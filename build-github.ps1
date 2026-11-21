# Baut docs/index.html fuer GitHub Pages aus index.html.
# index.html ist ohne <html>/<head>, weil Claude das beim Veroeffentlichen selbst ergaenzt.
# Fuer GitHub Pages braucht es ein vollstaendiges HTML-Dokument.
$ordner = $PSScriptRoot
$inhalt = [IO.File]::ReadAllText((Join-Path $ordner 'index.html'))
$kopf = '<!doctype html><html lang="de"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">' +
        '<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0;font:14px system-ui,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style></head><body>'
New-Item -ItemType Directory -Force (Join-Path $ordner 'docs') | Out-Null
$utf8 = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $ordner 'docs\index.html'), $kopf + "`n" + $inhalt + "`n</body></html>`n", $utf8)
Write-Host 'docs/index.html ist fertig.'
