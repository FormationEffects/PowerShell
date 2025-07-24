# config/funcs.pwsh.ps1
# Specifically for PowerShell related functions and aliases.

function Enter-Location {
    <#
    .SYNOPSIS
        Navigates to a specific directory. If none found, will default to a preset one.

    .DESCRIPTION
        This function is typically designed to enter the source/repos folder, but I've updated it to have
        env variables and input locations.

    .PARAMETER Path (alias -p)
        Backup path to navigate to if Environment variable is not setup.

    .PARAMETER EnvVariable (alias -e)
        Environment variable that holds a path to enter. If the environment variable is empty, default to Path.

    .EXAMPLE
        Enter-Location
        src (alias for Enter-Location at "C:\Users\jwilding\source\repos\")
        dev (alias for Enter-Location at "C:\Users\jwilding\source\repos\FEPipeline-dev")
        pub (alias for Enter-Location at "C:\Users\jwilding\source\repos\FEPipeline-public")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('p')][string]$Path,

        [Parameter(Mandatory=$true)]
        [Alias('e')][string]$EnvVariable
    )

    $Path = ($env_value =  [Environment]::GetEnvironmentVariable($EnvVariable)) -and (Test-Path $env_value) ? $env_value : $Path
    Set-Location $Path
}


function Update-Profile {
    <#
    .SYNOPSIS
        Updates the PowerShell profile.
    .DESCRIPTION
        This function updates the PowerShell profile by reloading it. It is useful for applying changes made to the profile without restarting PowerShell.
    .EXAMPLE
        Update-Profile
        profileupdate (alias for Update-Profile)
    #>

    . $PROFILE -Force
}

function Show-ProfileInfo {
    <#
    .SYNOPSIS
        Displays information about the PowerShell profile.
    .DESCRIPTION
        This function displays the path, directory, and name of the PowerShell profile. It is useful for understanding where the profile is located and its name.
    .EXAMPLE
        Show-ProfileInfo
        profileinfo (alias for Show-ProfileInfo)
    #>
    
    Write-Host "PowerShell Profile Path: $PROFILE"
    Write-Host "Profile Directory: $(Split-Path -Parent $PROFILE)"
    Write-Host "Profile Name: $(Split-Path -Leaf $PROFILE)"
}

function Get-SystemReport {
    param (
        [string]$ComputerName
    )

    if ($PSBoundParameters.ContainsKey("ComputerName")) {
        Write-Host "Gathering system report from '$ComputerName'..." -ForegroundColor Cyan
        try {
            Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                if (-not (Get-Command -Name Get-SystemReport -ErrorAction SilentlyContinue)) {
                    throw "Function 'Get-SystemReport' is not defined on remote host."
                }
                Get-SystemReport
            }
        } catch {
            Write-Host "Failed to get report from '$ComputerName': $_" -ForegroundColor Red
        }
        return
    }
    
    $report = [ordered]@{}

    # OS Info
    $osInfo = Get-ComputerInfo | Select-Object `
        @{Name = "OS Name"; Expression = { $_.OsName }},
        @{Name = "Architecture"; Expression = { $_.OsArchitecture }},
        @{Name = "Windows Version"; Expression = { $_.OsName }},
        @{Name = "Build"; Expression = { $_.WindowsBuildLabEx }}
    $report["Windows Version"] = $osInfo
    
    # CPU Info
    $cpuInfo = Get-CimInstance -ClassName Win32_Processor | Select-Object `
        @{Name = "CPU Name"; Expression = { $_.Name }},
        @{Name = "Cores"; Expression = { $_.NumberOfCores }},
        @{Name = "Logical Processors"; Expression = { $_.NumberOfLogicalProcessors }},
        @{Name = "Max Clock Speed (MHz)"; Expression = { $_.MaxClockSpeed }}
    $report["CPU"] = $cpuInfo

    # Memory Info
    $memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object `
        @{Name = "Capacity (GB)"; Expression = { [math]::round($_.Capacity / 1GB, 2) }},
        @{Name = "Speed (MHz)"; Expression = { $_.Speed }},
        @{Name = "Manufacturer"; Expression = { $_.Manufacturer }},
        @{Name = "Part Number"; Expression = { $_.PartNumber }}
    $report["Memory"] = $memoryInfo

    # GPU Info
    $gpuInfo = Get-CimInstance -ClassName Win32_VideoController | Select-Object `
        @{Name = "GPU Name"; Expression = { $_.Name }},
        @{Name = "GPU Memory (MB)"; Expression = { [math]::round($_.AdapterRAM / 1MB, 2) }},
        @{Name = "Driver Version"; Expression = { $_.DriverVersion }}
        @{Name = "Driver Date"; Expression = { $_.DriverDate }}
    $report["GPU"] = $gpuInfo
    
    Write-Host "`n=== System Report ===" -ForegroundColor Cyan
    foreach ($section in $report.GetEnumerator()) {
        Write-Host "`n[$($section.Key)]" -ForegroundColor Yellow
        if ($section.Value -is [string[]]) {
            $section.Value | ForEach-Object { Write-Host $_ -ForegroundColor Green }
        } elseif ($section.Value -is [System.Collections.IEnumerable] -and $section.Value -isnot [string]) {
            if ($section.Value.Count -eq 1) {
                $section.Value | Format-List
            } else {
                $section.Value | Format-Table -AutoSize
            }
        } else {
            $section.Value | Format-List
        }
    }

    Write-Host "`n=== End of Report ===" -ForegroundColor Cyan
}

