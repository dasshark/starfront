Start-Transcript -OutputDirectory "D:\AutomationLogs"
Set-Location $PSScriptRoot  

$upload_base_path = "/LocallyBackup/starfront_unsorted"


#region functions
. ./send-discord.ps1

function Test-FTPDestination {
    $server = "nas2.tail236ed0.ts.net"
    $port = 21

    try {
        $client = New-Object System.Net.Sockets.TcpClient($server, $port)
        $client.Close()
        Write-Host "Success: Connected to $server on port $port!" -ForegroundColor Green
        Send-Discord -message "FTP Server is available."
    } catch {
        Write-Host "Connection Failed: $($_.Exception.Message)" -ForegroundColor Red
        Send-Discord -message "FTP Server is **OFFLINE**.  Aborting file transfers."
        throw $PSItem
    }
}

function Test-NINASequencerState {
    try {
        $response = (Invoke-RestMethod -Uri "http://localhost:1888/v2/api/sequence/state" -Method Get).Response
        if ($reqponse.state -eq "Running" -or $response.status -eq "Running") {
            Send-Discord -message "NINA: Sequencer still running.  **Aborting further file syncing** ."
            throw $PSItem
        }
        else {
            Send-Discord -message "NINA: Sequencer not running. File transfer can continue."
        }
    }
    catch {
        Send-Discord -message "NINA is not running. File transfer can continue."
    }
}

function Send-TemplateFiles {
    $NINA_sequence_path = "C:\Users\Brian\Documents\N.I.N.A"
    $NINA_sequence_template_path = "C:\Users\Brian\Documents\N.I.N.A\Templates"
    $NINA_targets_path = "C:\Users\Brian\Documents\N.I.N.A\Targets"
    $NINA_sequence_count_tokeep = 1
    $NINA_logs_path = "C:\Users\Brian\AppData\Local\NINA\Logs"

    ##Sync NINA Logs
    Send-Discord -message "LOGS: Starting NINA Logs transfer"
    & 'C:\Program Files (x86)\WinSCP\WinSCP.com' Home_UGREEN /command "synchronize remote $NINA_logs_path $($upload_base_path)/NINA_Logs/" "exit"
    Send-Discord -message "LOGS: NINA Log Files Transferred"

    # NINA Template backup
    Send-Discord -message "TEMPLATE: Backing up sequence templates"
    & 'C:\Program Files (x86)\WinSCP\WinSCP.com' Home_UGREEN /command "synchronize remote $($NINA_sequence_template_path) $($upload_base_path)/NINA_Sequence_Templates/" "exit"
    Send-Discord -message "TEMPLATE: Sequence template backup complete"

    # NINA Sequence Backup
    Send-Discord -message "SEQUENCE: Backing up sequences"
    $transfer_time = Measure-Command { & 'C:\Program Files (x86)\WinSCP\WinSCP.com' Home_UGREEN /command "put -neweronly $($NINA_sequence_path)/*.json $($upload_base_path)/NINA_Sequences" "exit" }
    Send-Discord -message "SEQUENCE: Sequence transfer completed in $($transfer_time.Minutes) minutes"
    Send-Discord -message "SEQUENCE: Deleting all by last $($NINA_sequence_count_tokeep) sequence"
    get-childitem -path "$($NINA_sequence_path)\*.json" | sort-object LastWriteTime  | select-object -skiplast $NINA_sequence_count_tokeep | Remove-Item

    # NINA Targets Backup
    Send-Discord -message "TARGETS: Backing up sequence targets"
    & 'C:\Program Files (x86)\WinSCP\WinSCP.com' Home_UGREEN /command "synchronize remote $($NINA_targets_path) $($upload_base_path)/NINA_Targets/" "exit"
    Send-Discord -message "TARGETS: Sequence targets backup complete"

}



function Send-Images {
    $foldernames = (Get-ChildItem -Path "D:\CapturedImages\" -Directory -ErrorAction SilentlyContinue ).Name
    if ($foldernames) {
        Send-Discord -message "Un-sync'd imaging nights found: $(($foldernames).count)"
        foreach ($foldername in $foldernames) {
            $images = Get-ChildItem -path "D:\CapturedImages\$($foldername)" -Filter "*.fits" -recurse | Group-Object DirectoryName | Select-Object Name, Count
            Send-Discord -message "IMAGELIST: Sending Files:`n  $($images | ForEach-Object {"$(($_.name).replace('D:\CapturedImages\','')) - $($_.count)`n"} )"
            Send-Discord -message "IMAGES: Starting Images Transfer for folder $($foldername)"
            $transfer_time = Measure-Command { & 'C:\Program Files (x86)\WinSCP\WinSCP.com' Home_UGREEN /command "put -neweronly d:\capturedimages\$($foldername) $($upload_base_path)/" "exit" }
            Send-Discord -message "IMAGES: File transfer completed in $($transfer_time.Minutes) minutes"
            Move-Item -Path "D:\CapturedImages\$($foldername)" -Destination "D:\TransferredImages\$($foldername)"
            Send-Discord -message "IMAGES: Transferred image folder moved to D:\TransferredImages\$($foldername)"
        }

    }
    else {
        Send-Discord -message "IMAGES: No images to backup"
    }
}

#endregion functions

Test-FTPDestination
Send-TemplateFiles
Test-NINASequencerState
Send-Images


Stop-Transcript