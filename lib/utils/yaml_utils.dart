import 'dart:io';

import 'package:yaml/yaml.dart';

/// Parses pubspec.lock and returns resolved package versions.
Map<String, String>? parseLockFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final content = file.readAsStringSync();
    final doc = loadYaml(content) as Map?;
    if (doc == null) return null;

    final packages = doc['packages'];
    if (packages == null || packages is! Map) return null;

    final result = <String, String>{};
    for (final entry in packages.entries) {
      final pkg = entry.value;
      if (pkg is Map && pkg['version'] != null) {
        result[entry.key as String] = pkg['version'] as String;
      }
    }
    return result;
  } catch (_) {
    return null;
  }
}

/// Parses pubspec.yaml and returns a map of its contents.
Map<String, dynamic>? parsePubspec(String path) {
  final file = File(path);
  if (!file.existsSync()) return null;

  try {
    final content = file.readAsStringSync();
    final doc = loadYaml(content);
    return Map<String, dynamic>.from(doc as Map);
  } catch (_) {
    return null;
  }
}

/// Extracts package names from dependencies section.
List<String> getDependencies(Map<String, dynamic>? pubspec) {
  if (pubspec == null) return [];
  final deps = pubspec['dependencies'];
  if (deps == null || deps is! Map) return [];
  return deps.keys.cast<String>().toList();
}

/// Extracts package names from dev_dependencies section.
List<String> getDevDependencies(Map<String, dynamic>? pubspec) {
  if (pubspec == null) return [];
  final deps = pubspec['dev_dependencies'];
  if (deps == null || deps is! Map) return [];
  return deps.keys.cast<String>().toList();
}

/// Extracts dependency with version info (string or map/path).
Map<String, String> getDependencyVersions(Map<String, dynamic>? pubspec) {
  if (pubspec == null) return {};
  final deps = pubspec['dependencies'];
  if (deps == null || deps is! Map) return {};

  final result = <String, String>{};
  for (final entry in deps.entries) {
    final value = entry.value;
    if (value is String) {
      result[entry.key as String] = value;
    } else if (value is Map && value.containsKey('path')) {
      result[entry.key as String] = 'path: ${value['path']}';
    } else if (value is Map && value.containsKey('git')) {
      result[entry.key as String] = 'git';
    } else {
      result[entry.key as String] = value.toString();
    }
  }
  return result;
}

/// Removes packages from dependencies or dev_dependencies and writes updated pubspec.
/// Returns true if file was modified.
bool removePackagesFromPubspec(
  String path,
  List<String> packagesToRemove, {
  bool fromDevDependencies = false,
}) {
  final file = File(path);
  if (!file.existsSync()) return false;

  final content = file.readAsStringSync();
  final section = fromDevDependencies ? 'dev_dependencies' : 'dependencies';

  var modified = false;
  final lines = content.split('\n');
  final result = <String>[];
  var inSection = false;
  var sectionIndent = 0;
  var skipUntilNextPackage = false;
  var currentBlockIndent = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final trimmed = line.trimLeft();
    final indent = line.length - trimmed.length;

    if (trimmed.startsWith('$section:')) {
      inSection = true;
      sectionIndent = indent;
      skipUntilNextPackage = false;
      result.add(line);
      continue;
    }

    if (inSection) {
      if (trimmed.isEmpty) {
        skipUntilNextPackage = false;
        result.add(line);
        continue;
      }
      if (indent <= sectionIndent && trimmed.isNotEmpty) {
        inSection = false;
        skipUntilNextPackage = false;
        result.add(line);
        continue;
      }
      if (skipUntilNextPackage) {
        if (indent > currentBlockIndent) continue;
        skipUntilNextPackage = false;
      }
      final pkgName = trimmed.split(':').first.trim();
      if (packagesToRemove.contains(pkgName)) {
        modified = true;
        currentBlockIndent = indent;
        skipUntilNextPackage = true;
        continue;
      }
    }
    result.add(line);
  }

  if (modified) {
    file.writeAsStringSync(result.join('\n'));
  }
  return modified;
}

/// Extracts dev_dependency versions.
Map<String, String> getDevDependencyVersions(Map<String, dynamic>? pubspec) {
  if (pubspec == null) return {};
  final deps = pubspec['dev_dependencies'];
  if (deps == null || deps is! Map) return {};

  final result = <String, String>{};
  for (final entry in deps.entries) {
    final value = entry.value;
    if (value is String) {
      result[entry.key as String] = value;
    } else if (value is Map && value.containsKey('path')) {
      result[entry.key as String] = 'path: ${value['path']}';
    } else {
      result[entry.key as String] = value.toString();
    }
  }
  return result;
}
