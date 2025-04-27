$sourceDir = "C:\Users\VeniaminGorash\AppData\Local\Temp\postfix\postfix"  # Local directory with files and folders
$remoteUser = "VeniaminGorash"                                    # VM username
$remoteInstance = "smtp-proxy"                                    # VM instance name
$remoteBasePath = "/app/togotrek/postfix/"                                # Base destination path on VM
$zone = "us-west1-c"                                              # VM zone

# Get all files and directories recursively from the source directory
$items = Get-ChildItem -Path $sourceDir -Recurse

foreach ($item in $items) {
    # Calculate the relative path from the source directory
    $relativePath = $item.FullName.Substring($sourceDir.Length + 1)  # +1 to remove the trailing backslash
    Write-Host "relativePath: $relativePath"
    $remotePath = "$remoteBasePath$relativePath" -replace '\\', '/' # Convert Windows backslashes to Unix forward slashes
    Write-Host "remotePath: $remotePath"
    

    if ($item.PSIsContainer) {
        # If it's a directory, create it on the remote VM
        Write-Host "Creating directory $remotePath..."
        $sshCommand = "gcloud compute ssh $remoteUser@$remoteInstance --zone=$zone --command=`"mkdir -p $remotePath`""
        try {
            Invoke-Expression $sshCommand
            Write-Host "Successfully created directory $remotePath"
        } catch {
            Write-Host "Error creating directory $remotePath : $_"
        }
    } else {
        # If it's a file, copy it to the remote VM
        $localFilePath = $item.FullName
        $fileName = $item.Name
        Write-Host "Copying $fileName to $remotePath..."

        # Construct and execute the gcloud compute scp command
        $scpCommand = "gcloud compute scp `"$localFilePath`" $remoteUser@$remoteInstance`:$remotePath --zone=$zone"
        try {
            Invoke-Expression $scpCommand
            Write-Host "Successfully copied $fileName"
        } catch {
            Write-Host "Error copying $fileName : $_"
        }
    }
}