function Get-Checksum {
    param (
        [Alias('p')][string]$Path,
        [Alias('a')][string]$Algorithm = "SHA256",
        [Alias('r')][switch]$Recurse,
        [Alias('o')][switch]$Output,
        [Alias('h')][switch]$Help
    )

    if ($Help) {
        Write-Host "Usage: Check-Hash -Path (-p) <path> [-Algorithm (-a) <algorithm>] [-Recurse (-r)] [-Help (-h)]"  -ForegroundColor Green
        Write-Host "Calculates and displays the hash of files in the specified path." -ForegroundColor Green
        Write-Host "Current input settings:" -ForegroundColor Cyan
        Write-Host "  Path: $Path" -ForegroundColor Cyan
        Write-Host "  Algorithm: $Algorithm" -ForegroundColor Cyan
        Write-Host "  Recurse: $Recurse" -ForegroundColor Cyan
        return
    }

    if (-not (Test-Path $Path)) {
        Write-Host "Error: Path '$Path' does not exist." -ForegroundColor Red
        return
    }

    if ($Recurse) {
        $files = Get-ChildItem -Path $Path -Recurse | Where-Object {!$_.PSIsContainer}
    } else {
        $files = Get-ChildItem -Path $Path | Where-Object {!$_.PSIsContainer}
    }

    if ($files.Count -eq 0) {
        Write-Host "No files found in the specified path." -ForegroundColor Yellow
        return
    }

    # Create an empty hash object
    # $hash_object = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
    $full_hash_string = ""
    $all_hashes = @{}

    # Calculate the hash of each file and add it to the hash object
    foreach ($file in $files) {
        try {
            $stream = [System.IO.File]::Open($file.FullName, 'Open', 'Read', 'ReadWrite')
        } catch {
            Write-Warning "Skipping locked file: $($file.FullName)"
            continue
        }
        
        $file_hash = Get-FileHash -InputStream $stream -Algorithm $Algorithm
        $stream.Close()
        if (-not $file_hash) {
            Write-Warning "Failed to compute hash for file: $($file.FullName)"
            continue 
        }
        $all_hashes[$file.FullName] = $file_hash.Hash

        if ($Output) {
            # Output the individual hash (new line per file)
            Write-Output ("{0}  {1}" -f $file_hash.Hash, $file.FullName)
        }

        $full_hash_string += $file_hash.Hash
    }
    $string_as_stream = [System.IO.MemoryStream]::new()
    $writer = [System.IO.StreamWriter]::new($string_as_stream)
    $writer.Write($full_hash_string)
    $writer.Flush()
    $string_as_stream.Position = 0
    $final_hash = Get-FileHash -InputStream $string_as_stream -Algorithm $Algorithm

    if ($Output) {
        # Output the final hash
        Write-Host "`Hash: $($final_hash.Hash) | $($Path)" -ForegroundColor Green
    }
    # return $all_hashes#$final_hash.Hash #, $all_hashes
    # Add summary object at the end
    $summary = [PSCustomObject]@{
        Path       = $Path
        FinalHash  = $final_hash.Hash
        FileCount  = $all_hashes.Count
        Algorithm  = $Algorithm
    }

    # Output results + summary
    $all_hashes
    $summary
}

