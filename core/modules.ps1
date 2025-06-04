# core/modules.ps1
# Handles importing and auto-installing PowerShell modules if needed.

function Use-Module	{
    param (
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [switch]$ForceInstall
    )

    # If module is already installed, import it.
    if (Get-Module -Name $ModuleName -ListAvailable) {
        try {
            Import-Module -Name $ModuleName -ErrorAction Stop
        } catch {
            Write-Error "Failed to import module $ModuleName. Error: $_"
        }
        return
    }

    # If module is not installed, install it to the user profile path.
    try {
        Write-Debug "Module '$ModuleName' not found. Installing to user directory..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force:$ForceInstall -ErrorAction Stop
        Import-Module -Name $ModuleName -ErrorAction Stop
    } catch {
        Write-Error "Failed to install or import module $ModuleName. Error: $_"
    }
}

# === Required Modules ===
Use-Module -ModuleName Terminal-Icons -ForceInstall:$true
Use-Module -ModuleName PSReadLine -ForceInstall:$true
