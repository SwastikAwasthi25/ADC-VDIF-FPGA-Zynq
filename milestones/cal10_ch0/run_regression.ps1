param([Parameter(Mandatory=$true)][string]$ProjectRoot,[Parameter(Mandatory=$true)][string]$VivadoBin,[Parameter(Mandatory=$true)][string]$ScratchRoot)
$ErrorActionPreference='Stop'
$manifest=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'dependency_manifest.json') -Raw | ConvertFrom-Json
function AssertHash([string]$p,[string]$hash){if(!(Test-Path -LiteralPath $p -PathType Leaf)){throw "Missing: $p"};if((Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash -ne $hash){throw "Hash mismatch: $p"}}
$sources=@(); $checks=@{}
foreach($d in $manifest.compile_order){
 if($d.kind -eq 'published_rtl'){$f=Join-Path $PSScriptRoot $d.snapshot_relative_path}else{$f=Join-Path $ProjectRoot $d.project_relative_path}
 AssertHash $f $d.sha256; $f=(Resolve-Path -LiteralPath $f).Path; $sources+=$f; $checks[$f]=$d.sha256
}
$inc=Split-Path -Parent $sources[20]
foreach($t in $manifest.tests){$tb=Join-Path $PSScriptRoot $t.testbench; AssertHash $tb $t.sha256; $checks[$tb]=$t.sha256}
$run=Join-Path $ScratchRoot ('cal10_regression_'+[Guid]::NewGuid().ToString('N').Substring(0,10)); New-Item -ItemType Directory -Path $run | Out-Null
foreach($t in $manifest.tests){
 $dir=Join-Path $run $t.top; New-Item -ItemType Directory -Path $dir | Out-Null
 $tb=Join-Path $PSScriptRoot $t.testbench; Push-Location $dir
 try{
  & (Join-Path $VivadoBin 'xvlog.bat') -sv -i $inc @sources $tb | Tee-Object -FilePath compile.log
  if($LASTEXITCODE -ne 0){throw 'XVLOG failed'}
  & (Join-Path $VivadoBin 'xelab.bat') $t.top -s snapshot | Tee-Object -FilePath elaborate.log
  if($LASTEXITCODE -ne 0){throw 'XELAB failed'}
  & (Join-Path $VivadoBin 'xsim.bat') snapshot -runall -log simulation.log
  if($LASTEXITCODE -ne 0){throw 'XSIM failed'}
  $log=Get-Content -LiteralPath simulation.log -Raw
  if($log -match 'CHECK_FAILED|GLOBAL_TIMEOUT|(?im)^\s*Fatal:' -or $log -notmatch ('(?m)^'+[regex]::Escape($t.marker)+'\s*$')){throw 'Simulation acceptance failed'}
 }finally{Pop-Location}
}
foreach($e in $checks.GetEnumerator()){AssertHash $e.Key $e.Value}
Write-Host "CAL10_PORTABLE_REGRESSION_PASS: $run"
