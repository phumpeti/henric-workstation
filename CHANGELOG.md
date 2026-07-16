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


## [0.5.0] - 2026-07-15

### Added

- Modular package installation framework
- Package verification functions
- Module discovery
- read_module()
- install_module()
- Logging framework
- VERSION file
- Improved CLI structure

### Changed

- Refactored project architecture
- Separated module and package responsibilities
- Improved bootstrap structure
- Improved logging

### Fixed

- Duplicate package functions removed
- Function ordering improved
- Various CLI bugs

## [0.6.0] - 2026-07-16

### Added

- Implemented --install option
- Installation sammanfattning
- Status codes.
- New modules constants.sh, exit_codes.sh. dev.sh

### Changed

- Structure Cleanup so that install related functions are in install.sh and so on.

### Fixed

- clean up of structure.
- correct handling of bootstrap.sh for source.
- fixed several bugs.

Status: Stabile
