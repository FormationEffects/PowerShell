function Install-OhMyPosh {
    <#
    .SYNOPSIS
    Installs Oh My Posh for PowerShell.
    
    .DESCRIPTION
    This function installs Oh My Posh, a prompt theme engine for PowerShell.
    
    .EXAMPLE
    Install-OhMyPosh
    #>

    $winget_path = Resolve-Path -Path "C:\Program Files\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe" -ErrorAction SilentlyContinue

    if ($winget_path) {
        # Found a match, use it
        $winget_path = $winget_path.Path
    } else {
        # Fallback to default
        $winget_path = "winget.exe"
    }

    $app_name = "JanDeDobbeleer.OhMyPosh"
    $winget_install_args = "install $($app_name) --source winget --scope machine --accept-package-agreements --accept-source-agreements --force"
    $winget_update_args = "upgrade $($app_name) --source winget --scope machine --accept-package-agreements --accept-source-agreements --force"

    if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
        Write-Output "Oh My Posh is already installed, upgrading..."
        try {
            Start-Process -FilePath $winget_path -ArgumentList $winget_update_args -Wait -NoNewWindow
            Write-Output "Oh My Posh upgraded successfully."
        } catch {
            Write-Error "Failed to upgrade Oh My Posh: $_"
        }
    } else {
        Write-Output "Installing Oh My Posh..."
        try {
            Start-Process -FilePath $winget_path -ArgumentList $winget_install_args -Wait -NoNewWindow
            Write-Output "Oh My Posh installed successfully."
        } catch {
            Write-Error "Failed to install Oh My Posh: $_"
        }
    }
}

function Install-Fonts {
    <#
    .SYNOPSIS
    Installs the required fonts for Oh My Posh.
    
    .DESCRIPTION
    This function installs the Cascadia Code font, which is required for Oh My Posh themes.
    
    .EXAMPLE
    Install-Fonts
    #>

    if (-not (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue)) {
        Write-Error "Oh My Posh is not installed. Please install it first."
        return
    }
    Write-Output "Installing fonts: CascadiaCode"
    try {
        & "oh-my-posh" font install CascadiaCode
        Write-Output "Fonts installed successfully."
    } catch {
        Write-Error "Failed to install fonts: $_"
    }
}