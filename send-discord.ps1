function Send-Discord {
    param(
        [string]$message,
        [string]$discord_webhook
    )
    $payload = @{
        content  = $message
        username = "Starfront Powershell Bot"
        avatar_url = "https://cdn3.emoji.gg/emojis/65264-telescope.png"
    }| ConvertTo-Json
Invoke-RestMethod -Uri $discord_webhook -Method Post -Body $payload -ContentType "application/json"
}