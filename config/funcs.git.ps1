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

    if ($branches -contains $ShowBranches) {
        git switch $ShowBranches
        return
    }

    # Try to suggest a closest match
    $suggested = Get-ClosestMatch -target $ShowBranches -candidates $branches

    Write-Host "ShowBranches '$($ShowBranches)' not found." -ForegroundColor Red
    if ($suggested) {
        Write-Host "Did you mean '$($suggested)'? All available: $($branches)" -ForegroundColor Yellow
    }

}

function Invoke-Git {
    [CmdLetBinding()]
    param(
        [Alias('b')][string]$ShowBranches,
        [Alias('p')][switch]$Push,
        [Alias('h')][switch]$Help
    )

    $actions = @()
    if ($ShowBranches) { $actions += "branch" }
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

function Invoke-GitTools {
    [CmdletBinding()]
    param(
        [Alias('d')][switch]$Diff,              # Show git diff
        [Alias('a')][switch]$Add,               # Add files to git staging area
        [Alias('ap')][switch]$AddPatch,         # Add files to git staging area with patch mode
        [Alias('c')][switch]$Commit,            # Commit changes to git
        [Alias('co')][switch]$Checkout,         # Checkout a branch or commit
        [Alias('p')][switch]$Push,              # Push changes to remote repository
        [Alias('u')][switch]$Pull,              # Pull changes from remote repository
        [Alias('l')][switch]$Log,               # Show git log
        [Alias('sb')][switch]$ShowBranches,     # Show git branches
        [Alias('i')][switch]$Init,              # Initialize a new git repository
        [Alias('cl')][switch]$Clone,            # Clone a remote git repository
        [Alias('s')][switch]$Status,            # Show git status
        [Alias('h')][switch]$Help,              # Show help message
        [Alias('m')][string]$Message,           # Commit message for git commit
        [Alias('url')][string]$RepoUrl,         # Repository URL for git clone
        [Alias('b')][string]$BranchName         # ShowBranches name for checkout
    )

    $actions = @()
    if ($Diff) { $actions += "diff" }
    if ($Add) { $actions += "add" }
    if ($AddPatch) { $actions += "add_patch" }
    if ($Commit) { $actions += "commit" }
    if ($Checkout) { $actions += "checkout" }
    if ($Push) { $actions += "push" }
    if ($Pull) { $actions += "pull" }
    if ($Log) { $actions += "log" }
    if ($ShowBranches) { $actions += "branch" }
    if ($Init) { $actions += "init" }
    if ($Clone) { $actions += "clone" }
    if ($Status) { $actions += "status" }
    if ($Help) { $actions += "help" }

    if ($actions.Count -gt 1) {
        Write-Error "Error: Please use only one switch at a time (e.g., -b <branch>, -p <push>, -h <help>)."
        return
    }

    $action = if ($actions.Count -eq 1) { $actions[0] } else { "help" } # Default to activate if no action is specified
    switch ($action) {
        "diff" { git diff --output-indicator-new=" " --output-indicator-old=" " }
        "add" { git add }
        "add_patch" {
            git add --patch
        }
        "commit" {
            if (-not $Message) {
                Write-Host "No commit message provided. Please enter a message." -ForegroundColor Yellow
                $Message = Read-Host "Enter commit message"
            } 
            git commit -m $Message
        }
        "checkout" {
            if (-not $BranchName) {
                Write-Host "No branch specified. Please enter a branch name." -ForegroundColor Yellow
                $BranchName = Read-Host "Enter branch name to checkout"
            }
            Switch-Branch -BranchName $BranchName
        }
        "push" { git push }
        "pull" { git pull }
        "log" { git log --all --graph --pretty=format:'%C(magenta)%h %C(white) %an %ar%C(auto) %D%n%s%n' }
        "branch" { git branch }
        "init" { git init }
        "clone" {
            if (-not $RepoUrl) {
                Write-Host "No repository URL provided. Please enter a URL." -ForegroundColor Yellow
                $RepoUrl = Read-Host "Enter repository URL to clone"
            }
            git clone $RepoUrl
        }
        "status" { git status }
        "help" {
            Write-Host "Usage: gt [-d] [-a] [-c] [-p] [-u] [-l] [-b] [-i] [-cl] [-s] [-h]" -ForegroundColor Cyan
            Write-Host "-d, --diff     Show git diff."
            Write-Host "-a, --add      Add files to git staging area."
            Write-Host "-c, --commit   Commit changes to git."
            Write-Host "-p, --push     Push changes to remote repository."
            Write-Host "-u, --pull     Pull changes from remote repository."
            Write-Host "-l, --log      Show git log."
            Write-Host "-sb, --branch   Show git branches."
            Write-Host "-i, --init     Initialize a new git repository."
            Write-Host "-cl, --clone   Clone a remote git repository."
            Write-Host "-s, --status   Show git status."
            Write-Host "-h, --help     Show this help message."
            Write-Host "-m, --message  Commit message for git commit."
            Write-Host "-url, --repo-url Repository URL for git clone."
            Write-Host "-b, --branch-name ShowBranches name for checkout."
        }
        default {
            Write-Host "Invalid action: $action" -ForegroundColor Red
            Write-Host "Available actions: diff (-d), add (-a), commit (-c), push (-p), pull (-u), log (-l), branch (-b), init (-i), clone (-cl), status (-s), help (-h)." -ForegroundColor Yellow
            Write-Host "Available options: -m <message>, -url <repo-url>, -b <branch-name>." -ForegroundColor Yellow
            Write-Host "Available aliases: ga (add), gc (commit), gp (push), gu (pull), glo (log), gb (branch), gs (status), gi (init), glc (clone)." -ForegroundColor Yellow
        }
    }
}


# === Aliases ===
Set-Alias -Name gt -Value Invoke-GitTools -Description "Invoke Git tools with various options."

# Aliases for common git commands
# Sourced fromL https://www.youtube.com/watch?v=G3NJzFX6XhY
Set-Item -Path function:gd -Value { Invoke-GitTools -d }    # "Show git diff"

Set-Item -Path function:ga -Value { Invoke-GitTools -a }    # "Add files to git staging area"
Set-Item -Path function:gap -Value { Invoke-GitTools -ap }  # "Add files to git staging area with patch mode"

Set-Item -Path function:gc -Value { Invoke-GitTools -c }    # "Commit changes to git"
Set-Item -Path function:gco -Value { Invoke-GitTools -co }  # "Checkout a branch or commit"

Set-Item -Path function:gp -Value { Invoke-GitTools -p }    # "Push changes to remote repository"
Set-Item -Path function:gu -Value { Invoke-GitTools -u }    # "Pull changes from remote repository"

Set-Item -Path function:glo -Value { Invoke-GitTools -l }   # "Show git log"
Set-Item -Path function:gb -Value { Invoke-GitTools -sb }   # "Show git branches"
Set-Item -Path function:gs -Value { Invoke-GitTools -s }    # "Show git status"

Set-Item -Path function:gi -Value { Invoke-GitTools -i }    # "Initialize a new git repository"
Set-Item -Path function:glc -Value { Invoke-GitTools -cl }  # "Clone a remote git repository"