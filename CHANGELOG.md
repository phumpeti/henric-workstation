# Changelog

Alla betydande förändringar i projektet dokumenteras här.

## [0.9.0] - 2026-09-15

### Tillagt

* Omfattande testsvit med 99 gröna tester för kärnfunktioner, CLI, systemdiagnostik, moduler, paket och backends.
* Backendstöd för APT, Flatpak och npm testas separat och i kombination med modulsystemet.
* Tailscale-repositoryhantering har fått testbar konfiguration för repository-filen.
* Systemidentifiering har fått testbar konfiguration för `/etc/os-release`.
* Systemuppdatering via `--update` med stöd för APT, Flatpak och npm.
* Stöd för `--dry-run --update` för att simulera systemuppdateringar utan att utföra ändringar.
* Testtäckning för uppdateringsfunktionerna, inklusive lyckade körningar, felhantering och CLI-statuskoder.

### Förändrat

* `--list` visar nu moduler grupperade under backend (`APT`, `FLATPAK`, `NPM`) med paketantal per modul.
* `print_modules()` följer den aktuella katalogstrukturen under `packages/<backend>/`.
* Paketantal per modul beräknas via `read_module()` så att tomma rader och kommentarer inte räknas.
* `check_commands()` har konsoliderats till en gemensam, parameteriserad implementation.
* CLI-hjälp och versionshantering använder `APP_VERSION` konsekvent.
* CLI:t har rensats från temporära DEBUG-utskrifter.
* Produktionskoden har anpassats för mer deterministisk testning.
* `update_system()` kör uppdatering av APT, Flatpak och npm i följd.
* Systemuppdateringen fortsätter även om en backend misslyckas och rapporterar felstatus efter avslutad körning.
* README.md har kompletterats med dokumentation för `--update` och `--dry-run --update`.

### Fixat

* Rättat `--version` så att korrekt versionsvariabel används.
* Rättat `--help` så att korrekt versionsvariabel används.
* Rättat `--list` efter att paketdata flyttats till backend-specifika kataloger.
* Tagit bort en gammal `count_packages()`-referens i `print_modules()`.
* Tagit bort den äldre dubbla `check_commands()`-implementationen.
* Tagit bort den gamla interna `test_read_module()`-hjälpfunktionen.
* Rensat bort temporära felsökningsutskrifter från CLI:t.
* Säkerställt att felstatus från uppdateringskommandot förs vidare genom CLI:t.

## [0.6.1] - 2026-08-10

### Tillagt

* Modulär systemdiagnostik (`doctor`).
* Identifiering av operativsystem.
* Identifiering av CPU-arkitektur.
* Sudo-diagnostik.
* Paketmanager-diagnostik.
* Diagnostik av nödvändiga kommandon.
* Diagnostikutskrift grupperad i sektioner.

### Förändrat

* Systemidentifiering refaktorerad till separata `detect`-/`check`-funktioner.
* Förbättrad projektarkitektur med tydligare ansvar mellan komponenterna.

### Fixat

* Förbättrad Bash-felhantering.
* Förbättrad statushantering för paketinstallation.

## [0.6.0] - 2026-07-20

### Tillagt

* Nytt installationssystem.
* Stöd för installation av enskilda moduler (`--install <modul>`).
* Stöd för `--dry-run`.
* Nytt diagnostikkommando (`--doctor`).
* Installationssammanfattning med statistik.
* Gemensamma statuskoder och exit-koder.
* Projektkonstanter i egen modul.

### Förändrat

* Projektet har delats upp i mindre moduler med tydligare ansvar.
* CLI:t har refaktorerats och stöder flera argument.
* Installationsflödet har förenklats och blivit mer modulärt.
* Förbättrad loggning och utskrift under installation.
* Förbättrad struktur för felsökning och framtida utbyggnad.

### Fixat

* Flera problem i argumenthanteringen.
* Korrekt hantering av `set -Eeuo pipefail`.
* Flera problem med `readonly`-variabler.
* Flera fel i installationsflödet.

## [0.5.0] - 2026-07-15

### Tillagt

* Modulärt installationsramverk för paket.
* Funktioner för paketverifiering.
* Modulupptäckt.
* `read_module()`.
* Installationsfunktioner.
* Loggningsramverk.
* `VERSION`-fil.
* Förbättrad CLI-struktur.

### Förändrat

* Refaktorerad projektarkitektur.
* Tydligare separation mellan moduler och paket.
* Förbättrad bootstrap-struktur.
* Förbättrad loggning.

### Fixat

* Dubbla paketfunktioner tagits bort.
* Förbättrad funktionsordning.
* Olika CLI-buggar åtgärdade.

## [0.4.1] - 2026-07-13

### Tillagt

* Stöd för `--version`.
* Förbättrad hantering av kommandoradsargument.

### Förändrat

* CLI refaktorerat till `lib/cli.sh`.
* Förbättrad felhantering för okända argument.
* Hjälptext visas med `--help` eller `-h`.
* Installationsmotorn kan köras i dry-run-läge och visar vilka paket som skulle installeras.

### Fixat

* Åtgärdad felaktig argumentöverföring (`$0` → `"$@"`).
* Åtgärdade buggar i `case`-hanteringen.
* Korrigerat syntaxfel i `cli.sh`.

## [0.4.0] - 2026-07-13

### Tillagt

* Modulär projektstruktur.
* Miljökontroller.
* Modulupptäckt.
* Paketräkning.
* Sammanfattning.
* Kommandoradsargument.
* `--help`.
* `--list`.
* `--summary`.

### Förändrat

* Refaktorerat till bibliotek i `lib/`.
* Infört `main()` som programmets startpunkt.

## [0.1.0] - 2026-07-05

### Fixat

* Pekade på fel mapp för `bootstrap.sh`.

---

Status: Stabil
