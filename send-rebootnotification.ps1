Set-Location $PSScriptRoot
$config = Import-PowerShellDataFile -Path "./config.psd1"
. ./send-discord.ps1
$resboot_reason = Get-WinEvent -FilterHashtable @{LogName='System'; Id=1074,6008} -MaxEvents 1 | Select-Object TimeCreated, Id, Message

Send-Discord -message "REBOOT:  Starfront PC has rebooted `n>>> $($resboot_reason.Message)" -discord_webhook $config.discord_webhook_uri