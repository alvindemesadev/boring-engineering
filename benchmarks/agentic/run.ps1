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

$arms=@(
  @{ id="baseline"; skillSrc="" },
  @{ id="ponytail"; skillSrc=(Join-Path $ROOT "../arms/ponytail.md") },
  @{ id="boring-engineering"; skillSrc=(Join-Path $ROOT "../../SKILL.md") }
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
      # inject skill as real skill file so the build agent discovers it (not via prompt)
      if($arm.skillSrc){
        $skillDir=Join-Path $ws ".opencode/skills/$($arm.id)"
        New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
        Copy-Item $arm.skillSrc (Join-Path $skillDir "SKILL.md") -Force
        # also copy references/assets if they exist (boring has them next to SKILL.md)
        $skillRoot=Split-Path $arm.skillSrc -Parent
        if($arm.id -eq "boring-engineering"){
          $repoRoot=Join-Path $ROOT "../.."
          if(Test-Path (Join-Path $repoRoot "references")){ Copy-Item (Join-Path $repoRoot "references") $skillDir -Recurse -Force -ErrorAction SilentlyContinue }
          if(Test-Path (Join-Path $repoRoot "assets")){ Copy-Item (Join-Path $repoRoot "assets") $skillDir -Recurse -Force -ErrorAction SilentlyContinue }
        }
        git add ".opencode/skills/$($arm.id)/SKILL.md" 2>$null | Out-Null
        git commit -qm "inject $($arm.id) skill" 2>$null
      }
      # ticket prompt via file attachment (skill is now discovered, not pasted)
      $promptFile=Join-Path $ws "_ticket.txt"
      [IO.File]::WriteAllText($promptFile, $ticket.prompt, [Text.Encoding]::UTF8)
      $out=Join-Path $ws "_events.json"
      $err=Join-Path $ws "_err.txt"
      $opencodeCmd=Join-Path $ROOT "../node_modules/.bin/opencode.cmd"
      $cmdLine = "`"$opencodeCmd`" run --agent build --format json -m $Model -f `"$promptFile`" `"Complete the ticket in the attached file. Search the codebase first, then edit the repo in place. Keep the diff minimal.`" 1>`"$out`" 2>`"$err`""
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
