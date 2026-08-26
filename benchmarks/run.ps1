param(
  [int]$Limit = 0,
  [int]$CallTimeoutSec = 120,
  [string]$OnlyArm = ""
)
$ErrorActionPreference = 'Continue'
$ROOT = $PSScriptRoot
Set-Location $ROOT

$config = Get-Content "$ROOT\tasks\tasks.json" -Raw | ConvertFrom-Json
$model = $config.model
$runs = $config.runsPerCell
$tasks = $config.tasks
$resultsDir = Join-Path $ROOT "results"
$rawPath = Join-Path $resultsDir "raw.jsonl"
New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

function Strip-Frontmatter([string]$md) {
  return ($md -replace "(?s)\A---\r?\n.*?\r?\n---\r?\n", "").Trim()
}

$beRuleset = Strip-Frontmatter ([IO.File]::ReadAllText("$ROOT\..\SKILL.md", [Text.Encoding]::UTF8))
$poRuleset = Strip-Frontmatter ([IO.File]::ReadAllText("$ROOT\arms\ponytail.md", [Text.Encoding]::UTF8))
$cavemanRuleset = Strip-Frontmatter ([IO.File]::ReadAllText("$ROOT\arms\caveman.md", [Text.Encoding]::UTF8))
$yagniRuleset = Strip-Frontmatter ([IO.File]::ReadAllText("$ROOT\arms\yagni-oneliner.md", [Text.Encoding]::UTF8))
$arms = @(
  @{ id = "baseline"; ruleset = "" },
  @{ id = "caveman"; ruleset = $cavemanRuleset },
  @{ id = "yagni-oneliner"; ruleset = $yagniRuleset },
  @{ id = "ponytail"; ruleset = $poRuleset },
  @{ id = "boring-engineering"; ruleset = $beRuleset }
)

$seen = @{}
if (Test-Path $rawPath) {
  Get-Content $rawPath | ForEach-Object {
    try { $o = $_ | ConvertFrom-Json; $seen[$o.key] = $true } catch {}
  }
}

function Get-RulesetHash([string]$s) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($s))
  ($bytes[0..5] | ForEach-Object { $_.ToString("x2") }) -join ""
}

$queue = New-Object System.Collections.Generic.List[object]
for ($r = 0; $r -lt $runs; $r++) {
  for ($ti = 0; $ti -lt $tasks.Count; $ti++) {
    for ($ai = 0; $ai -lt $arms.Count; $ai++) {
      $armIdx = ($ai + $r + $ti) % $arms.Count
      $queue.Add(@{ arm = $arms[$armIdx]; task = $tasks[$ti]; run = $r })
    }
  }
}
$plan = @($queue | Where-Object { -not $seen.ContainsKey("$($_.arm.id)|$($_.task.id)|$($_.run)") })
if ($OnlyArm) { $plan = @($plan | Where-Object { $_.arm.id -eq $OnlyArm }) }
if ($Limit -gt 0 -and $plan.Count -gt 0) { $plan = $plan[0..([Math]::Min($Limit, $plan.Count) - 1)] }

Write-Output ("Plan: {0} cells total, {1} to run. Model: {2}" -f $queue.Count, $plan.Count, $model)

