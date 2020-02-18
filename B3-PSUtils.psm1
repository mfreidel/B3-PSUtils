# B3-PSUtils Root Module
# ==========================
#
# A PowerShell module that generates BLAKE3 hashes of files using the b3sum tool
#
# Currently, this is basically just a wrapper for the b3sum tool that is released by the BLAKE3 team (https://github.com/BLAKE3-team/BLAKE3). 
# User must compile b3sum.exe before using this module
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



# Default b3sum.exe location is your cargo binaries directory
$DefaultB3sumExePath = "$home\.cargo\bin\b3sum.exe"
#(!NOTE! -- This executable is not distributed with the module! See the README file for more info.)



#
# --- Script-only Functions (Not exported) ---
#


Function Check-B3sumExePath {
	param (
		[Parameter(Mandatory=$true)]
		  [string] $Path
	)
	# First, verify input ends with b3sum.exe
	if ($Path -like "*b3sum.exe") { 
		
		# Second, verify path exists
		if (Test-Path $Path) { 
			
			# Test the exe using the -V switch to print b3sum's version
			$b3sumExeTest = (Invoke-Expression "& '$Path' -V") 
			
			# Finally, verify exe output is from a b3sum executable
			if ($b3sumExeTest -like "b3sum*") { 
				$Result = @($true, "Success!")
			}
			else  { # Specified b3sum.exe doesn't work 
				$Result = @($false, "FAILED to verify b3sum.exe -- Your b3sum executable is broken. Try recompiling it?")
			}
		}
		else { # Specified b3sum.exe doesn't exist
			$Result = @($false, "FAILED to verify b3sum.exe -- Specified path ($Path) does not exist!")
		}
	}
	else { # Specified path doesn't end in b3sum.exe
			$Result = @($false, "FAILED to verify b3sum.exe -- You must specify a an executable that is named ' b3sum.exe.'")
	}

	return $Result
}




#
# --- Exported Functions ---
#


Function Get-B3FileHash {
<#
.SYNOPSIS
Creates a BLAKE3 hash of a given file.

.DESCRIPTION
Takes a file name as a string and returns a PowerShell object that resembles the output of Get-FileHash. This will only work with a single file name, and is not designed to work with multiple files (Use Get-B3HashCollection instead).

.PARAMETER FileName
Specifies the file name.

.PARAMETER Length
Specifies the number of output bytes (default for b3sum is 32)

.PARAMETER BinaryPath
Specifies the executable to use. Default value is the module's b3sum executable path (See Get-B3SumExePath and Set-B3SumExePath).

.PARAMETER NoMMap
Disables memory mapping

.PARAMETER Timer
Shows the 'CalculationSeconds' property in the returned object (how many seconds it took to calculate the hash value)

.PARAMETER ShowCommand
Shows the 'CommandUsed' property in the returned objects (command used to generate the hash value)

.EXAMPLE
PS> Get-B3FileHash .\NameOfMy.file

.EXAMPLE
PS> 'C:\Path\To\NameOfMy.file' | Get-B3FileHash

.EXAMPLE
PS> Get-B3FileHash -FileName C:\Path\To\NameOfMy.file -Timer -ShowCommand
#>
	param (
		[Parameter( 
			Mandatory = $true,
			ValueFromPipeline = $true
		)] [string] $FileName,
		[string] $BinaryPath = $b3sumEXE, #use b3sum executable path from module variable
		[switch] $NoMMap,
		[ValidateRange(0,9000)][Int32] $Length = 32,
		[switch] $Timer,
		[switch] $ShowCommand
	)
	
	if (Test-Path $FileName) { 
		# Initialize a custom PS object that will hold the output
		$B3HashObject = New-Object -TypeName psobject
		
		#Ensure file name is a full path
		$FileName = (Get-ChildItem $FileName).FullName
		
		#Build command string based on parameters
		$CommandString = "& '$BinaryPath'"
		if ($NoMMap) {
			$CommandString += " --no-mmap"
		}
		if ($Length -ne 32) {
			$CommandString += " -l $Length"
		}
		$CommandString += " '$FileName'"
	
		# Start Timer before running the command
		if ($Timer) {$Time1 = Get-Date}
	
		# Run the constructed the command, and store the output
		$CommandOutput = (Invoke-Expression $CommandString)
	
		# Stop Timer and store it in seconds
		if ($Timer) {
			$Time2 = Get-Date
			$TimerSeconds = ($Time2 - $Time1).TotalSeconds
		}
	
		# Split the b3sum output string into an array: Element 0 is the Hash, and 1 is the filename.
		# b3sum's output from a single file is: "<hash>  <full-path>"
		$SplitOutput = $CommandOutput -split "  "
	
		# Add NoteProperties to the object
		$B3HashObject | Add-Member -MemberType NoteProperty -Name Algorithm -Value "BLAKE3"
		$B3HashObject | Add-Member -MemberType NoteProperty -Name Hash -Value $SplitOutput[0]
		$B3HashObject | Add-Member -MemberType NoteProperty -Name Path -Value $SplitOutput[1]
		if ($Timer) {$B3HashObject | Add-Member -MemberType NoteProperty -Name CalculationSeconds -Value $TimerSeconds}
		if ($ShowCommand) {$B3HashObject | Add-Member -MemberType NoteProperty -Name CommandUsed -Value $CommandString}
		return $B3HashObject
	}
	else {
		Write-Error "File Doesn't exist: ($FileName)"
	}
}



