# Block-Schmiede KI

Eine Werkstatt für Minecraft: Beschreibe einen **Shader**, eine **Fabric-Mod** oder ein **Datapack**, und die KI baut alle Dateien, prüft sie und packt sie als ZIP.

**Ausprobieren:** https://mikkel-thiemann.github.io/block-schmiede/

## Was die Seite kann

- **KI-Bauen:** Shaderpacks für Iris/OptiFine, Fabric-Mods als Gradle-Projekt (mit Pixel-Texturen) und Datapacks für Minecraft 1.16.5 bis 1.21.8. Die KI kennt die Unterschiede zwischen den Versionen (pack_format, Ordnernamen, Item-Komponenten, Registry-Code).
- **Automatische Prüfung:** kaputtes JSON, fehlende Dateien, falsche Ordnernamen, fehlende Shader-Partner und mehr.
- **3D-Vorschau:** Der echte Shader-Code läuft live auf einer kleinen Minecraft-Insel (gbuffers, deferred, composite, final), mit Uhrzeit, Regen, Fotos und 8-Sekunden-Video.
- **Mod-Vorschau:** Items und Blöcke im Inventar-Look.
- **Ändern und Fehler-Doktor:** Änderungswünsche oder Fehlermeldungen einfügen, die KI repariert das Projekt.

> Die KI selbst läuft nur, wenn die Seite in Claude geöffnet wird. Auf GitHub Pages funktionieren das Beispiel, die 3D-Vorschau, Fotos, Video und der ZIP-Download.

## Direkt in Minecraft öffnen (Windows)

`Block-Schmiede Starter.bat` doppelklicken, nachdem die ZIP heruntergeladen wurde. Der Starter

1. nimmt die neueste Block-Schmiede-ZIP aus dem Download-Ordner,
2. findet Profile in der Modrinth App, in CurseForge und im normalen Launcher,
3. legt Shader in `shaderpacks` und schaltet sie in Iris direkt ein, oder legt Datapacks in eine Welt,
4. öffnet danach Minecraft.

Probelauf ohne Änderungen: `powershell -ExecutionPolicy Bypass -File starter.ps1 -Test`

## Dateien

- `index.html` – die Seite (Quelle)
- `docs/index.html` – die Seite für GitHub Pages, gebaut mit `build-github.ps1`
- `starter.ps1`, `Block-Schmiede Starter.bat` – der Starter für Windows
