#handle PS2
if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
Import-Module $PSScriptRoot\..\Invoke-Parallel\Invoke-Parallel.psd1 -Force

$a = "Hello"
$longvar = "World!"

Describe "Invoke-Parallel PS$PSVersion" {
    
    Context 'Strict mode' { 

        Set-StrictMode -Version latest

        It 'should out string' {
            $out = (0..10) | Invoke-Parallel @Verbose -ScriptBlock { "a$_" } 
            $out.Count | Should Be 11
            $out[5][0] | Should Be 'a'
        }

        It 'should output runspace errors to error stream' {
            $out = 0 | Invoke-Parallel @Verbose -ErrorVariable OutError -ErrorAction SilentlyContinue -ScriptBlock {
                Write-Error "A Fake Error!"
            }
            $out | Should Be $null
            $OutError[0].ToString() | Should Be "A Fake Error!"
        }

        It 'should import variables with one letter name' {            
            0 | Invoke-Parallel @Verbose -ImportVariables -ScriptBlock {
                $a
            } | Should Be "Hello"
        }

        It 'should import all variables' {
            0 | Invoke-Parallel @Verbose -ImportVariables -ScriptBlock {
                "$a $longvar"
            } | Should Be "Hello World!"
        }

        It 'should not import variables when not specified' {
            $a = "Hello"
            $longvar = "World!"
            0 | Invoke-Parallel @Verbose -ScriptBlock {
                "$a $longvar"
            } | Should Be " "
        }

        It 'should import modules' {
            0 | Invoke-Parallel @Verbose -ImportModules -ScriptBlock {
                Get-Module Pester
            } | Should not Be $null
        }

        It 'should not import modules when not specified' {
            0 | Invoke-Parallel @Verbose -ScriptBlock {
                Get-Module Pester
            } | Should Be $null
        }

        It 'should honor time out' {
            $timeout = $null
            0 | Invoke-Parallel @Verbose -RunspaceTimeout 1 -ErrorVariable TimeOut -ScriptBlock {
                Start-Sleep -Seconds 3
            } -ErrorAction SilentlyContinue
            $timeout[0].ToString() | Should Match "Runspace timed out at*"
        }

        It 'should pass in a specified variable as $parameter' {
            $a = 5
            0 | Invoke-Parallel @Verbose -Parameter $a -ScriptBlock {
                $parameter
            } | Should Be 5
        }

        It 'should support $using in PowerShell 3 and later' {
            $a = 4

            if($PSVersionTable.PSVersion.Major -eq 2)
            {
                0 | Invoke-Parallel @Verbose -ScriptBlock {
                    $using:a
                } | Should Be $Null
            }
            elseif($PSVersionTable.PSVersion.Major -gt 2)
            {
                0 | Invoke-Parallel @Verbose -ScriptBlock {
                    $using:a
                } | Should Be 4

                #Multiple $using statements
                $Output = 0 | Invoke-Parallel @Verbose -ScriptBlock {
                    $using:a
                    "$using:a"
                }
                $Output.count | Should Be 2
            }
        }
    }
}

