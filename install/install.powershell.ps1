
function Install-FormationProfile {
    <#
    .SYNOPSIS
    Installs or updates Formation Effects PowerShell profile.
    
    .DESCRIPTION
    This script checks for the existence of the Formation Effects PowerShell profile directory, updates it if it exists, 
    or creates it if it does not. It also copies the profile script to the all users PowerShell profile location.
    
    .EXAMPLE
    Install-FormationProfile
    #>
    # --- CONFIG ---
    $RepoUrl    = "https://github.com/FormationEffects/PowerShell.git"
    # $ProfileFile = $Profile.AllUsersAllHosts
    $ProfileRoot = Split-Path -Parent $Profile.AllUsersAllHosts
    $ProfileFile = Join-Path $ProfileRoot "profile.ps1"

    $FormationModule = Join-Path $ProfileRoot "Modules" "FormationEffects"
    $FormationModuleGit = Join-Path $ProfileRoot "Modules" "FormationEffects" ".git"

    $SourceProfile = Join-Path $PSScriptRoot "template.profile.ps1"

    # --- FUNCTIONS ---
    function Test-Git {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            Write-Error "Git is not installed on this system."
            exit 1
        }
    }

    # --- MAIN LOGIC ---
    Test-Git

    Write-Output "Checking PowerShell profile directory: $($FormationModule)"

    if (Test-Path $FormationModule) {
        Write-Warning "Profile directory exists."

        if (Test-Path $FormationModuleGit) {
            Write-Output "Git repo detected. Pulling updates..."
            Push-Location $FormationModule
            git fetch --all
            git reset --hard origin/main
            git pull
            Pop-Location
        } else {
            Write-Warning "Clearing old contents..."
            Remove-Item $FormationModule -Recurse -Force

            # Clone fresh repo
            Write-Output "Cloning repository..."
            git clone $RepoUrl $FormationModule
        }
    } else {
        Write-Output "Profile directory does not exist. Creating and cloning..."
        New-Item -ItemType Directory -Path $FormationModule -Force | Out-Null
        git clone $RepoUrl $FormationModule
    }

    # --- COPY PROFILE TO ALL USERS ---
    if (-not (Test-Path $SourceProfile)) {
        Write-Error "profile.ps1 not found in PDQ additional files: $SourceProfile"
        exit 1
    }

    Write-Output "Copying profile to all users PowerShell profile: $ProfileFile"
    Copy-Item -Path $SourceProfile -Destination $ProfileFile -Force

    Write-Output "PowerShell profile synced successfully at: $FormationModule"
}
