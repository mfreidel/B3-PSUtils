# B3-PSUtils
A PowerShell module that generates BLAKE3 hashes of files.

The purpose of this module is to add a PowerShell script-able interface for generating BLAKE3 hashes of files. It was created to assist with verifying the integrity of large data backups.


## Where's the Rust?
This is currently just a wrapper for b3sum.exe, which the user must compile before using this module. However, a goal of this project is to have the Rust code incorporated into the project eventually.


## Installing
It is important to note that this module does not include any software (either in source or binary form) from BLAKE3 or b3sum yet. Using this module requires that you download and compile b3sum yourself on Windows (Linux PowerShell is not yet supported).


### Step 1: Install Rust/Cargo
Install rust and cargo using rustup for Windows: https://www.rust-lang.org/tools/install

NOTE: You may need to modify your PATH environment variable and/or restart your computer.


### Step 2: Install b3sum
From a command line, run: 
```
cargo install b3sum
```

If that doesn't compile, try installing without default features: 
```
cargo install b3sum --no-default-features
```

You can also download the BLAKE3 and b3sum source from: https://github.com/BLAKE3-team/BLAKE3 and install using the --path option (commands not shown)


### Step 3: Install the module (Optional)
If you don't have a PowerShell Modules directory for your user ($home\Documents\WindowsPowerShell\Modules), then create it and copy the B3-PSUtils folder into it.

From PowerShell:
```
$DownloadedModule = 'C:\path\to\downloaded\B3-PSUtils' 
```

```
if (!(Test-Path "$home\Documents\WindowsPowerShell\Modules")) {new-item "$home\Documents\WindowsPowerShell\Modules"} 
Copy-Item $DownloadedModule $home\Documents\WindowsPowerShell\Modules -Recurse
```


### Step 4: Load the module
You may need to change PowerShell's execution policy to something less restrictive than the default. Read [this document from Microsoft](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7) for information about how you can change it. For security purposes, consider limiting the scope of this change as much as your needs for this module allow.

If you didn't install the module, run from PowerShell:
```
Import-Module 'C:\path\to\downloaded\B3-PSUtils\B3-PSUtils.psd1'
```

If you installed the module, you can run: 
```
Import-Module B3-PSUtils 
```

If you have Pester installed, you can change to the module directory in PowerShell and run `Invoke-Pester`. Doing so will reload the module and verify that everything is working properly.


## Using the module
There are five exported functions in the module:

1. 'Get-B3FileHash' generates a BLAKE3 hash of a single file.
2. 'Get-B3HashCollection' generates BLAKE3 hashes for an array of file names.
3. 'Get-B3StringHash' generates a BLAKE3 hash of a given string.
4. 'Get-B3sumExePath' shows the path to the b3sum executable that will be used for generating hashes
5. 'Set-B3sumExePath' changes the path to a b3sum executable used by the module

Usage information is available from Get-Help or the -? common parameter (Help Entries are written in module's source as comment blocks) 

## BLAKE3 Copyright Notice

This module utilizes a compiled binary of software by the BLAKE3 team, but is neither affiliated with nor endorsed by them in any way. 

BLAKE3 and b3sum are Copyright 2019 Jack O'Connor and Samuel Neves under the 
Apache License, Version 2.0. 

## PowerShell code Copyright Notice

   Copyright 2020 Michael J. Freidel

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.