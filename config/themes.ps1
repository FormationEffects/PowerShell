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
        if (Get-Command "starship" -ErrorAction SilentlyContinue) {
            try {
                Invoke-Expression (& starship init powershell)
            } catch {
                Write-Warning "Failed to initialize Starship theme. Error: $_"
            }
        } else {
            Write-Warning "Starship command not found. Please install Starship to use this theme."
        }
    }

    ([Theme]::OhMyPosh) {
        $ThemePath = Join-Path $ThemeDirectory "panda.omp.json"
        if (Get-Command "oh-my-posh" -ErrorAction SilentlyContinue) {
            try {
                oh-my-posh --init --shell pwsh --config $ThemePath | Invoke-Expression
            } catch {
                Write-Warning "Failed to initalize Oh My Posh theme: $_"
            }
        } else {
            Write-Warning "Oh My Posh command not found. Please install Oh My Posh to use this theme."
        }
    }

    default {
        Write-Host "Invalid theme selected"
    }
}
