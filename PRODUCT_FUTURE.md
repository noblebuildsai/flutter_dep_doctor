# Flutter Dep Doctor – Product Vision & Future Roadmap

> **Purpose:** This document captures all specs, ideas, plans, and future vision for Flutter Dep Doctor. Use it as the single source of truth when planning or implementing features.

---

## 1. The Core Idea

**Flutter Dep Doctor** helps Flutter and Dart developers manage dependencies safely and efficiently.

**Problem it solves:**
- Bloated `pubspec.yaml` files
- Version conflicts after Flutter/Dart upgrades
- Unknown package impact in large projects
- CI/CD pipeline risk (breaking builds unexpectedly)

**Audience:** Flutter developers, teams, CI/CD pipelines, enterprise projects.

**Why CLI:** Operates on projects, not as a runtime dependency. Can read, modify, and report safely. Fits developer workflows and CI/CD pipelines.

---

## 2. Current MVP (v0.1) – Implemented

- ✅ Scan for unused dependencies
- ✅ Flag dev/prod mismatches
- ✅ Dry-run clean option
- ✅ Simple dependency impact report

**Commands:**
- `scan` – Detect unused packages, dev/prod misclassification
- `clean` – Remove unused dependencies (with `--dry-run`)
- `report` – Generate dependency impact report
- `version` – Show current and resolved versions

---

## 3. Flutter/Dart Version Recommendation (v0.2)

**Idea:** Analyze a project and recommend which Flutter and Dart versions to use.

**What it would do:**
- Read project `environment` and constraints from `pubspec.yaml` / `pubspec.lock`
- Optionally fetch each dependency’s SDK constraints from pub.dev
- Compute the intersection of what all dependencies support
- Output: *"For this project, use Flutter 3.19.x / Dart 3.5.x"*

**Simple MVP approach:**
- Read project `environment` + `pubspec.lock` locally
- Report: *"Project declares Dart ^3.9.2. Current Flutter/Dart: …"*
- Suggest: *"Consider `flutter downgrade` or `flutter upgrade` to match."*

**Full version:**
- pub.dev API to fetch package SDK constraints
- Flutter ↔ Dart version mapping
- Transitive dependency analysis

---

## 4. AI-Powered Upgrade Assistant via MCP (v1.0 / Future)

**Idea:** An MCP server that turns Flutter Dep Doctor into an AI-powered upgrade assistant.

**Flow:**
1. User has an old Flutter project (Flutter, Dart, packages, code).
2. User connects via MCP (e.g. from Cursor).
3. Tool analyzes the project locally.
4. Identifies what needs upgrading and what might break.
5. AI proposes concrete changes (versions + code edits).
6. User sees a preview/diff locally.
7. User chooses: apply automatically or apply manually.

**Key aspects:**
- Runs locally (no cloud, privacy-preserving)
- Preview-before-apply (like `--dry-run` for whole upgrade)
- AI suggests migration fixes when APIs change
- End-to-end: upgrade versions and fix breaking code

**Challenges:**
- Fixing user code when APIs change (hard, needs AI + migration knowledge)
- "Update package code" = can’t change pub.dev packages; can suggest newer versions or handle local packages

**Flow:**
```
flutter_dep_doctor (current)
       ↓
Flutter Upgrade Assistant (MCP server)
       ↓
Uses: scan, report, version, + new "upgrade plan" logic
       ↓
AI (via MCP) interprets results and proposes code changes
       ↓
User reviews diffs and applies or edits manually
```

---

## 5. Implementation Requirements

### 5.1 Technical Components

| Component | Requirement |
|----------|-------------|
| **MCP server** | Model Context Protocol SDK (Node.js/TypeScript or Python) |
| **Tool integration** | Connect to flutter_dep_doctor (CLI or library) |
| **Project analysis** | Read pubspec, pubspec.lock, run `dart analyze`, `flutter pub get` |
| **AI / LLM** | LLM with code context (Cursor, Claude, etc.) |
| **Diff / preview** | Generate diffs and present as MCP resources |

### 5.2 Data Sources

| Source | Purpose |
|--------|---------|
| **pub.dev API** | `https://pub.dev/api/packages/<name>` – metadata, versions, SDK constraints |
| **Flutter/Dart version mapping** | Maintained list or scraping |
| **Local project** | pubspec.yaml, pubspec.lock, Dart files |
| **Changelogs** | Breaking changes, migration guides |

### 5.3 MCP Tools to Expose

| Tool | Purpose |
|------|---------|
| `analyze_project` | Run flutter_dep_doctor scan/report/version, return JSON |
| `get_upgrade_plan` | Compute recommended Flutter/Dart + package versions |
| `check_compatibility` | Call pub.dev, list incompatible packages |
| `generate_migration_diff` | Produce file diffs for proposed changes |
| `preview_changes` | Return structured summary of proposed changes |
| `apply_changes` | Apply changes (with user confirmation) |

### 5.4 Stack Options

| Option | Pros | Cons |
|--------|------|------|
| **MCP in Node.js** | Good MCP docs | Shell out to Dart |
| **MCP in Python** | Simple scripting | Less common for MCP |
| **Dart MCP server** | Same language | MCP Dart support limited |
| **Bridge** | Keep Dart logic in flutter_dep_doctor, MCP orchestrates | Best fit |

---

## 6. Original Project Spec (Reference)

### Structure
```
flutter_dep_doctor/
├── bin/flutter_dep_doctor.dart
├── lib/
│   ├── core/
│   │   ├── dependency_scanner.dart
│   │   ├── version_resolver.dart
│   │   └── impact_report.dart
│   └── utils/
│       ├── file_utils.dart
│       └── yaml_utils.dart
├── test/
├── pubspec.yaml
└── README.md
```

### CLI Commands
- `flutter_dep_doctor scan <project_path>`
- `flutter_dep_doctor clean <project_path> [--dry-run]`
- `flutter_dep_doctor report <project_path>`
- `flutter_dep_doctor version <project_path>`

### Core Features (Spec)
- **Dependency Scanner:** Unused packages, dev/prod misclassification, codegen-only usage
- **Version Resolver:** pubspec.lock, version conflicts, minimal/max compatible versions
- **Impact Report:** Risk score per package, Flutter SDK compatibility, upgrade order
- **Safe Clean:** Remove unused deps, dry-run, backup pubspec.yaml

### Optional v0.2+ (Spec)
- Version conflict solver (smart suggestions)
- Full CI/CD integration (GitHub Action)
- Package abandonment warning
- GUI plugin for IDE (VS Code / IntelliJ)
- Integration with Flutter upgrade simulation

---

## 7. Rough Timeline (MCP MVP)

| Phase | Effort |
|-------|--------|
| MCP server + `analyze_project` calling flutter_dep_doctor | 1–2 days |
| Upgrade logic + pub.dev fetch | 2–3 days |
| Preview/diff generation | 1–2 days |
| Apply changes tool | 1 day |
| Testing and polish | 2–3 days |

**Total:** ~1–2 weeks for MCP MVP.

---

## 8. Roadmap Summary

| Version | Focus |
|---------|-------|
| **v0.1** | Scan, clean, report, version (MVP) ✅ |
| **v0.2** | Flutter/Dart version recommendation |
| **v0.3** | Version conflict solver, pub.dev integration |
| **v1.0** | MCP server, AI upgrade assistant |

---

*Last updated: February 2025*
