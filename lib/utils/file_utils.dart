import 'dart:io';

/// Recursively finds all Dart files in [dirs] under [root].
List<String> findDartFiles(String root, List<String> dirs) {
  final result = <String>[];

  for (final dir in dirs) {
    final path = dir == '/' ? root : '$root/$dir';
    final dirFile = Directory(path);
    if (!dirFile.existsSync()) continue;

    for (final entity in dirFile.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        result.add(entity.path);
      }
    }
  }
  return result;
}

/// Extracts package names from import statements in Dart source.
/// Handles: import 'package:foo/bar.dart'; and import "package:foo/bar.dart";
final RegExp _importRegex = RegExp(
  r'''import\s+["'](package:([^/]+)/[^"']+)["']''',
);

Set<String> extractPackageImports(String content) {
  final packages = <String>{};
  for (final match in _importRegex.allMatches(content)) {
    packages.add(match.group(2)!);
  }
  return packages;
}

/// Reads file content, returns empty string on failure.
String readFileSafe(String path) {
  try {
    return File(path).readAsStringSync();
  } catch (_) {
    return '';
  }
}
