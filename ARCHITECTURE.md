# Architecture

## Overview

Henric Workstation is a modular Bash application for installing,
updating and diagnosing a Debian workstation.

The project separates command-line handling, application orchestration,
module processing, package backends, repository handling and system
diagnostics.

The main components are:

- `bootstrap.sh` — application entry point
- `lib/cli.sh` — command-line parsing and dispatch
- `lib/install_core.sh` — installation interface
- `lib/update.sh` — update orchestration
- `lib/modules.sh` — module discovery and processing
- `lib/packages.sh` — package-related operations
- `lib/repositories.sh` — repository preparation
- `lib/apt.sh` — APT backend
- `lib/flatpak.sh` — Flatpak backend
- `lib/npm.sh` — npm backend
- `lib/doctor.sh` — diagnostic orchestration
- `lib/system.sh` — system checks
- `lib/common.sh` — shared utilities and presentation
- `packages/` — package definitions
- `tests/` — automated tests

## Application flow

The application starts in `bootstrap.sh`.

```text
bootstrap.sh
    |
    +-- cli.sh
    |     |
    |     +-- install_core.sh
    |     |       |
    |     |       +-- modules.sh
    |     |               |
    |     |               +-- apt.sh
    |     |               +-- flatpak.sh
    |     |               +-- npm.sh
    |     |
    |     +-- update.sh
    |     |
    |     +-- doctor.sh
    |             |
    |             +-- system.sh
    |
    +-- common.sh
    +-- packages.sh
    +-- repositories.sh
```

`bootstrap.sh` is responsible for loading the application libraries and
starting the command-line interface. It does not contain the actual
installation, update or diagnostic logic.

## Command-line interface

`lib/cli.sh` handles command-line arguments and dispatches the requested
operation to the appropriate subsystem.

The main operations are:

- `--help`
- `--version`
- `--list`
- `--summary`
- `--doctor`
- `--install`
- `--update`
- `--dry-run`

A module name can also be supplied to install a specific module.

The CLI layer is intentionally kept separate from the implementation of
installation, updates and diagnostics.

## Installation

`lib/install_core.sh` provides the public installation interface.

It supports:

- installing all available modules
- installing a named module

The installation interface delegates the actual work to
`lib/modules.sh`.

This keeps the CLI and installation entry points independent from the
details of individual package managers.

## Module system

`lib/modules.sh` is responsible for discovering and processing modules.

Modules are stored as text files below `packages/` and are grouped
according to their package backend.

The module system is responsible for:

- discovering modules
- finding a named module
- reading module definitions
- identifying the appropriate backend
- loading backend implementations
- checking whether packages are installed
- identifying missing packages
- preparing required repositories
- delegating package installation

The module system orchestrates package processing but does not implement
the individual package managers.

### Module naming

Module files use a numeric prefix to determine their ordering.

For example:

```text
01-base.txt
02-network.txt
03-development.txt
```

The module name is the part following the numeric prefix.

Blank lines and comments in module files are ignored.

## Package backends

Package-manager implementations are isolated in separate backend files.

The currently supported backends are:

```text
APT
Flatpak
npm
```

The module system maps each backend to the functions required for package
state checking and installation.

### APT

`lib/apt.sh` handles Debian packages using APT and `dpkg`.

It provides package installation and APT system updates.

### Flatpak

`lib/flatpak.sh` handles Flatpak applications.

It provides Flatpak installation and Flatpak updates.

### npm

`lib/npm.sh` handles globally installed npm packages.

The npm backend uses a user-local prefix under:

```text
$HOME/.local
```

It provides npm package installation and updates.

Backend implementations also handle their own `--dry-run` behaviour.

## Package definitions

Package definitions are stored under `packages/`.

```text
packages/
├── apt/
├── flatpak/
├── npm/
└── README.MD
```

Each backend directory contains module files.

The contents of a module file are package names, one per line.

The package definition layer is intentionally separated from the Bash
implementation. This allows the workstation configuration to be changed
by editing package lists rather than modifying installation logic.

## Package handling

`lib/packages.sh` contains package-related helper operations.

It is used for tasks such as:

- checking whether a package exists
- checking whether a package is installed
- verifying package state
- counting packages defined by the project

Package installation itself remains the responsibility of the relevant
backend.

## Repository handling

`lib/repositories.sh` handles repositories that must be prepared before
certain packages can be installed.

The current implementation contains support for the Tailscale
repository.

Repository handling is separated from package installation so that
backend code does not need to contain repository-specific configuration.

The module processing layer can determine whether a package requires
repository preparation before installation.

## Updates

`lib/update.sh` provides the system-wide update operation.

Updates are performed through the supported backends in this order:

1. APT
2. Flatpak
3. npm

The update process attempts all supported backends even if one backend
fails.

If one or more backends fail, the overall update operation returns a
failure status after all backends have been attempted.

This prevents one failed package manager from preventing the remaining
package managers from being updated.

## Dry-run

Dry-run support is handled by the operations that would normally modify
the system.

When `--dry-run` is active, package installation and update operations
report what they would do without performing the corresponding changes.

The orchestration layers continue to execute normally so that the user
can inspect the intended operations.

## Diagnostics

`lib/doctor.sh` orchestrates the diagnostic system.

`lib/system.sh` contains checks for the host environment, including:

- operating system
- CPU architecture
- sudo availability
- network connectivity
- package manager availability
- required commands

The diagnostic system also checks that the project contains required
files and directories.

The doctor command produces a summary of successful checks, informational
messages, warnings and errors.

## Shared utilities

`lib/common.sh` contains functionality shared by several parts of the
application.

This includes:

- status and logging output
- success, information, warning and error messages
- section and banner output
- environment checks
- command checks
- installation summaries
- help output

Messages are currently written to standard error.

The project does not currently implement file-based application logging.

## Constants and exit codes

`lib/constants.sh` contains shared constants used by the application,
including command lists used by system diagnostics.

`lib/exit_codes.sh` contains named application exit codes.

Only exit codes that are actively used by the application should be
considered part of its effective exit-code interface.

## Testing

The project currently uses a single test runner:

```text
tests/tests.sh
```

The test suite covers the main application subsystems, including:

- module discovery and processing
- package handling
- repositories
- npm handling
- command-line handling
- installation
- diagnostics
- system checks
- common utilities
- package backends
- updates
- failure paths

Tests are grouped by subsystem within the test file.

The project also contains test fixtures under:

```text
tests/fixtures/
```

## Development environment

`scripts/dev.sh` provides a development shell by sourcing
`bootstrap.sh` without executing the normal CLI entry point.

This allows project functions and libraries to be used interactively
during development and testing.

## Project structure

The main project structure is:

```text
.
├── bootstrap.sh
├── VERSION
├── README.md
├── ARCHITECTURE.md
├── CODING_STANDARD.md
├── CHANGELOG.md
├── fixes/
├── lib/
├── packages/
├── scripts/
└── tests/
```

The project intentionally keeps package definitions, application logic,
development helpers and tests in separate areas.

## Design principles

The architecture follows these principles:

- package definitions are separated from implementation
- package-manager implementations are isolated in backend files
- module processing is independent of individual package managers
- CLI handling is separated from application logic
- installation and updates are separate operations
- diagnostics are separated from installation
- repository handling is separated from package installation
- backend failures are propagated to their callers
- dry-run behaviour is implemented by modifying operations
- package configuration is data-driven
- shared functionality is kept in common libraries
- tests cover both successful operations and failure paths

The goal is a small, modular Bash application where changes to package
definitions normally do not require changes to the application logic.