# PowerShell Profile v1.0.1
# Author: Jaron Wilding

# === Profile Setup ===
$DefaultRoot = Split-Path -Parent $Profile
if ($env:FormationEffectsModule -and (Test-Path $env:FormationEffectsModule)) {
    $ModulePath = $env:FormationEffectsModule
} else {
    $ProfileRoot = Split-Path -Parent $Profile.AllUsersAllHosts
    $FormationModule = Join-Path $ProfileRoot "Modules" "FormationEffects"
    if (Test-Path $FormationModule) {
        $ModulePath = $FormationModule
    } else {
        Write-Warning "FormationEffects module not found at $FormationModule. Using default user root."
        $ModulePath = $DefaultRoot
    }
}

# === Core Setup ===
. "$ModulePath\core\modules.ps1" -ErrorAction Stop
. "$ModulePath\core\core.ps1" -ErrorAction Stop

# === Config Blocks ===
$ConfigFiles = @(
    "$ModulePath\config\themes.ps1",
    "$ModulePath\config\funcs.form.ps1",
    "$ModulePath\config\funcs.pwsh.ps1",
    "$ModulePath\config\funcs.python.ps1",
    "$ModulePath\config\funcs.git.ps1"
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
    # "$ModulePath\install\install.uv.ps1",
    # "$ModulePath\install\install.ohmyposh.ps1",
    # "$ModulePath\install\install.powershell.ps1",
)

foreach ($InstallFile in $InstallFiles) {
    if (Test-Path $InstallFile) {
        . $InstallFile -ErrorAction Stop
    } else {
        Write-Warning "Install file not found: $InstallFile"
    }
}

# === Completion Setup ===
$CompletionFiles = @(
    "$ModulePath\completion\_rez.ps1",
    "$ModulePath\completion\_eza.ps1"
)
foreach ($CompletionFile in $CompletionFiles) {
    if (Test-Path $CompletionFile) {
        . $CompletionFile -ErrorAction Stop
    } else {
        Write-Warning "Completion file not found: $CompletionFile"
    }
}