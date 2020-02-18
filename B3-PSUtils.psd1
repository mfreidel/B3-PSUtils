#
# Module manifest for 'B3-PSUtils'
#
# Generated by: Michael J. Freidel
#


@{

# Script module or binary module file associated with this manifest.
RootModule = 'B3-PSUtils.psm1'

# Version number of this module.
ModuleVersion = '0.3.5'

# ID used to uniquely identify this module
GUID = '3065a86e-a9df-45df-9581-9c73ed470de0'

# Author of this module
Author = 'Michael J. Freidel'

# Company or vendor of this module
CompanyName = 'Michael J. Freidel'

# Copyright statement for this module
Copyright = "Copyright 2020 Michael J. Freidel.

    Licensed under the Apache License, Version 2.0 (the `"License`");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an `"AS IS`" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   BLAKE3 and b3sum are Copyright 2019 Jack O'Connor and Samuel Neves
"

# Description of the functionality provided by this module
Description = 'A PowerShell module that generates BLAKE3 hashes of files with output similar to the Get-FileHash cmdlet.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '5.1.0'

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = 'Get-B3FileHash', 'Get-B3HashCollection', 'Get-B3sumExePath', 'Set-B3sumExePath', 'Get-B3StringHash'

# Cmdlets to export from this module
CmdletsToExport = ''

# Variables to export from this module
VariablesToExport = ''

# Aliases to export from this module
AliasesToExport = ''

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

