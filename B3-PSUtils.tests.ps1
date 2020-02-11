# B3-PSUtils Unit Tests
# =========================
#
# Pester Unit Test script for the B3-PSUtils module
# You can download Pester from: https://go.microsoft.com/fwlink/?LinkID=534084
#
# !NOTE! -- Some of the tests fail in Visual Studio 2019 with the PowerShell extension. Not sure why this happens, but manually running Invoke-Pester from a PowerShell window should show a passing result for everything.
#

#
#    Copyright 2020 Michael J. Freidel
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# Write banners to the screen
Get-Content .\banners\testsfor.txt | Write-Host -ForegroundColor yellow
Get-Content .\banners\b3-psu.txt | Write-Host -ForegroundColor yellow

# Determine the module path and name based on this script
$ThisModule = $MyInvocation.MyCommand.Path -replace '\.tests\.ps1$'
$ThisModuleName = $ThisModule | Split-Path -Leaf

Write-Host "`n`nModule loading...`n`n"

# Reload the module before testing
Get-Module -Name $ThisModuleName -All | Remove-Module -Force -ErrorAction Ignore
$InitStart = Get-Date
Import-Module -Name "$ThisModule.psd1" -Force -ErrorAction Stop
$InitEnd = Get-Date
$LoadTime = [math]::Round(($InitEnd - $InitStart).TotalMilliseconds)

# Display load time and version string
$ThisModuleVersion = ((Get-Module B3-PSUtils).version).ToString()
Write-Host "Module loaded in $LoadTime`ms (Version: $ThisModuleVersion) `n`n"

# Show Full Module Details (uncomment if necessary, but this is usually too much info.)
#Write-Host "Full Module Details:`n"; Get-Module $ThisModuleName | select * -ExcludeProperty "Definition"; Write-Host "`n`n"

# Generate hashes of the module files for testing
$TestFileName = ".\B3-PSUtils.psd1"
$TestFileNamesArray = @(".\B3-PSUtils.psm1", ".\B3-PSUtils.tests.ps1")

# Show Example Output for Single file
Write-Host "Example Output:`n`n"
Write-Host "PS...> Get-B3FileHash $TestFileName -ShowCommand -Timer | FL"
Get-B3FileHash $TestFileName -ShowCommand -Timer | Format-List

# Show Example Output for Single file
Write-Host "PS...> `$MyArray = @('.\B3-PSUtils.psm1', '.\B3-PSUtils.tests.ps1')"
Write-Host "PS...> ,`$MyArray | Get-B3HashCollection -ShowCommand -Timer | FL"
,$TestFileNamesArray | Get-B3HashCollection -ShowCommand -Timer | Format-List

Write-Host "Running unit tests...`n`n"

Describe "Get-B3FileHash" {
	Context "Input" {
		It "accepts a file name from parameter" {
			(Get-B3FileHash -FileName $TestFileName) | should not be $null
		}
		It "accepts a file name from pipeline" {
			($TestFileName | Get-B3FileHash) | should not be $null
		}
	}
	Context "Output"{
		It "returns a powershell object" {
			(Get-B3FileHash $TestFileName) | should BeOfType "PSCustomObject"
		}
		It "optionally displays calculation seconds" {
			((Get-B3FileHash $TestFileName -Timer).CalculationSeconds) | should BeOfType "System.Double"
		}
		It "does not display calculation seconds when unspecified" {
			(Get-B3FileHash $TestFileName).CalculationSeconds | should be $null
		}
		It "optionally displays b3sum command used" {
			(Get-B3FileHash $TestFileName -ShowCommand).CommandUsed  | should BeLike "*b3sum*"
		}
		It "does not display b3sum command used when unspecified" {
			(Get-B3FileHash $TestFileName).CommandUsed | should be $null
		}
	}
}

Describe "Get-B3HashCollection" {
	Context "Input" {
		It "accepts an array of file names from parameter" {
			(Get-B3HashCollection -FromArray $TestFileNamesArray) | should not be $null
		}
		It "accepts an array of file names from pipeline" {
			(,$TestFileNamesArray | Get-B3HashCollection) | should not be $null # Unary array operator (,) is necessary in this case. Not sure how to fix that...
		}
	}
	Context "Output" {
		$OutputArray = (Get-B3HashCollection -FromArray $TestFileNamesArray -Timer -ShowCommand)
		It "returns an array of multiple objects" {
			$OutputArray.count | should BeGreaterThan 1
		}
		It "sends 'Timer' option to Get-B3FileHash" {
			$OutputArray[1].CalculationSeconds | should BeOfType "System.Double" 
		}
		It "sends 'ShowCommand' option to Get-B3FileHash" {
			$OutputArray[1].CommandUsed  | should BeLike "*b3sum*"
		}
	}
}

Describe "Get-B3StringHash" {
	Context "Input" {
		It "accepts a string as first positional parameter" {
			Get-B3StringHash Pester | should not be $null
		}
		It "accepts a string from pipeline" {
			("Pester" | Get-B3StringHash) | should not be $null
		}
		It "optionally accepts an additional string for key derivation" {
			("Pester" | Get-B3StringHash -KeyContext "Pester") | should not be $null
		}
	}
	Context "Output" {
		It "returns hash value that is 64 chars long by default" {
			("Pester" | Get-B3StringHash).length | should be 64
		}
		It "can return a derived key" {
			("Pester" | Get-B3StringHash -KeyContext "Pester").length | should be 64
			(("Pester" | Get-B3StringHash -KeyContext "Pester") -eq ("Pester" | Get-B3StringHash)) | should be $false
		}
	}
}

Describe "Get-B3sumExePath" {
	Context "Output" {
		It "displays path to b3sum exectuble used by the module" {
			Get-B3sumExePath | should BeLike "*b3sum.exe"
		}
	}
}

Describe "Set-B3sumExePath" {
	#Set the file names to use in the tests
	$DefaultExe = "$home\.cargo\bin\b3sum.exe"
	$GoodExe = "$($TestDrive)\b3sum.exe"
	$BadExe = "$($TestDrive)\broken-b3sum.exe" 
	$NotExe = 'C:\Windows\System32\ipconfig.exe' 
	# !NOTE! -- The file stored in $NotExe will be copied to the $BadExe location in Pester's $TestDrive and then executed from there with the '-V' option.
	# The ipconfig Windows tool is used by default, because it should be available for all Windows systems and simply doesn't do anything when run in the test.

	#Create the "good" executable in Pester's TestDrive
	Copy-Item $DefaultExe $GoodExe

	#Create the "bad" executable in Pester's TestDrive
	Copy-Item $NotExe $BadExe
	
	Context "Input" {
		It "prevents setting path to a non-existant file" {
			(Set-B3sumExePath .\ghosts\b3sum.exe -ErrorAction SilentlyContinue) | should throw
		}
		It "prevents setting path to a file that isn't b3sum" {
			(Set-B3sumExePath $NotExe -ErrorAction SilentlyContinue) | should throw
		}
		It "prevents setting path to a non-functioning b3sum executable" {
			(Set-B3sumExePath $BadExe -ErrorAction SilentlyContinue) | should throw
		}
		It "can set path to different b3sum executable" {
			(Set-B3sumExePath $GoodExe) | should BeLike "Success*" 
		}
		It "can set path to module's default value (in ~\.cargo\bin)" {
			(Set-B3sumExePath default) | should BeLike "Success*" 
		}
	}
}


