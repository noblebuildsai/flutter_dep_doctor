#!/usr/bin/env dart

import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_dep_doctor/flutter_dep_doctor.dart';

const _version = '0.1.0';

void main(List<String> arguments) {
  final parser = ArgParser();
  parser.addCommand('scan');
  parser.addCommand('report');
  parser.addCommand('version');
  final cleanCmd = parser.addCommand('clean');
  cleanCmd.addFlag(
      'dry-run',
      abbr: 'n',
      negatable: false,
      help: 'List packages to remove without modifying pubspec.yaml',
    );

  try {
    final results = parser.parse(arguments);
    final command = results.command;
    final rest = command?.rest ?? arguments;

    final projectPath = rest.isNotEmpty ? rest.first : '.';
    final path = _resolvePath(projectPath);

    if (!Directory(path).existsSync()) {
      print('Error: Project path does not exist: $path');
      exit(1);
    }

    if (command == null) {
      _printUsage(parser);
      exit(0);
    }

    switch (command.name) {
      case 'scan':
        _runScan(path);
        break;
      case 'clean':
        _runClean(path, dryRun: command['dry-run'] as bool);
        break;
      case 'report':
        _runReport(path);
        break;
      case 'version':
        _runVersion(path);
        break;
      default:
        _printUsage(parser);
        exit(1);
    }
  } on FormatException catch (e) {
    print('Error: $e');
    _printUsage(parser);
    exit(1);
  }
}

String _resolvePath(String path) {
  if (path == '.') return Directory.current.path;
  final resolved = File(path).absolute.path;
  if (Directory(resolved).existsSync()) return resolved;
  return path;
}

void _printUsage(ArgParser parser) {
  print('''
Flutter Dep Doctor - Manage Flutter/Dart dependencies safely

Usage: flutter_dep_doctor <command> [project_path]

Commands:
  scan    Scan for unused dependencies and dev/prod mismatches
  clean   Remove unused dependencies (use --dry-run to preview)
  report  Generate dependency impact report
  version Show current dependency versions and suggestions

Examples:
  flutter_dep_doctor scan .
  flutter_dep_doctor clean ./my_project --dry-run
  flutter_dep_doctor report

Version: $_version
''');
}

void _runScan(String path) {
  final scanner = DependencyScanner(path);
  final result = scanner.scan();

  print('Scanning: $path\n');
  print('=' * 50);

  if (!result.hasIssues) {
    print('No issues found.');
    return;
  }

  if (result.unusedPackages.isNotEmpty) {
    print('\nUnused packages (not imported anywhere):');
    for (final pkg in result.unusedPackages) {
      print('  - $pkg');
    }
  }

  if (result.devDepsInProd.isNotEmpty) {
    print('\nDev dependencies used in production code (lib/):');
    print('  Consider moving to dependencies:');
    for (final pkg in result.devDepsInProd) {
      print('  - $pkg');
    }
  }

  if (result.prodDepsOnlyInDev.isNotEmpty) {
    print('\nProduction dependencies only used in test/tool:');
    print('  Consider moving to dev_dependencies:');
    for (final pkg in result.prodDepsOnlyInDev) {
      print('  - $pkg');
    }
  }
  print('');
}

void _runClean(String path, {required bool dryRun}) {
  final pubspecPath = '$path/pubspec.yaml';
  if (!File(pubspecPath).existsSync()) {
    print('Error: pubspec.yaml not found at $path');
    exit(1);
  }

  final scanner = DependencyScanner(path);
  final result = scanner.scan();

  if (result.unusedPackages.isEmpty) {
    print('No unused packages to remove.');
    return;
  }

  final pubspec = parsePubspec(pubspecPath);
  final deps = getDependencies(pubspec);
  final devDeps = getDevDependencies(pubspec);

  final toRemoveFromDeps = result.unusedPackages.where(deps.contains).toList();
  final toRemoveFromDevDeps =
      result.unusedPackages.where(devDeps.contains).toList();

  print('Packages to remove:');
  for (final pkg in toRemoveFromDeps) {
    print('  - $pkg (from dependencies)');
  }
  for (final pkg in toRemoveFromDevDeps) {
    print('  - $pkg (from dev_dependencies)');
  }

  if (dryRun) {
    print('\n[DRY RUN] No changes made. Run without --dry-run to apply.');
    return;
  }

  // Backup
  final backupPath = '$path/pubspec.yaml.backup';
  File(pubspecPath).copySync(backupPath);
  print('\nBackup created: pubspec.yaml.backup');

  var modified = false;
  if (toRemoveFromDeps.isNotEmpty) {
    modified |= removePackagesFromPubspec(
      pubspecPath,
      toRemoveFromDeps,
      fromDevDependencies: false,
    );
  }
  if (toRemoveFromDevDeps.isNotEmpty) {
    modified |= removePackagesFromPubspec(
      pubspecPath,
      toRemoveFromDevDeps,
      fromDevDependencies: true,
    );
  }

  if (modified) {
    print('Updated pubspec.yaml. Run `dart pub get` to refresh.');
  }
}

void _runReport(String path) {
  final report = ImpactReport(path);
  final result = report.generate();

  print('Dependency Impact Report: $path\n');
  print('=' * 50);
  print('Summary:');
  print('  Total packages: ${result.packages.length}');
  print('  Unused: ${result.unusedCount}');
  print('  Misclassified: ${result.misclassifiedCount}');
  print('');
  print('Packages:');
  for (final pkg in result.packages) {
    final riskStr = pkg.risk == RiskLevel.high
        ? 'HIGH'
        : pkg.risk == RiskLevel.medium
            ? 'MED'
            : 'LOW';
    final note = pkg.note != null ? ' - ${pkg.note}' : ''; // ignore: unnecessary_brace_in_string_interps
    print('  [${riskStr}] ${pkg.name} ${pkg.version}$note');
  }
  print('');
}

void _runVersion(String path) {
  final resolver = VersionResolver(path);
  final versions = resolver.getCurrentVersions();
  final locked = resolver.getLockedVersions();

  print('Dependency Versions: $path\n');
  print('=' * 50);

  if (versions.isEmpty) {
    print('No dependencies found.');
    return;
  }

  for (final entry in versions.entries) {
    final lockedVer = locked?[entry.key];
    final lockNote =
        lockedVer != null && lockedVer != entry.value ? ' (resolved: $lockedVer)' : '';
    print('  ${entry.key}: ${entry.value}$lockNote');
  }
  print('');
}
