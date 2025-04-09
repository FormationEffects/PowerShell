# config/funcs.python.ps1
# Specifically for Python related functions and aliases.

# Global Variables
$VENV_DIR_NAME = ".venv"

# == VENVS (Virtual Environment) Functions

function Get-Venv() {
    <# 
    .SYNOPSIS
        Activates the virtual environment.

    .DESCRIPTION
        This function activates the virtual environment if it exists. If the virtual environment is already active, it deactivates it.
        It is useful for managing Python virtual environments in PowerShell.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Get-Venv
        venv (Alias for Get-Venv).
    #>

    [CmdletBinding()]
    param()

    if (Test-Path env:VIRTUAL_ENV) {
        Write-Debug "Deactivating virtual environment."
        deactivate
        return
    }
    Get-ChildItem activate.ps1 -Recurse -Depth 2 | ForEach-Object{$_.FullName} | Invoke-Expression
}

function New-Venv() {
    <# 
    .SYNOPSIS
        Creates a new virtual environment.

    .DESCRIPTION
        This function creates a new virtual environment in the current directory. If a virtual environment already exists, it will not create a new one unless the -r switch is used.
        It is useful for setting up a new Python project with its own dependencies.

    .EXAMPLE
        New-Venv
        venv -c (Alias for New-Venv).
    #>

    [CmdletBinding()]
    param()

    # Sanity checks for the virtual environment directory name
    if (Test-Path env:VIRTUAL_ENV) {
        Write-Debug "Deactivating virtual environment."
        deactivate
    }
    if (Test-Path $VENV_DIR_NAME) {
        Write-Warning "Virtual environment already exists. Use -r to refresh it."
        return
    }
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Error "Python is not installed or not in the PATH."
        return
    }
    Write-Debug "Creating virtual environment."
    python -m venv $VENV_DIR_NAME
    Get-Venv -Verbose:$VerbosePreference
}

function Reset-Venv {
    <#
    .SYNOPSIS
        Resets the virtual environment.

    .DESCRIPTION
        This function removes the existing virtual environment, creates a new one, and activates it.
        It is useful for refreshing the virtual environment with a clean state.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Reset-Venv
        venv -rr (Alias for Reset-Venv).
    #>

    [CmdletBinding()]
    param()

    if (Test-Path env:VIRTUAL_ENV) {
        Write-Debug "Deactivating virtual environment."
        deactivate
    }
    if (Test-Path $VENV_DIR_NAME) {
        Write-Debug "Removing virtual environment."
        Remove-Item -Recurse -Force $VENV_DIR_NAME
    }
    New-Venv -Verbose:$VerbosePreference
}

function Remove-Venv {
    <#
    .SYNOPSIS
        Removes the virtual environment.

    .DESCRIPTION
        This function removes the virtual environment if it exists. It deactivates the environment first if it is active.
        It is useful for cleaning up the virtual environment when it is no longer needed.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Remove-Venv
        venv -r (Alias for Remove-Venv).
    #>
    [CmdletBinding()]
    param()

    # No need to do begin, process, and end blocks for a simple function
    # as it is not doing any complex operations.

    if (Test-Path env:VIRTUAL_ENV) {
        Write-Debug "Deactivating virtual environment."
        deactivate
    }
    if (Test-Path $VENV_DIR_NAME) {
        Write-Debug "Removing virtual environment."
        Remove-Item -Recurse -Force $VENV_DIR_NAME
        Write-Host "Virtual environment removed." -ForegroundColor Green
    } else {
        Write-Warning "No virtual environment found to delete."
    }
}

