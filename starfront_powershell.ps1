Set-Location $PSScriptRoot
$config = Import-PowerShellDataFile -Path "./config.psd1"

Start-Transcript -OutputDirectory $config.automation_logs_path


$upload_base_path = $config.upload_base_path


#region functions
. ./send-discord.ps1

function Test-FTPDestination {
    $server = $config.ftp_destinaion_server
    $port = 21

    try {
        $client = New-Object System.Net.Sockets.TcpClient($server, $port)
        $client.Close()
        Write-Host "Success: Connected to $server on port $port!" -ForegroundColor Green
        Send-Discord -message "FTP Server is available." -discord_webhook $config.discord_webhook_uri
    } catch {
        Write-Host "Connection Failed: $($_.Exception.Message)" -ForegroundColor Red
        Send-Discord -message "FTP Server is **OFFLINE**.  Aborting file transfers."  -discord_webhook $config.discord_webhook_uri
        throw $PSItem
    }
}

function Test-NINASequencerState {
    try {
        $response = (Invoke-RestMethod -Uri "$($confi.local_nina_advancedapi_base_uri)/v2/api/sequence/state" -Method Get).Response
        if ($reqponse.state -eq "Running" -or $response.status -eq "Running") {
            Send-Discord -message "NINA: Sequencer still running.  **Aborting further file syncing** ." -discord_webhook $config.discord_webhook_uri
            throw $PSItem
        }
        else {
            Send-Discord -message "NINA: Sequencer not running. File transfer can continue." -discord_webhook $config.discord_webhook_uri
        }
    }
    catch {
        Send-Discord -message "NINA is not running. File transfer can continue." -discord_webhook $config.discord_webhook_uri
    }
}

function Send-TemplateFiles {
    $NINA_sequence_path = $config.NINA_sequence_path
    $NINA_sequence_template_path = $config.nina_sequence_template_path
    $NINA_targets_path = $config.nina_targets_path
    $NINA_sequence_count_tokeep = 1
    $NINA_logs_path = $config.nina_logs_path

    ##Sync NINA Logs
    Send-Discord -message "LOGS: Starting NINA Logs transfer" -discord_webhook $config.discord_webhook_uri
    & $($config.winscp_executable_path) $config.winscp_profile_name /command "synchronize remote $NINA_logs_path $($upload_base_path)/NINA_Logs/" "exit"
    Send-Discord -message "LOGS: NINA Log Files Transferred" -discord_webhook $config.discord_webhook_uri

    # NINA Template backup
    Send-Discord -message "TEMPLATE: Backing up sequence templates" -discord_webhook $config.discord_webhook_uri
    & $($config.winscp_executable_path) $config.winscp_profile_name /command "synchronize remote $($NINA_sequence_template_path) $($upload_base_path)/NINA_Sequence_Templates/" "exit"
    Send-Discord -message "TEMPLATE: Sequence template backup complete" -discord_webhook $config.discord_webhook_uri

    # NINA Sequence Backup
    Send-Discord -message "SEQUENCE: Backing up sequences" -discord_webhook $config.discord_webhook_uri
    $transfer_time = Measure-Command { & $($config.winscp_executable_path) $config.winscp_profile_name /command "put -neweronly $($NINA_sequence_path)/*.json $($upload_base_path)/NINA_Sequences" "exit" }
    Send-Discord -message "SEQUENCE: Sequence transfer completed in $($transfer_time.Minutes) minutes" -discord_webhook $config.discord_webhook_uri
    Send-Discord -message "SEQUENCE: Deleting all by last $($NINA_sequence_count_tokeep) sequence" -discord_webhook $config.discord_webhook_uri
    get-childitem -path "$($NINA_sequence_path)\*.json" | sort-object LastWriteTime  | select-object -skiplast $NINA_sequence_count_tokeep | Remove-Item

    # NINA Targets Backup
    Send-Discord -message "TARGETS: Backing up sequence targets" -discord_webhook $config.discord_webhook_uri
    & $($config.winscp_executable_path) $config.winscp_profile_name /command "synchronize remote $($NINA_targets_path) $($upload_base_path)/NINA_Targets/" "exit"
    Send-Discord -message "TARGETS: Sequence targets backup complete" -discord_webhook $config.discord_webhook_uri

}



function Send-Images {
    $foldernames = (Get-ChildItem -Path $config.captured_images_path -Directory -ErrorAction SilentlyContinue ).Name
    if ($foldernames) {
        Send-Discord -message "Un-sync'd imaging nights found: $(($foldernames).count)" -discord_webhook $config.discord_webhook_uri
        foreach ($foldername in $foldernames) {
            $images = Get-ChildItem -path "$($config.captured_images_path)\$($foldername)" -Filter "*.fits" -recurse | Group-Object DirectoryName | Select-Object Name, Count
            Send-Discord -message "IMAGELIST: Sending Files:`n  $($images | ForEach-Object {"$(($_.name).replace('$($config.captured_images_path)\','')) - $($_.count)`n"} )" -discord_webhook $config.discord_webhook_uri
            Send-Discord -message "IMAGES: Starting Images Transfer for folder $($foldername)" -discord_webhook $config.discord_webhook_uri
            $transfer_time = Measure-Command { & $($config.winscp_executable_path) $config.winscp_profile_name /command "put -neweronly $($config.captured_images_path)\$($foldername) $($upload_base_path)/" "exit" }
            Send-Discord -message "IMAGES: File transfer completed in $([Math]::Round($transfer_time.TotalMinutes)) minutes" -discord_webhook $config.discord_webhook_uri
            Move-Item -Path "$($config.captured_images_path)\$($foldername)" -Destination "$($config.transferred_images_path)\$($foldername)"
            Send-Discord -message "IMAGES: Transferred image folder moved to $($config.transferred_images_path)\$($foldername)" -discord_webhook $config.discord_webhook_uri
        }

    }
    else {
        Send-Discord -message "IMAGES: No images to backup" -discord_webhook $config.discord_webhook_uri
    }
}

#endregion functions

Test-FTPDestination
Send-TemplateFiles
Test-NINASequencerState
Send-Images


Stop-Transcript