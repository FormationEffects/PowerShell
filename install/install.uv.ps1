function Update-EnvironmentPath {
    <#
    .SYNOPSIS
      Updates the system PATH environment variable at the specified scope.

    .DESCRIPTION
      - Adds specified paths to the PATH variable if they are not already present.

        - Can prepend or append paths based on the Prepend switch.
        - Performs safety checks to ensure the new PATH is valid and does not remove critical directories.
    .PARAMETER env_scope
      The scope at which to update the PATH variable. Can be "Machine", "User",
        or "Process".
    .PARAMETER paths_to_add
        An array of paths to add to the PATH variable.
    .PARAMETER Prepend
        If specified, paths will be prepended to the PATH variable instead of appended.
    .EXAMPLE
      Update-EnvironmentPath -env_scope "Machine" -paths_to_add @("C:\Formation\Managers\uv", "C:\Formation\Managers\uv\tools") -Prepend
        Updates the machine-level PATH variable to include the specified directories,
            prepending them if the Prepend switch is used.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Machine", "User", "Process")]
        [string]$env_scope,
        [Parameter(Mandatory = $true)]
        [string[]]$paths_to_add,
        [Parameter(Mandatory=$false)]
        [Switch] $Prepend
    )

    Write-Output "Updating environment path at scope: $env_scope"
    
    
    $current_env_path = [Environment]::GetEnvironmentVariable("Path", $env_scope)
    $current_env_path_length = $current_env_path.Length
    $current_env_path_list = $current_env_path -split [IO.Path]::PathSeparator | Where-Object { $_ }

    # Add new paths if missing
    foreach ($path in $paths_to_add) {
        if ($current_env_path_list -notcontains $path) {
            if ($Prepend) {
                Write-Output "Prepending $path"
                $current_env_path_list = ,$path + $current_env_path_list | Where-Object { $_ } # Ensure no empty entries
            } else {
                Write-Output "Appending $path"
                 $current_env_path_list = $current_env_path_list + $path | Where-Object { $_ }
            }
        } else {
            Write-Warning "$path already exists."
        }
    }

    # Rebuild new PATH string
    $new_env_path = ($current_env_path_list | Where-Object { $_ }) -join [IO.Path]::PathSeparator
    $new_env_path_length = $new_env_path.Length

    Write-Output $new_env_path
    # === SAFETY CHECKS ===
    if ($new_env_path -notmatch "Windows\\System32") {
        Write-Error "New PATH is missing System32! Aborting."
        return
    }

    if ($new_env_path_length -lt $current_env_path_length) {
        Write-Error "New PATH is shorter than original ($new_env_path_length vs $current_env_path_length). Aborting."
        return
    }

    # Apply update if safe
    [Environment]::SetEnvironmentVariable("Path", $new_env_path, $env_scope)
    $env:Path = $new_env_path # Update current session
    Write-Output "PATH updated successfully!"
}

