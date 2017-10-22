Import-Module $PSScriptRoot\Invoke-Parallel\Invoke-Parallel.psd1 -Force

$a = "Hello"
$longvar = "World!"
0 | Invoke-Parallel -ImportVariables -ScriptBlock {
    "Write-Host $a $longvar"
} 