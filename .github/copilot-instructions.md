# Project Guidelines

## Code Search Engine

Use **Auggie (Augment Code Search)** as the primary code search engine for this project.

- Tool: `mcp_auggie_augment_code_search`
- Repo: `DST-Arknights/DST-Arknights-KaltsitEsperanta`
- When exploring code, searching for implementations, or understanding how features work, **always try Auggie first** before falling back to local grep/file search.

## Project Context

This is a Don't Starve Together (DST) character mod for "Kaltsit Esperanta" (凯尔希), written in Lua. Key entry points:
- `modmain.lua` — Main mod entry, character registration, tuning values
- `modmain/` — Modular gameplay scripts (tech, intellect, weapons, animal affinity)
- `scripts/prefabs/` — Prefab definitions for items and entities
- `animSource/` — Spriter animation source files (.scml)

## Build and Test

This is a DST mod; no build step required. Testing is done by loading the mod in Don't Starve Together.
