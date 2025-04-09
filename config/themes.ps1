# config/themes.ps1
# Theme configuration for PowerShell

# === Themes enum ===
enum Theme {
    Starship
    OhMyPosh
}

# === Config ===
$Global:CurrentTheme = [Theme]::OhMyPosh
$ThemeDirectory = Join-Path (Split-Path -Parent $Profile) "themes"

switch ($Global:CurrentTheme) {
    # The enums need to be surrounded by parentheses to be evaluated correctly.
    ([Theme]::Starship) {
        $env:STARSHIP_CONFIG = Join-Path $ThemeDirectory "panda.starship.toml"
        try {
            Invoke-Expression (& starship init powershell)
        } catch {
            Write-Error "Failed to initialize Starship theme. Error: $_"
        }
    }

    ([Theme]::OhMyPosh) {
        $ThemePath = Join-Path $ThemeDirectory "panda.omp.json"
        $env:POSH_GIT_ENABLED = $true
        try {
            oh-my-posh --init --shell pwsh --config $ThemePath | Invoke-Expression
        } catch {
            Write-Error "Failed to initalize Oh My Posh theme: $_"
        }
    }

    default {
        Write-Host "Invalid theme selected"
    }
}
