# core/core.ps1
# Core environment setup and configuration

# === Set Environment Variables ===
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView
Set-PSReadLineOption -EditMode Windows