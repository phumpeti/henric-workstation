# Changelog

Alla betydande förändringar i projektet dokumenteras här.

## v0.1.0 - 2026-07-05

Pointed at wrong folder for bootstrap.sh

## v0.4.0 - 2026-07-13

### Tillagt
- Modulär projektstruktur
- Miljökontroller
- Modulupptäckt
- Paketräkning
- Sammanfattning
- Kommandoradsargument
- `--help`
- `--list`
- `--summary`

### Förändrat
- Refaktorerat till bibliotek i `lib/`
- Infört `main()` som programmets startpunkt


## [0.4.1] - 2026-07-13

### Added
- Stöd för `--version`
- Förbättrad hantering av kommandoradsargument

### Changed
- Refaktorerat CLI till `lib/cli.sh`
- Förbättrad felhantering för okända argument
- Hjälptext visas endast med `--help` eller `-h`
- Installationsmotorn körs i "dry run"-läge och skriver ut vilka paket som skulle installeras

### Fixed
- Åtgärdat felaktig argumentöverföring (`$0` → `"$@"`)
- Åtgärdat flera buggar i `case`-hanteringen
- Korrigerat syntaxfel i `cli.sh`
