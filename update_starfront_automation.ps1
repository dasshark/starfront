function touch {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Path
    )
    process {
        if (Test-Path -LiteralPath $Path) {
            (Get-Item -LiteralPath $Path).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $Path
        }
    }
}

Set-Location $PSScriptRoot

git pull

touch -path "$($PSScriptRoot)\lastupdate.ts"