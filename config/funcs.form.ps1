# config/funcs.form.ps1
# Specifically for Formation Effects tooling.

class RobocopyFailure : System.Exception {
    RobocopyFailure([string]$message) : base($message) {}
}

function Copy-FileWithRobocopy {
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$DestDir,
        [string]$Filename,
        [int]$Threadcount = 1,
        [int]$RetryCount = 10,
        [int]$RetryDelay = 2
    )

    $src_path = Join-Path $SourceDir $Filename
    
    if (-not (Test-Path $src_path)) {
        throw [RobocopyFailure]::new("Source file '$src_path' does not exist.")
    }

    $robo_args = @(
        "/xc",  # Excludes changed files
        "/xn",  # Excludes newer files
        "/xo",  # Excludes older files
        $SourceDir,
        $DestDir,
        $Filename,
        "/njh",  # Specifies that there is no job header
        "/njs",  # Specifies that there is no job summary
        "/ndl",  # Specifies that directory names are not to be logged
        "/MT:$($Threadcount)",  # Creates multi-threaded copies with n threads
        "/R:$($RetryCount)",  # Specifies the number of retries on failed copies
        "/W:$($RetryDelay)",  # Specifies the wait time between retries (in seconds)
        "/TEE"  # Writes the status output to the console window
    )

    $process = Start-Process -FilePath "robocopy" -ArgumentList $robo_args -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -gt 8) {
        Write-Debug "Source: $($SourceDir), Destination: $($DestDir), Filename: $($Filename), Threadcount: $($Threadcount), RetryCount: $($RetryCount), RetryDelay: $($RetryDelay)"
        throw [RobocopyFailure]::new("Robocopy failed with exit code $($process.ExitCode). Check the parameters and ensure the source file exists.")
    }

    return $process.ExitCode
}

function Copy-AndRenameFileWithRobocopy {
    [CmdletBinding()]
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$DestDir,
        [string]$SourceFilename,
        [string]$DestFilename,
        [int]$Threadcount = 1,
        [int]$RetryCount = 10,
        [int]$RetryDelay = 2
    )

    $robo_run = Copy-FileWithRobocopy -SourceDir $SourceDir -DestDir $DestDir -Filename $SourceFilename -Threadcount $Threadcount -RetryCount $RetryCount -RetryDelay $RetryDelay

    $src_path = Join-Path $DestDir $SourceFilename

    if (Test-Path $src_path) {
        Rename-Item -Path $src_path -NewName $DestFilename -ErrorAction Stop
    }

    return $robo_run
}

function Copy-DirectoryWithRobocop {
    [CmdletBinding()]
    param (
        [string]$SourceDir,
        [string]$DestDir,
        [int]$Threadcount = 1,
        [int]$RetryCount = 10,
        [int]$RetryDelay = 2
    )

    $robo_args = @(
        "/xc",  # Excludes changed files
        "/xn",  # Excludes newer files
        "/xo",  # Excludes older files
        $SourceDir,
        $DestDir,
        "/e",  # Copies subdirectories (including empty directories)
        "/MT:$($Threadcount)",  # Creates multi-threaded copies with n threads
        "/R:$($RetryCount)",  # Specifies the number of retries on failed copies
        "/W:$($RetryDelay)",  # Specifies the wait time between retries (in seconds)
        "/TEE"  # Writes the status output to the console window
    )

    $process = Start-Process -FilePath 'robocopy' -ArgumentList $robo_args -NoNewWindow -Wait -PassThru

    if ($process.ExitCode -gt 8) {
        Write-Debug "Source: $($SourceDir), Destination: $($DestDir), Threadcount: $($Threadcount), RetryCount: $($RetryCount), RetryDelay: $($RetryDelay)"
        throw [RobocopyFailure]::new("Robocopy failed with exit code $($process.ExitCode).")
    }

    return $process.ExitCode
}

# function Copy-FilePreserveStructure {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory=$true)]
#         [string]$SourceRoot,

#         [Parameter(Mandatory=$true)]
#         [string]$DestinationRoot,

#         [Parameter(Mandatory=$true)]
#         [string[]]$FilesToCopy,

#         [int]$Threadcount = 1,
#         [int]$RetryCount = 10,
#         [int]$RetryDelay = 2
#     )
# }