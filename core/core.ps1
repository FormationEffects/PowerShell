# core/core.ps1
# Core environment setup and configuration

# === Set Environment Variables ===
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
$env:POSH_GIT_ENABLED = $true # Posh-git integration: https://github.com/dahlbyk/posh-git
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Windows

if (Get-Command "uv" -ErrorAction SilentlyContinue) {
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
}

if (Get-Command "delta" -ErrorAction SilentlyContinue) {
    (& delta --generate-completion powershell) | Out-String | Invoke-Expression
}