# Henric Workstation

Automatiserad installation och konfiguration av min Debian-arbetsstation.

## Mål

Projektet installerar och konfigurerar en komplett utvecklingsmiljö med:

- Debian
- Java
- Docker
- Git
- Samba
- Tailscale
- Nextcloud
- Flatpak
- Multimedia
- Testautomatisering
- EliteBook-specifika inställningar

Projektet är modulärt och kan användas för att återskapa en komplett arbetsstation från en ny Debian-installation.

## Exempel

Visa hjälp:

```bash
./bootstrap.sh --help
```

Visa installerbara moduler:

```bash
./bootstrap.sh --list
```

Visa sammanfattning:

```bash
./bootstrap.sh --summary
```

Kontrollera systemet:

```bash
./bootstrap.sh --doctor
```

Installera alla moduler:

```bash
./bootstrap.sh --install
```

Installera en specifik modul:

```bash
./bootstrap.sh --install development
```

Simulera installation:

```bash
./bootstrap.sh --install --dry-run
```

## Diagnostics

Run a full system diagnostic before installation:

```bash
./bootstrap.sh --doctor