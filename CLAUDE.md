# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository is a reusable CLAUDE instructions template and utility tooling for Perl module development. The primary artifact is `CLAUDE-briandfoy-perl.md`, which other Perl module repos import via:

	@CLAUDE-briandfoy-perl.md

## Repository Contents

- **`CLAUDE-briandfoy-perl.md`** — The reusable instruction template for brian d foy's Perl modules. Edit this when updating the shared Perl coding standards.
- **`util/find-distros-using-claude.pl`** — Queries MetaCPAN's Elasticsearch API to list all CPAN distributions that include a CLAUDE.md file. Depends on core modules only (HTTP::Tiny, JSON::PP, List::Util).
- **`util/claude-commit`** — Bash script to commit with Claude Code as git author and the human as co-author. Env vars `CLAUDE_AUTHOR` and `CLAUDE_EMAIL` override the defaults ("Claude Code, Opus 4.7").

## Running the Utilities

```bash
# Discover CPAN distributions using CLAUDE.md
perl util/find-distros-using-claude.pl

# Commit with Claude as author (all staged changes)
./util/claude-commit "commit message"

# Commit specific files
./util/claude-commit "commit message" lib/Foo.pm t/foo.t
```

## No Build or Test Step

This repo has no Makefile, no CPAN distribution, and no test suite. There is nothing to build or install.