function Compare-Checksum {
    param (
        [Alias('p')][string]$PathA,
        [Alias('q')][string]$PathB,
        [Alias('a')][string]$Algorithm = "SHA256",
        [Alias('o')][switch]$Output,
        [Alias('h')][switch]$Help
    )

    if ($Help) {
        Write-Host "Usage: Compare-Checksum -PathA (-p) <pathA> -PathB (-q) <pathB> [-Algorithm (-a) <algorithm>] [-Output (-o)] [-Help (-h)]"  -ForegroundColor Green
        Write-Host "Compares the checksums of files in two specified paths." -ForegroundColor Green
        return
    }

    if (-not (Test-Path $PathA)) {
        Write-Host "Error: Path A '$PathA' does not exist." -ForegroundColor Red
        return
    }

    if (-not (Test-Path $PathB)) {
        Write-Host "Error: Path B '$PathB' does not exist." -ForegroundColor Red
        return
    }

    $path_a_file_hashes, $path_a_hash = Get-Checksum -Path $PathA -Algorithm $Algorithm -Recurse -Output:$Output
    $path_b_file_hashes, $path_b_hash = Get-Checksum -Path $PathB -Algorithm $Algorithm -Recurse -Output:$Output

    if ($null -eq $path_a_hash -or $null -eq $path_b_hash) {
        Write-Host "Error: Could not compute checksums for one or both paths." -ForegroundColor Red
        return
    }

    if ($path_a_file_hashes.Count -ne $path_b_file_hashes.Count) {
        Write-Host "The number of files in both paths is different." -ForegroundColor Yellow
        return
    }

    if ($path_a_hash.FinalHash -eq $path_b_hash.FinalHash) {
        Write-Host "The checksums of both paths match: $($path_a_hash.FinalHash)" -ForegroundColor Green
        return
    } else {
        Write-Host "`nThe checksums of both paths do NOT match." -ForegroundColor Red
        Write-Host "Path A Checksum: $($path_a_hash.FinalHash)" -ForegroundColor Yellow
        Write-Host "Path B Checksum: $($path_b_hash.FinalHash)" -ForegroundColor Yellow
        Write-Host "`nAnalyzing file differences..." -ForegroundColor Cyan

        # Sort keys for consistency
        $keysA = $path_a_file_hashes.Keys | Sort-Object
        $keysB = $path_b_file_hashes.Keys | Sort-Object

        # Compare hashes by relative path (strip root)
        $differences = @()
        foreach ($fileA in $keysA) {
            $relative = [System.IO.Path]::GetRelativePath($PathA, $fileA)
            $fileB = Join-Path $PathB $relative

            if (-not $path_b_file_hashes.ContainsKey($fileB)) {
                $differences += "Missing in Path B: $relative"
                continue
            }

            if ($path_a_file_hashes[$fileA] -ne $path_b_file_hashes[$fileB]) {
                $differences += "Different content: $relative"
            }
        }

        # Check if PathB has extra files
        foreach ($fileB in $keysB) {
            $relative = [System.IO.Path]::GetRelativePath($PathB, $fileB)
            $fileA = Join-Path $PathA $relative

            if (-not $path_a_file_hashes.ContainsKey($fileA)) {
                $differences += "Missing in Path A: $relative"
            }
        }

        if ($differences.Count -eq 0) {
            Write-Host "Files differ only in ordering, but hashes match individually." -ForegroundColor Yellow
        } else {
            Write-Host "`nDifferences found:" -ForegroundColor Red
            $differences | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        }
    }
}

# === Aliases ===
Set-Alias -Name sysinfo -Value Get-SystemReport
Set-Alias -Name profileinfo -Value Show-ProfileInfo
Set-Alias -Name profileupdate -Value Update-Profile
Set-Alias -Name comphash -Value Compare-Checksum
Set-Alias -Name gethash -Value Get-Checksum

# === Alias Functions ===
Set-Item -Path function:src -Value { Enter-Location -Path "C:\Users\jwilding\source\repos\"                     -EnvVariable "SOURCE_DIR" }
Set-Item -Path function:dev -Value { Enter-Location -Path "C:\Users\jwilding\source\repos\FEPipeline-dev"       -EnvVariable "FE_PIPELINE_DEV" }
Set-Item -Path function:pub -Value { Enter-Location -Path "C:\Users\jwilding\source\repos\FEPipeline-public"    -EnvVariable "FE_PIPELINE_PUB" }


# Set-Item -Path function:cmp-hash -Value { Compare-Checksum -PathA $args[0] -PathB $args[1] -Algorithm "SHA256" -Output:$true }
# Set-Item -Path function:get-hash -Value { Get-Checksum -Path $args[0] -Algorithm "SHA256" -Recurse:$true -Output:$true }