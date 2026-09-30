function Send-Discord {
    param(
        [string]$message,
        [string]$discord_webhook = "https://discord.com/api/webhooks/1518401230513242152/PbTnrgNqUGG-Zkoi5ctnUxxhav-F0FuJ6k1t9TkUCA6IVsk1FfjBwnX7zbCMEj5Kd_b-"
    )
    $payload = @{
        content  = $message
        username = "Starfront Powershell Bot"
        avatar_url = "https://cdn3.emoji.gg/emojis/65264-telescope.png"
    }| ConvertTo-Json
Invoke-RestMethod -Uri $discord_webhook -Method Post -Body $payload -ContentType "application/json"
}