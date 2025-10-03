# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`klone` is a shell utility that clones repositories into deterministic directory paths based on their URL. It transforms URLs like `https://github.com/kfkonrad/klone` into workspace paths like `~/workspace/github/kfkonrad/klone`.

The tool has **four separate implementations** with identical functionality:
- **Fish** (`functions/klone.fish`) - oh-my-fish/fisher compatible
- **Bash** (`bash/klone.sh`)
- **ZSH** (`zsh/klone.sh`)
- **Nushell** (`nushell/klone.nu`)

## Architecture

### Core Path Transformation Algorithm

All implementations follow the same logic flow:

1. **URL Parsing**: Detect URL scheme (SSH `git@...` vs HTTPS `https://...`)
2. **Domain Extraction**: Extract FQDN and apply domain aliases if configured
3. **Path Extraction**: Extract repository path and apply path replacements if configured
4. **Final Path Construction**: Combine base directory + domain + path

### Key Differences Between Implementations

- **Bash/ZSH/Fish**: Custom TOML parser using regex (no multi-line array support)
- **Nushell**: Uses built-in TOML parser (supports multi-line arrays)

### Configuration System

Config file: `~/.config/klone/config.toml` (override via `$KLONE_CONFIG`)

Three TOML sections:
- `[general]`: `base_dir`, `cd_after_clone`, `clone_command`
- `[domain_alias]`: Map domains to custom strings (e.g., `github.com = "foo/bar"`)
- `[path_replace]`: Regex-based path transformations per domain (e.g., `gitlab.com = ["rluna", "baz"]`)

## Development Commands

### Testing

Run the automated test suite:

```bash
cd tests
./test.sh
```

The test suite uses Docker containers for each shell (Bash 5.3.3, ZSH 5.9, Fish 4.0.2, Nushell 0.106.1) and pytest to validate:
- URL parsing (HTTPS, SSH, git://)
- Domain extraction and aliasing
- Path replacement
- Dry-run mode (--dry-run/-n flag before/after URL)
- TOML config parsing across all shells

Tests run in GitHub Actions on push/PR to main branch.

### Key Implementation Requirements

When modifying any implementation:

1. **Maintain feature parity** - All 4 implementations must have identical behavior
2. **URL scheme support** - Handle `git@...`, `ssh://git@...`, and `https://...`
3. **Clone tool flexibility** - Clone command runs from parent directory of target path
4. **Helper naming** - All helper functions prefixed with `__klone_helper_` or `klone_helper_`
5. **Variable cleanup** - Shell implementations must clean up TOML vars (prefix `klone_toml_`)
6. **Dry-run flag position** - Support `--dry-run`/`-n` before or after URL

### TOML Parsing Constraints

- **Bash/ZSH/Fish**: Single-line arrays only (`["val1", "val2"]`)
- **Nushell**: Full TOML spec supported via built-in parser
- All parsers convert dots/colons/hyphens in keys to underscores for variable names

## Version Control

- Primary branch: `main`
- Uses both Git and Jujutsu (`.jj/` directory present)
