# config/funcs.pwsh.ps1
# Specifically for PowerShell related functions and aliases.

function Enter-Source {
    <#
    .SYNOPSIS
        Naviagates to the source directory.

    .DESCRIPTION
        This function changes the current directory to the source directory where the project files are located.
        It is useful for quickly accessing the source code directory.

    .EXAMPLE
        Enter-Source
        src (alias for Enter-Source)
    #>

    Set-Location "C:\Users\Jaron\source\repos\"
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

# === Aliases ===
Set-Alias -Name src -Value Enter-Source
Set-Alias -Name sysinfo -Value Get-SystemReport
Set-Alias -Name profileinfo -Value Show-ProfileInfo
Set-Alias -Name profileupdate -Value Update-Profile