function Install-Eza {
    <#
    .SYNOPSIS
    Installs Eza for PowerShell.
    
    .DESCRIPTION
    This function installs Eza, a modern replacement for the 'ls' command in PowerShell.
    
    .EXAMPLE
    Install-Eza
    #>

    $winget_path = Resolve-Path -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue

    if ($winget_path) {
        # Found a match, use it
        $winget_path = $winget_path.Path
    } else {
        # Fallback to default
        $winget_path = "winget.exe"
    }

    $app_name = "eza-community.eza"
    $winget_install_args = "install -e --id $($app_name) --source winget --accept-package-agreements --accept-source-agreements --force --silent"
    $winget_update_args = "upgrade -e --id $($app_name) --source winget --accept-package-agreements --accept-source-agreements --force --silent"

    if (Get-Command "eza" -ErrorAction SilentlyContinue) {
        Write-Output "Eza is installed. Upgrading..."
        try {
            Start-Process -FilePath $winget_path -ArgumentList $winget_update_args -Wait -NoNewWindow
            Write-Output "Eza upgraded successfully."
        } catch {
            Write-Error "Failed to upgrade Eza: $_"
        }
    } else {
        Write-Output "Eza not installed. Installing..."
        try {
            Start-Process -FilePath $winget_path -ArgumentList $winget_install_args -Wait -NoNewWindow
            Write-Output "Eza installed successfully."
        } catch {
            Write-Error "Failed to install Eza: $_"
        }
    }
}
