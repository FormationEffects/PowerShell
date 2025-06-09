function Install-UV {
    <#
    .SYNOPSIS
      Install UV, set up environment variables, PATH, Python versions, and shell integration.

    .DESCRIPTION
      - If run as Administrator, writes ENV and PATH at Machine scope; otherwise at User scope
      - Defines UV_* environment variables
      - Ensures UV_INSTALL_DIR and UV_TOOL_BIN_DIR are in your PATH
      - Downloads and installs UV itself
      - Installs Python 3.11 & 3.12, then 3.13-preview as default
      - Runs `uv tool update-shell`
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param()

    # ====== Stage 1: Determine the scope we are running in.
    # Determine scope: Machine if admin, else User
    $principal =  New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $scope = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($scope) {
        Write-Verbose "Running as Administrator; setting environment variables at Machine scope."
        $env_scope = [EnvironmentVariableTarget]::Machine
    } else {
        Write-Verbose "Running as User; setting environment variables at User scope. Recommended to run as Administrator for full functionality."
        $env_scope = [EnvironmentVariableTarget]::User
    }
    
    # ====== Stage 2: Make a backup of the environment variables, since we literally overwrite PATH
    $script_dir = if ($PSSCriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Definition -Parent }

    $time_stamp = Get-Date -Format "yyyMMdd_HHmmss"
    $backup_dir = Join-Path $script_dir "backups"
    New-Item -ItemType Directory -Path $backup_dir -Force | Out-Null
    
    $user_reg = Join-Path $backup_dir "env_user_$($time_stamp).reg"
    $mach_reg = Join-Path $backup_dir "env_mach_$($time_stamp).reg"
    # Create the user environment backup
    reg export "HKCU\Environment" $user_reg /y | Out-Null
    Write-Verbose "Created backup of user environment variables."

    if ($scope) {
        # Create the machine environment backup
        reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" $mach_reg /y | Out-Null
        Write-Verbose "Created backup of machine environment variables."
    }

    # ====== Stage 3: Setup the Environment variables as specific variables, and add them to the path.
    $env_vars = @{
        "UV_INSTALL_DIR"        = "C:\Custom\Managers\uv"
        "UV_TOOL_DIR"           = "C:\Custom\Managers\uv\tools"
        "UV_PYTHON_INSTALL_DIR" = "C:\Custom\Managers\uv\pythons"
        "UV_PYTHON_BIN_DIR"     = "C:\Custom\Managers\python\bin"
        "UV_CACHE_DIR"          = "C:\Custom\Managers\python\.cache"
        "UV_TOOL_BIN_DIR"       = "C:\Custom\Managers\python\.local\bin"
    }
    # Ensure Environment Variables are set
    foreach ($name in $env_vars.Keys) {
        $desired_value = $env_vars[$name]
        Write-Verbose "$($name): $($env_scope) = $($desired_value)"
        $current = [Environment]::GetEnvironmentVariable($name, $env_scope)
        if ($current -eq $desired_value) {
            Write-Verbose "Value exists: $($current)"
            continue
        }
        if($PSCmdlet.ShouldProcess("$($env_scope) ENV $($name)", "Set to $($desired_value)")) {
            [Environment]::SetEnvironmentVariable($name, $desired_value, $env_scope)
            Set-Item -Path "Env:$name" -Value $desired_value # Update the current session's environment variable
        }
    }
    Write-Verbose "Set the UV environment variables at $env_scope scope."

    $paths_to_add = @($env_vars["UV_INSTALL_DIR"], $env_vars["UV_TOOL_BIN_DIR"], $env_vars["UV_PYTHON_BIN_DIR"])
    $existing = [Environment]::GetEnvironmentVariable('Path', $env_scope) -split ';' | Where-Object { $_ -and ($paths_to_add -notcontains $_) }
    $new_path = ($paths_to_add + $existing) -join ';'
    
    if ($PSCmdlet.ShouldProcess("$($env_scope) PATH", "Update to include new directories")) {
        [Environment]::SetEnvironmentVariable("Path", $new_path, $env_scope)
        $env:Path = $new_path # Update the current session's environment variable
        Write-Verbose "Updated PATH with new directories."
    }

    # ====== Stage 4: Ensure UV is installed
    if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
        if ($PSCmdlet.ShouldProcess("Install UV", "Download & execute installer")) {
            Write-Verbose "Downloading and running UV installer..."
            Invoke-Expression (Invoke-RestMethod "https://astral.sh/uv/install.ps1")
        }
    } else {
        Write-Verbose "UV command already exists; skipping installation."
    }
    # Install the Python versions
    if($PSCmdlet.ShouldProcess("Install Python", "Install Python 3.11, 3.12, and 3.13-preview")) {
        Write-Verbose "Installing Python versions 3.11, 3.12, and 3.13 and pinning to default."
        uv python install 3.11
        uv python install 3.12
        uv python install 3.13 --preview --default
    }

    # Install ruff as well
    if($PSCmdlet.ShouldProcess("Install ruff", "Install ruff using uv tool install")) {
        Write-Verbose "Installing ruff..."
        uv tool install ruff
    }

    # Update shell integration
    if($PSCmdlet.ShouldProcess("Update shell integration", "Run uv tool update-shell")) {
        Write-Verbose "Updating shell integration..."
        uv tool update-shell
    }
}