function Invoke-Venv() {
    <#
    .SYNOPSIS
        Manages the virtual environment.

    .DESCRIPTION
        This function provides a simple interface to create, activate, remove, or refresh the virtual environment.
        It is useful for managing Python virtual environments in PowerShell.

    .PARAMETER Create (alias -c)
        Creates a new virtual environment.
        
    .PARAMETER Activate (alias -a | default action)
        Activates the virtual environment.

    .PARAMETER Delete (alias -d)
        Removes the virtual environment (alias for -r).

    .PARAMETER Refresh (alias -r)
        Refreshes the virtual environment by removing and recreating it.

    .PARAMETER Help (alias -h)
        Displays help information.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        venv -c -Verbose // Creates a new virtual environment with verbose output
        venv -a -Debug // Activates the virtual environment (default action) with debug output
        venv -d -Verbose // Deletes the virtual environment with verbose output
        venv -r // Refreshes the virtual environment
        venv -h // Displays help information
    #>
    [CmdLetBinding()]
    param(
        [Alias('c')][switch]$Create,
        [Alias('a')][switch]$Activate,
        [Alias('d')][switch]$Delete,
        [Alias('r')][switch]$Refresh,
        [Alias('h')][switch]$Help
    )

    $actions = @()
    if ($Create) { $actions += "create" }
    if ($Activate) { $actions += "activate" }
    if ($Delete) { $actions += "delete" }
    if ($Refresh) { $actions += "refresh" }
    if ($Help) { $actions += "help" }

    if ($actions.Count -gt 1) {
        Write-Error "Error: Please use only one switch at a time (e.g., -c, -a, -d, -r, -h)."
        return
    }

    $action = if ($actions.Count -eq 1) { $actions[0] } else { "activate" } # Default to activate if no action is specified

    switch ($action) {
        "create" { New-Venv -Verbose:$VerbosePreference }
        "activate" { Get-Venv -Verbose:$VerbosePreference }
        "delete" { Remove-Venv -Verbose:$VerbosePreference }
        "refresh" { Reset-Venv -Verbose:$VerbosePreference }
        "help" {
            Write-Host "Usage: venv [-c] [-a] [-r] [-d] [-rr] [-h]" -ForegroundColor Cyan
            Write-Host "-c, --create   Create a new virtual environment."
            Write-Host "-a, --activate Activate the virtual environment."
            Write-Host "-d, --delete   Remove the virtual environment."
            Write-Host "-r, --refresh  Refresh the virtual environment."
            Write-Host "-h, --help     Show this help message."
            Write-Host "-Verbose       Show detailed output."
        }
        default {
            Write-Host "Invalid action: $action" -ForegroundColor Red
            Write-Host "Available actions: create (-c), activate (-a), delete (-d), refresh (-r), help (-h)." -ForegroundColor Yellow
        }
    }
}


# == Requirement and general Python Functions

function Initialize-Requirements() {
    <#
    .SYNOPSIS
        Installs the requirements from requirements.txt.

    .DESCRIPTION
        This function installs the packages listed in the requirements.txt file into the virtual environment.
        It is useful for setting up the environment with the necessary dependencies for a Python project.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Initialize-Requirements
        pyinstall (Alias for Initialize-Requirements).
    #>
    [CmdletBinding()]
    param()

    if (-not (Test-Path requirements.txt)) {
        Write-Warning "requirements.txt file not found. Please create it first."
        return
    }
    Write-Debug "Installing requirements from requirements.txt."
    pip install -r requirements.txt
    Write-Debug "Requirements installation completed."
}

function Get-Requirements() {
    <#
    .SYNOPSIS
        Updates the requirements.txt file with the current environment's packages.

    .DESCRIPTION
        This function generates a requirements.txt file based on the currently installed packages in the virtual environment.
        It is useful for creating a snapshot of the current environment's dependencies.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Get-Requirements
        pyupdate (Alias for Get-Requirements).
    #>
    [CmdletBinding()]
    param()

    Write-Debug "Generating requirements.txt from the current environment."
    pip freeze > requirements.txt
    Write-Debug "requirements.txt file updated."
}

function Reset-Requirements() {
    <#
    .SYNOPSIS
        Resets the virtual environment and installs requirements.

    .DESCRIPTION
        This function removes the existing virtual environment, creates a new one, and installs the requirements from requirements.txt.

    .INPUTS
        Accepts the standard arguments, such as -Verbose and -Debug.

    .OUTPUTS
        None

    .EXAMPLE
        Reset-Requirements
        pyreset (Alias for Reset-Requirements).
    #>
    [CmdletBinding()]
    param()

    Write-Debug "Resetting the virtual environment and installing requirements."
    Remove-Venv -Verbose:$VerbosePreference
    New-Venv -Verbose:$VerbosePreference
    Initialize-Requirements -Verbose:$VerbosePreference

    Write-Debug "Reset and installation of requirements completed."
}


# == Aliases for convenience
Set-Alias -Name venv -Value Invoke-Venv
Set-Alias -Name pyupdate -Value Get-Requirements
Set-Alias -Name pyinstall -Value Initialize-Requirements
Set-Alias -Name pyreset -Value Reset-Requirements