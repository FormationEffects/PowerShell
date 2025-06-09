# PowerShell Profile v1.0.1
# Author: Jaron Wilding

# === Profile Setup ===
$ProfileRoot = Split-Path -Parent $Profile

# === Core Setup ===
. "$ProfileRoot\core\modules.ps1" -ErrorAction Stop
. "$ProfileRoot\core\core.ps1" -ErrorAction Stop

# === Config Blocks ===
$ConfigFiles = @(
    "$ProfileRoot\config\themes.ps1",
    "$ProfileRoot\config\funcs.pwsh.ps1",
    "$ProfileRoot\config\funcs.python.ps1"
)

foreach ($ConfigFile in $ConfigFiles) {
    if (Test-Path $ConfigFile) {
        . $ConfigFile -ErrorAction Stop
    } else {
        Write-Error "Config file not found: $ConfigFile"
    }
}

# === Install \ Setup Blocks ===
$InstallFiles = @(
    "$ProfileRoot\install\install.uv.ps1"
)

foreach ($InstallFile in $InstallFiles) {
    if (Test-Path $InstallFile) {
        . $InstallFile -ErrorAction Stop
    } else {
        Write-Warning "Install file not found: $InstallFile"
    }
}
