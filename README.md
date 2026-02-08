# Flutter Dep Doctor

A CLI tool to help Flutter and Dart developers manage dependencies safely and efficiently.

## Features

- **Scan** – Detect unused packages and dev/prod misclassification
- **Clean** – Remove unused dependencies (with optional dry-run)
- **Report** – Generate dependency impact reports
- **Version** – View current and resolved dependency versions

## Installation

**From pub.dev** (when published):

```bash
dart pub global activate flutter_dep_doctor
```

**From local source** (during development):

```bash
cd /path/to/flutter_dep_doctor
dart pub global activate --source path .
```

**Or run directly without installing:**

```bash
dart run /path/to/flutter_dep_doctor/bin/flutter_dep_doctor.dart <command> [project_path]
```

## Where to Run

Run all commands **from inside your Flutter project directory** (the folder that contains `pubspec.yaml`):

```bash
cd /path/to/your/flutter_project
flutter_dep_doctor scan .
```

Using `.` means the current directory. You can also pass a path: `flutter_dep_doctor scan ./my_app`

## Usage

### Scan for issues

```bash
flutter_dep_doctor scan .
flutter_dep_doctor scan ./my_project
```

Scans for:
- Unused packages (not imported anywhere)
- Dev dependencies used in production code (`lib/`)
- Production dependencies only used in test/tool (could be `dev_dependencies`)

### Clean unused packages

```bash
# Preview what would be removed
flutter_dep_doctor clean . --dry-run

# Remove unused packages (creates pubspec.yaml.backup first)
flutter_dep_doctor clean .
```

### Generate impact report

```bash
flutter_dep_doctor report .
```

### View dependency versions

```bash
flutter_dep_doctor version .
```

## Project structure

```
flutter_dep_doctor/
├── bin/flutter_dep_doctor.dart   # CLI entry point
├── lib/
│   ├── core/
│   │   ├── dependency_scanner.dart
│   │   ├── version_resolver.dart
│   │   └── impact_report.dart
│   └── utils/
│       ├── file_utils.dart
│       └── yaml_utils.dart
├── test/
└── pubspec.yaml
```

## MVP (v0.1)

- ✅ Scan for unused dependencies
- ✅ Flag dev/prod mismatches
- ✅ Dry-run clean option
- ✅ Simple dependency impact report

## License

BSD-3-Clause