Function Get-B3HashCollection {
<#
.SYNOPSIS
Generates BLAKE3 hashes for an array of file names.

.DESCRIPTION
Takes an array of file names (as a string) and returns an array of PowerShell objects from the Get-B3FileHash function. An array sent from pipeline to this function must use the unary array operator (,) or it will only return the last hash of the element of the array.

.PARAMETER FromArray
Specifies the array of file names.

.PARAMETER NoMMap
Disables memory mapping

.PARAMETER Timer
Shows the 'CalculationTime' property in the returned objects (how many seconds it took to calculate the hash value)

.PARAMETER ShowCommand
Shows the 'CommandUsed' property in the returned objects (command used to generate the hash value)

.EXAMPLE
PS> Get-B3HashCollection @(".\NameOfMy.file", ".\NameOfMyOther.file")

.EXAMPLE
PS> ,$MyArray | Get-B3HashCollection

.EXAMPLE
PS> Get-B3HashCollection -FromArray $MyArray -Timer -ShowCommand
#>
	param (
		[Parameter(
			ValueFromPipeline = $true
		)] [array] $FromArray,
		[switch] $NoMMap,
		[switch] $Timer,
		[switch] $ShowCommand
	)
	
	# These options get added to the command string for each file
	$PassthroughOptions = ""
	if ($NoMMap) {$PassthroughOptions += " -NoMMap"}
	if ($Timer) {$PassthroughOptions += " -Timer"}
	if ($ShowCommand) {$PassthroughOptions += " -ShowCommand"}

	# Initialize arrays to hold input & output
	$FilesList = @()
	$FileHashes = @()
	
	# Build Array from parameter. This extra step is taken instead of using the paramater input directly to account for planned features that aren't implemented yet.
	$FilesList += $FromArray

	# Feed each element of list array to Get-B3FileHash function, and add each returned object to the FileHashes array 
	ForEach ($FileName in $FilesList) {
		if (Test-Path $FileName) {
			# Combine file name and options
			$FileHashes += (Invoke-Expression "Get-B3FileHash -FileName '$FileName'$PassthroughOptions")
		}
		else {
			Write-Warning "Get-B3HashCollection -- File ($FileName) doesn't exist! Skipping..."
		}
	}

	# Return the array of hash objects
	return ,$FileHashes
}


Function Get-B3StringHash {
<#
.SYNOPSIS
Generates a BLAKE3 hash of a string value.

.DESCRIPTION
Takes a string and returns a BLAKE3 hash. Optionally can return a derived key when the -KeyContext parameter is used.

.PARAMETER Value
Specifies the string to be hashed.

.PARAMETER KeyContext
Specifies the context string used in key derivation mode.

.EXAMPLE
PS> Get-B3StringHash "MyString"

.EXAMPLE
PS> Get-B3StringHash "MyString" -KeyContext "MyContext"
#>
	param (
		[Parameter( 
			Mandatory = $true,
			ValueFromPipeline = $true
		)] [string] $Value,
		[string] $KeyContext,
		[switch] $NoMMap
	)
	
	# Build the command string
	$CommandString = "'$Value' | & '$b3sumEXE'"
	if ($NoMMap) {
			$CommandString += " --no-mmap"
		}
	if ($KeyContext -ne "") { # KeyContext was specified: add the --derive-key option with the variable
		$CommandString += " --derive-key '$KeyContext'"
	}
	
	# Run command, store output
	$CommandOutput = Invoke-Expression $CommandString
	
	# Return the command output
	return $CommandOutput
}


Function Get-B3sumExePath {
<#
.SYNOPSIS
Prints the path to the b3sum executable being used by B3-PSUtils

.DESCRIPTION
Just run it without any options. It doesn't do anything fancy.
#>
	Write-Output $b3sumEXE
}


Function Set-B3sumExePath {
<#
.SYNOPSIS
Changes the path to a b3sum executable used by the B3-PSUtils module

.DESCRIPTION
Takes a path as a string (must end with b3sum.exe), verifies that is a working b3sum.exe file, and changes the module's executable path to it. Future use of functions from B3-PSUtils will use the executable at this location when generating hashes.

.PARAMETER NewPath
Specifies the path to a valid b3sum.exe file. Also accepts a keyword of 'Default' to revert to the module's default location.

.EXAMPLE
PS> Set-B3sumExePath -NewPath C:\Path\To\My\b3sum.exe

.EXAMPLE
PS> Set-B3sumExePath default
#>
	param (
		[Parameter(Mandatory=$true)]
		  [string] $NewPath
	)
	$VerifyPath = (Check-B3sumExePath -Path $NewPath)
	if ($NewPath -eq "Default") { 
		# Default keyword sets path to the script's default path
		$Script:b3sumEXE = $DefaultB3sumExePath
		Write-Output "Success! b3sum executable path was changed to: $b3sumEXE"
	}
	elseif ($VerifyPath -contains $true) {
		$NewFullPath = (Get-ChildItem $NewPath).FullName
		$Script:b3sumEXE = $NewFullPath
		Write-Output "Success! b3sum executable path was changed to: $b3sumEXE"
	}
	else {
		# Print the failure message in an error
		Write-Error $VerifyPath[1]
	}
}



#
# --- Module initialization ---
#

# Check if b3sum is installed at default location
$CheckDefaultExe = (Check-B3sumExePath -Path $DefaultB3sumExePath)

if ($CheckDefaultExe -contains $true) {
	# Set b3sum path variable if b3sum.exe is verfied
	$b3sumEXE = $DefaultB3sumExePath
}
else {
	# If b3sum isn't available at the default location, then warn user and set it to an echo command that displays a "friendly" message in the psobjects.
	Write-Warning  "Problems occurred with b3sum executable..."
	Write-Warning $CheckDefaultExe[1]
	Write-Warning "Follow the installation instructions in the README.md file, or this module won't work properly!"
	$b3sumEXE = 'echo "ERROR:RTFM!  `;`)"'
	$DefaultB3sumExePath = 'echo ERROR:RTFM!  `;`)'
}