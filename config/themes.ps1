# config/themes.ps1
# Theme configuration for PowerShell

# === Themes enum ===
enum Theme {
    Starship
    OhMyPosh
}

# === Config ===
$defaultTheme = [Theme]::OhMyPosh
$Global:CurrentTheme = $defaultTheme
$ThemeDirectory = Join-Path (Split-Path -Parent $Profile) "themes"

if ($env:TerminalTheme) {
    try {
        $parsedTheme = [Theme]::Parse([Theme], $env:TerminalTheme, $true)
        $Global:CurrentTheme = $parsedTheme
        Write-Debug "Parsed theme from environment variable: $parsedTheme"
    } catch {
        Write-Debug "Failed to parse theme from environment variable. Defaulting to OhMyPosh."
    }
} else {
    Write-Debug "No theme specified in environment variable. Defaulting to OhMyPosh."
}


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
