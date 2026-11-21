# Block-Schmiede Starter
# Nimmt die neueste ZIP aus der Block-Schmiede (aus deinem Download-Ordner),
# installiert sie ins richtige Minecraft-Profil und oeffnet Minecraft.
#
# Benutzung: Doppelklick auf "Block-Schmiede Starter.bat"
#            oder eine ZIP-Datei auf die .bat ziehen.
# Probelauf ohne etwas zu veraendern: starter.ps1 -Test

param(
    [string]$Datei,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'

function Schreib([string]$text, [string]$farbe = 'Gray') { Write-Host $text -ForegroundColor $farbe }

function Waehle([string]$frage, $liste, [scriptblock]$anzeige) {
    $liste = @($liste)
    if ($liste.Count -eq 0) { return $null }
    Schreib ''
    Schreib $frage 'Yellow'
    for ($i = 0; $i -lt $liste.Count; $i++) {
        Schreib ('  [{0}] {1}' -f ($i + 1), (& $anzeige $liste[$i]))
    }
    if ($liste.Count -eq 1 -or $Test) {
        Schreib ('  -> nehme [1]') 'DarkGray'
        return $liste[0]
    }
    while ($true) {
        $antwort = Read-Host 'Nummer eingeben (Enter = 1)'
        if ([string]::IsNullOrWhiteSpace($antwort)) { return $liste[0] }
        $n = 0
        if ([int]::TryParse($antwort, [ref]$n) -and $n -ge 1 -and $n -le $liste.Count) { return $liste[$n - 1] }
        Schreib 'Bitte eine Nummer aus der Liste.' 'Red'
    }
}

function Version-Aus([string]$name) {
    if ($name -match 'mc(\d+\.\d+(?:\.\d+)?)') { return $Matches[1] }
    if ($name -match '\+([\d.]+)\.jar$') { return $Matches[1] }
    return ''
}

function Setze-Eigenschaften([string]$datei, [hashtable]$werte) {
    $zeilen = New-Object System.Collections.Generic.List[string]
    if (Test-Path $datei) { foreach ($z in [IO.File]::ReadAllLines($datei)) { $zeilen.Add($z) } }
    foreach ($key in $werte.Keys) {
        $gefunden = $false
        for ($i = 0; $i -lt $zeilen.Count; $i++) {
            if ($zeilen[$i] -match ('^\s*' + [regex]::Escape($key) + '\s*=')) { $zeilen[$i] = "$key=$($werte[$key])"; $gefunden = $true }
        }
        if (-not $gefunden) { $zeilen.Add("$key=$($werte[$key])") }
    }
    New-Item -ItemType Directory -Force (Split-Path $datei) | Out-Null
    [IO.File]::WriteAllLines($datei, $zeilen)
}

function Kopiere([string]$von, [string]$nachOrdner) {
    if ($Test) { Schreib "  (Test) wuerde kopieren nach: $nachOrdner" 'DarkGray'; return }
    New-Item -ItemType Directory -Force $nachOrdner | Out-Null
    Copy-Item -LiteralPath $von -Destination (Join-Path $nachOrdner (Split-Path $von -Leaf)) -Force
}

# ---------- 1. ZIP finden ----------
$downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
if ($Datei) {
    $zip = Get-Item -LiteralPath $Datei
} else {
    $zip = Get-ChildItem $downloads -Filter '*.zip' -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '-(shader|mod|datapack)-[\d.]+(\s*\(\d+\))?\.zip$' } |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if (-not $zip) {
    Schreib 'Keine Block-Schmiede-ZIP im Download-Ordner gefunden.' 'Red'
    Schreib 'Klicke zuerst in der Block-Schmiede auf "ZIP herunterladen".'
    return
}
if ($zip.Name -notmatch '-(shader|mod|datapack)-(\d+(?:\.\d+)*)') {
    Schreib "Bei $($zip.Name) weiss ich nicht, ob es ein Shader, eine Mod oder ein Datapack ist." 'Red'
    return
}
$art = $Matches[1]
$version = $Matches[2]
Schreib ''
Schreib '=== Block-Schmiede Starter ===' 'Cyan'
Schreib "Datei:   $($zip.Name)"
Schreib "Art:     $art   (Minecraft $version)"

# ---------- 2. Minecraft-Profile finden ----------
$ziele = @()
$mc = Join-Path $env:APPDATA '.minecraft'
if (Test-Path $mc) {
    $mods = Join-Path $mc 'mods'
    $ziele += [pscustomobject]@{
        Name = 'Minecraft Launcher (normales .minecraft)'; Pfad = $mc; Art = 'vanilla'; Version = ''
        Iris = [bool](Get-ChildItem $mods -Filter 'iris*.jar' -ErrorAction SilentlyContinue)
        OptiFine = [bool](Get-ChildItem $mods -Filter '*OptiFine*.jar' -ErrorAction SilentlyContinue)
        Fabric = [bool](Get-ChildItem $mods -Filter 'fabric-api*.jar' -ErrorAction SilentlyContinue)
    }
}
$modrinth = Join-Path $env:APPDATA 'ModrinthApp\profiles'
foreach ($p in (Get-ChildItem $modrinth -Directory -ErrorAction SilentlyContinue)) {
    $mods = Join-Path $p.FullName 'mods'
    $iris = Get-ChildItem $mods -Filter 'iris*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
    $fapi = Get-ChildItem $mods -Filter 'fabric-api*.jar' -ErrorAction SilentlyContinue | Select-Object -First 1
    $ver = ''
    if ($fapi) { $ver = Version-Aus $fapi.Name } elseif ($iris) { $ver = Version-Aus $iris.Name }
    $ziele += [pscustomobject]@{
        Name = "Modrinth: $($p.Name)"; Pfad = $p.FullName; Art = 'modrinth'; Version = $ver
        Iris = [bool]$iris; OptiFine = $false; Fabric = [bool]$fapi
    }
}
$curse = Join-Path $env:USERPROFILE 'curseforge\minecraft\Instances'
foreach ($p in (Get-ChildItem $curse -Directory -ErrorAction SilentlyContinue)) {
    $ver = ''
    $info = Join-Path $p.FullName 'minecraftinstance.json'
    if (Test-Path $info) { try { $ver = (Get-Content $info -Raw | ConvertFrom-Json).gameVersion } catch {} }
    $mods = Join-Path $p.FullName 'mods'
    $ziele += [pscustomobject]@{
        Name = "CurseForge: $($p.Name)"; Pfad = $p.FullName; Art = 'curseforge'; Version = $ver
        Iris = [bool](Get-ChildItem $mods -Filter 'iris*.jar' -ErrorAction SilentlyContinue)
        OptiFine = [bool](Get-ChildItem $mods -Filter '*OptiFine*.jar' -ErrorAction SilentlyContinue)
        Fabric = [bool](Get-ChildItem $mods -Filter 'fabric-api*.jar' -ErrorAction SilentlyContinue)
    }
}
if ($ziele.Count -eq 0) { Schreib 'Ich habe kein Minecraft gefunden.' 'Red'; return }

function Sortiere($liste) {
    # Profile mit genau der passenden Version zuerst
    @($liste | Sort-Object @{ Expression = { if ($_.Version -eq $version) { 0 } elseif ($_.Version) { 1 } else { 2 } } }, Name)
}
function Zeige($z) {
    $extra = @()
    if ($z.Version) { $extra += $z.Version }
    if ($z.Iris) { $extra += 'Iris' }
    if ($z.OptiFine) { $extra += 'OptiFine' }
    if ($z.Version -eq $version) { $extra += 'passt!' }
    if ($extra.Count) { return "$($z.Name)  [$($extra -join ', ')]" }
    return $z.Name
}

# ---------- 3. Installieren ----------
$ziel = $null
switch ($art) {
    'shader' {
        $kandidaten = @($ziele | Where-Object { $_.Iris -or $_.OptiFine })
        if ($kandidaten.Count -eq 0) {
            Schreib ''
            Schreib 'Kein Profil mit Iris oder OptiFine gefunden.' 'Red'
            Schreib 'Tipp: Installiere in der Modrinth App das Profil "Fabulously Optimized" - da ist Iris schon drin.'
            $kandidaten = $ziele
        }
        $ziel = Waehle 'In welches Profil soll der Shader?' (Sortiere $kandidaten) ${function:Zeige}
        Kopiere $zip.FullName (Join-Path $ziel.Pfad 'shaderpacks')
        if (-not $Test) {
            if ($ziel.Iris) {
                Setze-Eigenschaften (Join-Path $ziel.Pfad 'config\iris.properties') @{ shaderPack = $zip.Name; enableShaders = 'true' }
                Schreib 'Iris eingestellt: der neue Shader ist schon ausgewaehlt und eingeschaltet.' 'Green'
            }
            if ($ziel.OptiFine) {
                Setze-Eigenschaften (Join-Path $ziel.Pfad 'optionsshaders.txt') @{ shaderPack = $zip.Name }
                Schreib 'OptiFine eingestellt: der neue Shader ist schon ausgewaehlt.' 'Green'
            }
        }
    }
    'datapack' {
        # Alle Welten aus allen Profilen, zuletzt gespielte zuerst
        $welten = @(foreach ($z in $ziele) {
            foreach ($w in (Get-ChildItem (Join-Path $z.Pfad 'saves') -Directory -ErrorAction SilentlyContinue)) {
                $stand = $w.LastWriteTime
                $dat = Join-Path $w.FullName 'level.dat'
                if (Test-Path $dat) { $stand = (Get-Item $dat).LastWriteTime }
                [pscustomobject]@{ Welt = $w; Ziel = $z; Stand = $stand }
            }
        })
        $welten = @($welten | Sort-Object Stand -Descending | Select-Object -First 15)
        if ($welten.Count -eq 0) {
            Schreib 'Ich habe keine Welt gefunden. Erstelle zuerst eine Welt und starte mich dann nochmal.' 'Red'
        } else {
            $wahl = Waehle 'In welche Welt soll das Datapack? (zuletzt gespielte oben)' $welten {
                param($w)
                $v = if ($w.Ziel.Version) { ", $($w.Ziel.Version)" } else { '' }
                "$($w.Welt.Name)   ($($w.Ziel.Name)$v, zuletzt $($w.Stand.ToString('dd.MM.yyyy')))"
            }
            $ziel = $wahl.Ziel
            Kopiere $zip.FullName (Join-Path $wahl.Welt.FullName 'datapacks')
            Schreib "Datapack liegt in der Welt '$($wahl.Welt.Name)'. Im Spiel: /reload" 'Green'
            if ($ziel.Version -and $ziel.Version -ne $version) {
                Schreib "Achtung: Das Datapack ist fuer $version gebaut, das Profil hat $($ziel.Version)." 'Yellow'
            }
        }
    }
    'mod' {
        $basis = [IO.Path]::GetFileNameWithoutExtension($zip.Name)
        $ordner = Join-Path ([Environment]::GetFolderPath('MyDocuments')) "Block-Schmiede Mods\$basis"
        if ($Test) { Schreib "  (Test) wuerde entpacken nach: $ordner" 'DarkGray' }
        else { Expand-Archive -LiteralPath $zip.FullName -DestinationPath $ordner -Force }
        $jar = Get-ChildItem $ordner -Recurse -Filter '*.jar' -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\build\\libs\\' -and $_.Name -notmatch 'sources' } | Select-Object -First 1
        if ($jar) {
            $ziel = Waehle 'In welches Profil soll die Mod?' (Sortiere @($ziele | Where-Object { $_.Fabric })) ${function:Zeige}
            if ($ziel) { Kopiere $jar.FullName (Join-Path $ziel.Pfad 'mods'); Schreib "Mod $($jar.Name) installiert." 'Green' }
        } else {
            Schreib ''
            Schreib 'Eine Mod ist Quellcode und muss erst gebaut werden:' 'Yellow'
            Schreib '  1. Java (Temurin JDK) und IntelliJ IDEA Community installieren'
            Schreib "  2. In IntelliJ den Ordner oeffnen: $ordner"
            Schreib '  3. Im Gradle-Fenster "build" starten'
            Schreib '  4. Danach diesen Starter nochmal mit der ZIP starten - dann kopiere ich die fertige .jar in dein Profil.'
            if (-not $Test) { Start-Process explorer.exe $ordner }
            return
        }
    }
}

# ---------- 4. Minecraft oeffnen ----------
if (-not $ziel) { return }
Schreib ''
if ($Test) { Schreib "(Test) wuerde jetzt oeffnen: $($ziel.Name)" 'DarkGray'; return }
switch ($ziel.Art) {
    'modrinth' {
        $exe = $null
        try {
            $cmd = (Get-ItemProperty 'HKCU:\Software\Classes\modrinth\shell\open\command' -ErrorAction Stop).'(default)'
            if ($cmd -match '"([^"]+\.exe)"') { $exe = $Matches[1] }
        } catch {}
        if (-not $exe) { $exe = Join-Path $env:LOCALAPPDATA 'Modrinth App\Modrinth\Modrinth App\Modrinth App.exe' }
        if (Test-Path $exe) {
            Start-Process $exe
            Schreib "Die Modrinth App geht auf. Klicke beim Profil '$($ziel.Name -replace '^Modrinth: ', '')' auf Play." 'Green'
        } else { Schreib 'Modrinth App nicht gefunden. Starte sie selbst.' 'Red' }
    }
    'curseforge' { Schreib "Oeffne CurseForge und starte '$($ziel.Name -replace '^CurseForge: ', '')'." 'Green' }
    default {
        $store = Get-AppxPackage -Name 'Microsoft.4297127D64EC6' -ErrorAction SilentlyContinue
        $exe = @("${env:ProgramFiles(x86)}\Minecraft Launcher\MinecraftLauncher.exe", "$env:ProgramFiles\Minecraft Launcher\MinecraftLauncher.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
        if ($store) { Start-Process "shell:AppsFolder\$($store.PackageFamilyName)!Minecraft" }
        elseif ($exe) { Start-Process $exe }
        else { Schreib 'Minecraft Launcher nicht gefunden.' 'Red'; return }
        Schreib 'Der Minecraft Launcher geht auf. Waehle das passende Profil und klicke auf Spielen.' 'Green'
    }
}