function Install-UV {
    <#
    .SYNOPSIS
      Install UV, set up environment variables, PATH, Python versions, and shell integration.

    .DESCRIPTION
      - If run as Administrator, writes ENV and PATH at Machine scope; otherwise at User scope
      - Defines UV_* environment variables
      - Ensures UV_INSTALL_DIR and UV_TOOL_BIN_DIR are in your PATH
      - Downloads and installs UV itself
      - Installs Python 3.11-preview as default
      - Runs `uv tool update-shell`
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
    param(
        [switch]$NonInteractive
    )
    $principal =  New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $scope = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $scope) {
        Write-Verbose "Running as non-Administrator; Please run this script as Administrator to set environment variables at Machine scope."
        return
    }
    
    Write-Verbose "Running as Administrator; setting environment variables at Machine scope."
    $env_scope = [EnvironmentVariableTarget]::Machine
    
    # ====== Stage 2: Make a backup of the environment variables, since we literally overwrite PATH
    $time_stamp = Get-Date -Format "yyyMMdd_HHmmss"

    # Backup root in ProgramData
    $backup_root = Join-Path $env:ProgramData "FormationEffects" "EnvironmentBackups"
    New-Item -ItemType Directory -Path $backup_root -Force | Out-Null
    
    # Create the backup file names
    $user_reg = Join-Path $backup_root "env_user_$($time_stamp).reg"
    $mach_reg = Join-Path $backup_root "env_mach_$($time_stamp).reg"

    # Create the user environment backup
    reg export "HKCU\Environment" $user_reg /y | Out-Null
    Write-Verbose "Created backup of user environment variables."

        # Create the machine environment backup
    reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" $mach_reg /y | Out-Null
    Write-Verbose "Created backup of machine environment variables."
    # ====== Stage 3: Setup the Environment variables as specific variables, and add them to the path.
    $env_vars = @{
        "UV_INSTALL_DIR"        = "C:\Formation\Managers\uv"
        "UV_TOOL_DIR"           = "C:\Formation\Managers\uv\tools"
        "UV_PYTHON_INSTALL_DIR" = "C:\Formation\Managers\uv\pythons"
        "UV_PYTHON_BIN_DIR"     = "C:\Formation\Managers\python\bin"
        "UV_CACHE_DIR"          = "C:\Formation\Managers\python\.cache"
        "UV_TOOL_BIN_DIR"       = "C:\Formation\Managers\python\.local\bin"
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
        if (-not $NonInteractive){
            if($PSCmdlet.ShouldProcess("$($env_scope) ENV $($name)", "Set to $($desired_value)")) {
                [Environment]::SetEnvironmentVariable($name, $desired_value, $env_scope)
                Set-Item -Path "Env:$name" -Value $desired_value # Update the current session's environment variable
            }
        } else {
            [Environment]::SetEnvironmentVariable($name, $desired_value, $env_scope)
            Set-Item -Path "Env:$name" -Value $desired_value # Update the current session's environment variable
        }
    }

    Write-Verbose "Set the UV environment variables at $env_scope scope."
    $paths_to_add = @($env_vars["UV_INSTALL_DIR"], $env_vars["UV_TOOL_BIN_DIR"], $env_vars["UV_PYTHON_BIN_DIR"])
    # New, safer way to update the PATH
    Update-EnvironmentPath -env_scope $env_scope -paths_to_add $paths_to_add -Prepend

    # ====== Stage 4: Ensure UV is installed
    if (-not (Get-Command "uv" -ErrorAction SilentlyContinue)) {
        if (-not $NonInteractive){
            if ($PSCmdlet.ShouldProcess("Install UV", "Download & execute installer")) {
                Write-Verbose "Downloading and running UV installer..."
                Invoke-Expression (Invoke-RestMethod "https://astral.sh/uv/install.ps1")
            }
        } else {
            Write-Verbose "Downloading and running UV installer..."
            Invoke-Expression (Invoke-RestMethod "https://astral.sh/uv/install.ps1")
        }
    } else {
        Write-Verbose "UV command already exists; skipping installation."
    }

    # Install the Python versions
    if (-not $NonInteractive){
        if($PSCmdlet.ShouldProcess("Install Python", "Install Python 3.11")) {
            Write-Verbose "Installing Python version 3.11 pinning to default."
            uv python install 3.11 --preview --default
        }
    } else {
        Write-Verbose "Installing Python version 3.11 pinning to default."
        uv python install 3.11 --preview --default
    }

    # Install ruff as well
    if (-not $NonInteractive){
        if($PSCmdlet.ShouldProcess("Install ruff", "Install ruff using uv tool install")) {
            Write-Verbose "Installing ruff..."
            uv tool install ruff
        }
    } else {
        Write-Verbose "Installing ruff..."
        uv tool install ruff
    }

    # Update shell integration
    if (-not $NonInteractive){
        if($PSCmdlet.ShouldProcess("Update shell integration", "Run uv tool update-shell")) {
            Write-Verbose "Updating shell integration..."
            uv tool update-shell
        }
    } else {
        Write-Verbose "Updating shell integration..."
        uv tool update-shell
    }
}