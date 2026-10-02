Set-Location $PSScriptRoot
$config = Import-PowerShellDataFile -Path "./config.psd1"
. ./send-discord.ps1

Send-Discord -message "REBOOT:  Starfront PC has rebooted" -discord_webhook $config.discord_webhook_uri