foreach ($cell in $plan) {
  $armId = $cell.arm.id
  $taskId = $cell.task.id
  $run = $cell.run
  $key = "$armId|$taskId|$run"
  $ruleset = $cell.arm.ruleset
  $prompt = if ($ruleset) { $ruleset + "`n`n---`n`n" + $cell.task.prompt } else { $cell.task.prompt }

  $id = [guid]::NewGuid().ToString("N").Substring(0, 8)
  $promptFile = Join-Path $resultsDir "prompt-$id.txt"
  $outFile = Join-Path $resultsDir "events-$id.json"
  $errFile = Join-Path $resultsDir "clierr-$id.txt"
  [IO.File]::WriteAllText($promptFile, $prompt, [Text.UTF8Encoding]::new($false))

  $env:BE_MODEL = $model
  $env:BE_PROMPT_FILE = $promptFile
  $env:BE_OUT = $outFile
  $env:BE_ERR = $errFile

  Write-Host -NoNewline ("[{0}] {1} ... " -f (Get-Date -Format HH:mm:ss), $key)

  $sw = [Diagnostics.Stopwatch]::StartNew()
  $p = Start-Process cmd.exe -ArgumentList '/d', '/s', '/c', "`"$ROOT\runner.cmd`"" -PassThru -WindowStyle Hidden -WorkingDirectory $ROOT
  Wait-Process -Id $p.Id -Timeout $CallTimeoutSec -ErrorAction SilentlyContinue
  if (-not $p.HasExited) { taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
  $latencyMs = $sw.ElapsedMilliseconds

  $text = ""
  $tokIn = $null; $tokOut = $null; $tokRea = $null; $cost = $null
  if (Test-Path $outFile) {
    foreach ($l in [IO.File]::ReadAllLines($outFile, [Text.Encoding]::UTF8)) {
      try { $e = $l | ConvertFrom-Json } catch { continue }
      if ($e.type -eq 'text' -and $e.part.text) { $text += $e.part.text }
      if ($e.type -eq 'step_finish' -and $e.part.tokens) {
        $tokIn = $e.part.tokens.input; $tokOut = $e.part.tokens.output
        $tokRea = $e.part.tokens.reasoning; $cost = $e.part.cost
      }
    }
  }

  Write-Host -NoNewline ("lat={0}s chars={1} " -f [int]($latencyMs / 1000), $text.Length)

  $row = [ordered]@{
    key = $key; arm = $armId; task = $taskId; run = $run; model = $model
    latencyMs = $latencyMs
    tokens_input = $tokIn; tokens_output = $tokOut; tokens_reasoning = $tokRea
    cost_usd = $cost
    ruleset_sha256_12 = if ($ruleset) { Get-RulesetHash $ruleset } else { "" }
    response_chars = $text.Length
    response = $text
    loc = $null; passed = $false; reason = ""
  }

  $blocks = [regex]::Matches($text, '(?s)```[a-zA-Z0-9]*\r?\n(.*?)```')
  if ($blocks.Count -eq 0) {
    $row.reason = "no_code_block"
  } else {
    $code = ($blocks | Sort-Object { $_.Groups[1].Value.Length } -Descending | Select-Object -First 1).Groups[1].Value
    $loc = ($code -split "\r?\n" | Where-Object { $_.Trim().Length -gt 0 }).Count
    $row.loc = $loc

    $sandbox = Join-Path $resultsDir ("sandbox\" + ($key -replace '\|', '__'))
    New-Item -ItemType Directory -Path $sandbox -Force | Out-Null
    [IO.File]::WriteAllText((Join-Path $sandbox "package.json"), '{"type":"module"}')
    foreach ($prop in $cell.task.files.PSObject.Properties) {
      $dst = Join-Path $sandbox $prop.Name
      New-Item -ItemType Directory -Path (Split-Path $dst -Parent) -Force | Out-Null
      [IO.File]::WriteAllText($dst, $prop.Value)
    }
    $solPath = Join-Path $sandbox $cell.task.solutionFile
    New-Item -ItemType Directory -Path (Split-Path $solPath -Parent) -Force | Out-Null
    [IO.File]::WriteAllText($solPath, $code)
    [IO.File]::WriteAllText((Join-Path $sandbox "test.mjs"), $cell.task.test)

    Push-Location $sandbox
    $tout = & node test.mjs 2>&1
    $texit = $LASTEXITCODE
    Pop-Location
    if ($texit -eq 0) { $row.passed = $true; $row.reason = "pass" }
    elseif ($null -eq $texit) { $row.reason = "node-missing" }
    else {
      $row.reason = "test-fail"
      $firstErr = ($tout | Out-String) -split "`r?`n" | Where-Object { $_ -match "Error|AssertionError" } | Select-Object -First 1
      if ($firstErr) { Write-Host -NoNewline ("[{0}] " -f $firstErr.Trim()) }
    }
  }

  $row | ConvertTo-Json -Compress -Depth 4 | Add-Content $rawPath -Encoding UTF8
  Remove-Item $promptFile, $outFile, $errFile -ErrorAction SilentlyContinue
  Write-Output ("loc={0} pass={1} {2}" -f $row.loc, $row.passed, $row.reason)
  Start-Sleep -Milliseconds 500
}
Write-Output "Done."
