param(
  [int]$Runs = 2,
  [int]$CallTimeoutSec = 180,
  [string]$Model = "opencode/muse-spark-1.2-contributor-free"
)
$ErrorActionPreference='Continue'
$ROOT=$PSScriptRoot
$FIXTURE=Join-Path $ROOT "fixtures/mini-ecommerce"
$TICKETS=Get-Content (Join-Path $ROOT "tickets.json") -Raw | ConvertFrom-Json
$RUNS_DIR=Join-Path $ROOT "runs"
New-Item -ItemType Directory -Path $RUNS_DIR -Force | Out-Null
$STAMP=Get-Date -Format "yyyyMMdd-HHmmss"
$STAMP_DIR=Join-Path $RUNS_DIR $STAMP
New-Item -ItemType Directory -Path $STAMP_DIR -Force | Out-Null

function StripFM([string]$md){ return ($md -replace "(?s)\A---\r?\n.*?\r?\n---\r?\n","").Trim() }
$boringRules=[IO.File]::ReadAllText((Join-Path $ROOT "../../SKILL.md"),[Text.Encoding]::UTF8) | ForEach-Object { StripFM $_ }
$ponytailRules=[IO.File]::ReadAllText((Join-Path $ROOT "../arms/ponytail.md"),[Text.Encoding]::UTF8) | ForEach-Object { StripFM $_ }
$arms=@(
  @{ id="baseline"; rules="" },
  @{ id="ponytail"; rules=$ponytailRules },
  @{ id="boring-engineering"; rules=$boringRules }
)

Write-Output "Tier A pilot: $($TICKETS.Count) tickets × $($arms.Count) arms × $Runs runs = $($TICKETS.Count*$arms.Count*$Runs) cells"
Write-Output "Fixture: $FIXTURE -> $STAMP_DIR"

foreach($ticket in $TICKETS){
  foreach($arm in $arms){
    for($r=0;$r -lt $Runs;$r++){
      $key="$($arm.id)__$($ticket.id)__$r"
      $ws=Join-Path $STAMP_DIR $key
      Copy-Item -Path $FIXTURE -Destination $ws -Recurse -Force
      # git init + baseline commit
      Push-Location $ws
      git init -q; git config user.email "bench@boring.test"; git config user.name "bench"
      git add .; git commit -qm "baseline"
      # inject skill as file attachment prompt
      $promptFile=Join-Path $ws "_prompt.txt"
      $fullPrompt=if($arm.rules){ $arm.rules + "`n`n---`n`n" + $ticket.prompt } else { $ticket.prompt }
      [IO.File]::WriteAllText($promptFile, $fullPrompt, [Text.Encoding]::UTF8)
      $out=Join-Path $ws "_events.json"
      $err=Join-Path $ws "_err.txt"
      $opencodeCmd=Join-Path $ROOT "../node_modules/.bin/opencode.cmd"
      # agentic: build agent with tools, workspace = $ws, prompt via file attachment
      $cmdLine = "`"$opencodeCmd`" run --agent build --format json -m $Model -f `"$promptFile`" `"Complete the ticket described in the attached file. Edit the repo in place.`" 1>`"$out`" 2>`"$err`""
      $p=Start-Process cmd.exe -ArgumentList '/d','/s','/c',$cmdLine -PassThru -WindowStyle Hidden -WorkingDirectory $ws
      Wait-Process -Id $p.Id -Timeout $CallTimeoutSec -ErrorAction SilentlyContinue
      if(-not $p.HasExited){ taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
      # score git diff
      $added=(git diff --numstat | ForEach-Object { [int]($_ -split "`t")[0] } | Measure-Object -Sum).Sum
      if($null -eq $added){ $added=0 }
      $diff=git diff --stat
      # write score
      $score=@{ key=$key; arm=$arm.id; task=$ticket.id; run=$r; loc_added=$added; diff_stat=$diff; model=$Model } | ConvertTo-Json -Compress
      $score | Add-Content (Join-Path $STAMP_DIR "_scores.jsonl") -Encoding UTF8
      Write-Output ("{0} loc={1} {2}" -f $key,$added,($diff -split "`n")[0])
      Pop-Location
    }
  }
}
Write-Output "Done. Scores: $STAMP_DIR/_scores.jsonl"
Get-Content (Join-Path $STAMP_DIR "_scores.jsonl") | ForEach-Object { $_ | ConvertFrom-Json | Group-Object arm | ForEach-Object { "{0} avg loc {1:N1}" -f $_.Name, (($_.Group | Measure-Object loc_added -Average).Average) } } | Sort-Object | Get-Unique
