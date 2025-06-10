# config/funcs.git.ps1
# Specifically for Git related functions and aliases.
function Get-ClosestMatch {
    param (
        [string]$target,
        [string[]]$candidates
    )

    $target = $target.ToLower()

    $scores = @{}

    foreach ($c in $candidates) {
        $cLower = $c.ToLower()
        $score = [Math]::Abs($target.Length - $cLower.Length)
        if ($target -like "*$cLower*" -or $cLower -like "*$target*") {
            $score -= 1
        }
        $scores[$c] = $score
    }

    return ($scores.GetEnumerator() | Sort-Object Value | Select-Object -First 1).Key
}

function Push-ToGit {
    [CmdletBinding()]
    param()

    $branch = git rev-parse --abbrev-ref HEAD
    Write-Host "Pushing branch '$($branch)' to GitHub and Gitlab..."
    git push github $branch
    git push gitlab $branch
}

function Switch-Branch {
    [CmdletBinding()]
    param(
        [string]$BranchName
    )
    # Get list of all branches (local + remote, remove remotes/origin/)
    $branches = git branch --all | ForEach-Object {
        $_.Trim() -replace '^\*?\s*remotes/[^/]+/', '' -replace '^\*?\s*', ''
    } | Sort-Object -Unique

    if ($branches -contains $Branch) {
        git switch $Branch
        return
    }

    # Try to suggest a closest match
    $suggested = Get-ClosestMatch -target $Branch -candidates $branches

    Write-Host "Branch '$($Branch)' not found." -ForegroundColor Red
    if ($suggested) {
        Write-Host "Did you mean '$($suggested)'? All available: $($branches)" -ForegroundColor Yellow
    }

}

function Invoke-Git {
    [CmdLetBinding()]
    param(
        [Alias('b')][string]$Branch,
        [Alias('p')][switch]$Push,
        [Alias('h')][switch]$Help
    )

    $actions = @()
    if ($Branch) { $actions += "branch" }
    if ($Push) { $actions += "push" }

    if ($actions.Count -gt 1) {
        Write-Error "Error: Please use only one switch at a time (e.g., -b <branch>, -p <push>, -h <help>)."
        return
    }

    $action = if ($actions.Count -eq 1) { $actions[0] } else { "help" } # Default to activate if no action is specified

    switch ($action) {
        "branch" { Switch-Branch -Verbose:$VerbosePreference }
        "push" { Push-ToGit -Verbose:$VerbosePreference }
        "help" {
            Write-Host "Usage: gh [-b] [-p] [-h]" -ForegroundColor Cyan
            Write-Host "-b, --branch   Switches the current repository to branch."
            Write-Host "-p, --push     Push to Github and Gitlab respectively."
            Write-Host "-h, --help     Show this help message."
            Write-Host "-Verbose       Show detailed output."
        }
        default {
            Write-Host "Invalid action: $action" -ForegroundColor Red
            Write-Host "Available actions: branch (-b), push (-p), help (-h)." -ForegroundColor Yellow
        }
    }


}

# === Aliases ===
Set-Alias -Name gt -Value Invoke-Git