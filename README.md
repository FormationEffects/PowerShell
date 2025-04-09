# Welcome to my personal PowerShell profile

This repository contains my personal PowerShell profile, which includes added functionality for the specific programs I code in.

## Table of Contents

[**Installation**](#installation)
  - [**Requirements**](#requirements)
  - [**Winget**](#winget)
  - [**Windows Terminal**](#windows-terminal)
  - [**PowerShell +7**](#powershell-7)
  - [**Oh-My-Posh**](#oh-my-posh)

[**Project Structure**](#project-structure)

[**Initialization Stages**](#initialization-stages)
  - [**Core**](#core)
  - [**Config**](#config)
    - [**Theming**](#theming)

[**Functions**](#functions)
  - [**PowerShell**](#powershell)
  - [**Python**](#python)


## Installation:

All programs should be installed using Administrator privileges.

### Requirements:
```Bash
Winget
PowerShell +7
Oh-My-Posh
Nerd-Font install
```

### Winget

Winget needs to be installed to run these commands, you have to install it via the Microsoft Store.

#### Winget Install Options:

```PowerShell
--id (Limit the search to this ID).
-s | --source (The source name, normally winget).
-e | --exact (Match exact string, so no preview).
-h | --silent (Disable UI, silent install).
--accept-package-agreements (Avoid License Agreement prompt).
--accept-source-agreements (Avoid Source License Agreement prompt).
```

### Windows Terminal:

Overall a better experience in terms of command-lines on Windows.

#### Install:

```PowerShell
winget install --id Microsoft.WindowsTerminal -s winget -e -h --accept-package-agreements --accept-source-agreements
```

### PowerShell +7

The heart of this profile repository, I've taken into account for older versions of PowerShell, but this is currently targeting PowerShell +7

#### Install:

```PowerShell
winget install --id Microsoft.PowerShell -s winget -e -h --accept-package-agreements --accept-source-agreements
```

### Oh-My-Posh

The main theme engine for Windows Terminal and PowerShell, as well as Nerd-Font install.

#### Links:

- **Oh-My-Posh** [Website](#https://ohmyposh.dev) | [Github](#https://github.com/jandedobbeleer/oh-my-posh)
- **Nerd-Fonts** [Website](#https://www.nerdfonts.com) | [Github](#https://github.com/ryanoasis/nerd-fonts)


#### Install Oh-My-Posh:

```PowerShell
winget install --id JanDeDobbeleer.OhMyPosh -s winget  -e -h --accept-package-agreements --accept-source-agreements
```

#### Install Nerd-Font (CaskaydiaCove Font Family):

```PowerShell
oh-my-posh font install CascadiaCode
```


## Project Structure:

```bash
├── config/
│   ├── funcs.pswh.ps1
│   ├── funcs.python.ps1
│   └── themes.ps1
├── core/
│   ├── core.ps1
│   └── modules.ps1
├── themes/
│   ├── panda.omp.json
│   ├── panda.omp.yaml
│   └── panda.starship.toml
├── .gitignore
├── Microsoft.PowerShell_profile.ps1
└── README.md
```

## Initialization Stages:

### Core

When this profile is first loaded, it will first dot-source the scripts located in [`core/`](./core/) in the following order:
- [core/modules.ps1](./core/modules.ps1)
- [core/core.ps1](./core/core.ps1)

Where [`modules.ps1`](./core/modules.ps1) will import, or install and import, the following PowerShell modules:
- **Terminal-Icons** [PowerShell Gallery](#https://www.powershellgallery.com/packages/Terminal-Icons/) | [Github](#https://github.com/devblackops/Terminal-Icons)
- **PSReadLine** [PowerShell Gallery](#https://www.powershellgallery.com/packages/PSReadLine) | [Github](#https://github.com/PowerShell/PSReadLine)

And [`core.ps1`](./core/core.ps1) will set common environment variables that are to be used in conjuction with the loaded modules, as well as Oh-My-Posh and PowerShell respectively.

### Config

After core has been loaded and configured, we then dot-source the files inside of the [`config/`](./config/) folder, with theming being loaded first, but in the current order:
- [config/themes.ps1](./config/themes.ps1)
- [config/funcs.pwsh.ps1](./config/funcs.pwsh.ps1)
- [config/funcs.python.ps1](./config/funcs.python.ps1)

I'll only touch on the [`themes.ps1`](./config/themes.ps1) as the rest of config just adds Functions to the environment, not actually adjusting the environment itself.

#### Theming

Right now the two terminal theme engines supported is [**Oh-My-Posh**](#https://ohmyposh.dev) and [**Starship**](#https://starship.rs), and I have a Theme enum at the start of the file itself.

The default theme is `OhMyPosh`, however you can set a environment variable to override this, or just change the default inside of [`config/themes.ps1`](./config/themes.ps1).

```bash
TerminalTheme=OhMyPosh
TerminalTheme=Starship
```

- OhMyPosh theme directly targets the json [`themes/panda.omp.json`](./themes/panda.omp.json)
- Starship theme directly targets the toml file [`themes/panda.starship.toml`](./themes/panda.starship.toml)


## Functions

### PowerShell

| Command | Alias | Description |
|----------|-------|-------------|
| [`Enter-Source`](#enter-source-alias-src) | `src` | Navigates to the source repo directory (hardcoded path). |
| [`Update-Profile`](#update-profile-alias-profileupdate) | `profileupdate` | Reloads your current PowerShell profile using. |
| [`Show-ProfileInfo`](#show-profileinfo-alias-profileinfo) | `profileinfo` | Prints out the path, folder, and file name of your PowerShell Profile. |
| [`Get-SystemReport`](#get-systemreport-alias-sysinfo) | `sysinfo` | Gets system info locally or remotely. |


- #### Enter-Source (Alias: src)
    [`/config/funcs.pwsh.ps1`](./config/funcs.pwsh.ps1)

    **Syntax**
    ```PowerShell
    Enter-Source
        []
    ```

    **Description:**
    ```
    This function changes the current directory to the source directory where the project files are located. It is useful for quickly accessing the source code directory.
    ```

- #### Update-Profile (Alias: profileupdate)
    [`/config/funcs.pwsh.ps1`](./config/funcs.pwsh.ps1)

    **Syntax**
    ```PowerShell
    Update-Profile
        []
    ```

    **Description:**
    ```
    This function updates the PowerShell profile by reloading it. It is useful for applying changes made to the profile without restarting PowerShell.
    ```

- #### Show-ProfileInfo (Alias: profileinfo)
    [`/config/funcs.pwsh.ps1`](./config/funcs.pwsh.ps1)

    **Syntax**
    ```PowerShell
    Show-ProfileInfo 
        []
    ```

    **Description:**
    ```
    This function displays the path, directory, and name of the PowerShell profile. It is useful for understanding where the profile is located and its name.
    ```

- #### Get-SystemReport (Alias: sysinfo)
    [`/config/funcs.pwsh.ps1`](./config/funcs.pwsh.ps1)

    **Syntax**
    ```PowerShell
    Get-SystemReport
        [-ComputerName <String>]
    ```

    **Description:**
    ```
    Gets a readout of the hardware currently installed on the given machine. If no ComputerName is passed, it will be run on the current machine.
    ```

    [TODO] NOT WORKING ON REMOTE MACHINE.


### Python

| Function | Alias | Description |
|----------|-------|-------------|
| [`Invoke-Venv`](#invoke-venv-alias-venv) | `venv` | Primary management of Virtual Environment. |
| [`Get-Venv`](#get-venv-alias-venv--a----activate) | `venv` | Activates / Deactivates the virtual environment.. |
| [`New-Venv`](#new-venv-alias-venv--c----create) | `venv -c` | Creates a new Python virtual environment in the current directory. |
| [`Reset-Venv`](#reset-venv-alias-venv--r----refresh) | `venv -r` | Resets the virtual environment.
| [`Remove-Venv`](#remove-venv-alias-venv--d----delete) | `venv -d` | Removes the current Python virtual environment directory. |
| [`Initialize-Requirements`](#initialize-requirements-alias-pyinstall) | `pyinstall` | Installs the requirements from requirements.txt. |
| [`Get-Requirements`](#get-requirements-alias-pyupdate) | `pyupdate` | Updates the requirements.txt file with the current environment's packages. |
| [`Reset-Requirements`](#reset-requirements-alias-pyreset) | `pyreset` | Resets the virtual environment and installs requirements. |


- #### Invoke-Venv (Alias: venv)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Invoke-Venv
        [-a | --activate <switch>] (Default)
        [-c | --create <switch>]
        [-d | --delete <switch>]
        [-r | --reset <switch>]
        [-h | --help <switch>]
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function provides a simple interface to create, activate, remove, or reset the virtual environment.
    It is useful for managing Python virtual environments in PowerShell.
    ```


- #### Get-Venv (Alias: venv -a | --activate)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Get-Venv
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function activates the virtual environment if it exists. If the virtual environment is already active, it deactivates it.
    ```

- #### New-Venv (Alias: venv -c | --create)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    New-Venv
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function creates a new virtual environment in the current directory. If a virtual environment already exists, it will not create a new one.
    ```


- #### Reset-Venv (Alias: venv -r | --refresh)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Reset-Venv
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function removes the existing virtual environment, creates a new one, and activates it.
    It is useful for refreshing the virtual environment with a clean state.
    ```


- #### Remove-Venv (Alias: venv -d | --delete)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Remove-Venv
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function removes the virtual environment if it exists. It deactivates the environment first if it is active.
    It is useful for cleaning up the virtual environment when it is no longer needed.
    ```

- #### Initialize-Requirements (Alias: pyinstall)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Initialize-Requirements
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function installs the packages listed in the requirements.txt file into the virtual environment.
    It is useful for setting up the environment with the necessary dependencies for a Python project.
    ```

- #### Get-Requirements (Alias: pyupdate)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Get-Requirements
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function generates a requirements.txt file based on the currently installed packages in the virtual environment.
    It is useful for creating a snapshot of the current environment's dependencies.
    ```

- #### Reset-Requirements (Alias: pyreset)
    [`/config/funcs.python.ps1`](./config/funcs.python.ps1)

    **Syntax**
    ```PowerShell
    Reset-Requirements
        [<CommonParameters>]
    ```

    **Description:**
    ```
    This function removes the existing virtual environment, creates a new one, and installs the requirements from requirements.txt.
    ```