<#
.SYNOPSIS
    Copies files from a local directory to a Google Cloud VM, preserving directory structure.
.DESCRIPTION
    Uses gcloud compute scp to copy files and gcloud compute ssh to create directories on the remote VM.
    Includes error handling, logging, and dry-run mode.
.PARAMETER SourceDir
    Local directory to copy files from (default: C:\Users\VeniaminGorash\AppData\Local\Temp\postfix\postfix).
.PARAMETER RemoteUser
    Username for the remote VM (default: VeniaminGorash).
.PARAMETER RemoteInstance
    Name of the Google Cloud instance (default: smtp-proxy).
.PARAMETER RemoteBasePath
    Base path on the remote VM (default: /app/togotrek/postfix/).
.PARAMETER Zone
    Google Cloud zone (default: us-west1-c).
.PARAMETER DryRun
    If specified, previews actions without executing them.
.EXAMPLE
    .\Copy-To-GCloudVM.ps1 -SourceDir "C:\Temp\postfix" -DryRun
    .\Copy-To-GCloudVM.ps1 -RemoteUser "user" -RemoteInstance "my-vm"
#>
param (
    [string]$SourceDir = "C:\Users\VeniaminGorash\AppData\Local\Temp\postfix\postfix",
    [string]$RemoteUser = "VeniaminGorash",
    [string]$RemoteInstance = "smtp-proxy",
    [string]$RemoteBasePath = "/app/togotrek/",
    [string]$Zone = "us-west1-c",
    [switch]$DryRun
)

# Initialize logging
$logFile = "Copy-To-GCloudVM-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

# Validate inputs
Write-Log "Validating inputs..."
if (-not (Test-Path $SourceDir)) {
    Write-Log "Source directory '$SourceDir' does not exist." "ERROR"
    exit 1
}
if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
    Write-Log "gcloud command not found. Ensure Google Cloud SDK is installed." "ERROR"
    exit 1
}

# Normalize paths
$SourceDir = (Resolve-Path $SourceDir).Path
$RemoteBasePath = $RemoteBasePath -replace '\\', '/' -replace '/$', ''

# Collect all files and directories
Write-Log "Collecting files and directories from '$SourceDir'..."
$items = Get-ChildItem -Path $SourceDir -Recurse
$directories = $items | Where-Object { $_.PSIsContainer } | ForEach-Object {
    $relativePath = $_.FullName.Substring($SourceDir.Length + 1) -replace '\\', '/'
    "$RemoteBasePath/$relativePath"
}
$files = $items | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    [PSCustomObject]@{
        LocalPath = $_.FullName
        RelativePath = $_.FullName.Substring($SourceDir.Length + 1) -replace '\\', '/'
        RemotePath = "$RemoteBasePath/" + ($_.FullName.Substring($SourceDir.Length + 1) -replace '\\', '/')
    }
}

# Create directories on remote VM
if ($directories) {
    Write-Log "Creating directories on remote VM..."
    $mkdirCommand = "mkdir -p " + ($directories -join ' ')
    $sshCommand = "gcloud compute ssh $RemoteUser@$RemoteInstance --zone=$Zone --command=`"$mkdirCommand`""
    if ($DryRun) {
        Write-Log "[DryRun] Would execute: $sshCommand"
    } else {
        try {
            Write-Log "Executing: $sshCommand"
            Invoke-Expression $sshCommand | ForEach-Object { Write-Log $_ }
            Write-Log "Directories created successfully."
        } catch {
            Write-Log "Failed to create directories: $_" "ERROR"
            exit 1
        }
    }
} else {
    Write-Log "No directories to create."
}

# Copy files to remote VM
Write-Log "Copying files to remote VM..."
foreach ($file in $files) {
    $scpCommand = "gcloud compute scp `"$($file.LocalPath)`" $RemoteUser@$RemoteInstance`:$($file.RemotePath) --zone=$Zone"
    if ($DryRun) {
        Write-Log "[DryRun] Would copy '$($file.LocalPath)' to '$($file.RemotePath)'"
    } else {
        try {
            Write-Log "Copying '$($file.LocalPath)' to '$($file.RemotePath)'..."
            Invoke-Expression $scpCommand | ForEach-Object { Write-Log $_ }
            Write-Log "Copied '$($file.LocalPath)' successfully."
        } catch {
            Write-Log "Failed to copy '$($file.LocalPath)': $_" "ERROR"
            # Continue with next file instead of exiting
        }
    }
}

Write-Log "File transfer completed."