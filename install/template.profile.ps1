# === Profile Setup ===
$ProfileRoot = Split-Path -Parent $Profile.AllUsersAllHosts

$FormationModule = Join-Path $ProfileRoot "Modules" "FormationEffects"
$FormationEffectsProfile = Join-Path $FormationModule "Microsoft.PowerShell_profile.ps1"

$env:FormationModule = $FormationModule

. $FormationEffectsProfile