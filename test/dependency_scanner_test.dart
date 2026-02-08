import 'dart:io';

import 'package:flutter_dep_doctor/flutter_dep_doctor.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyScanner', () {
    late String testProjectPath;

    setUp(() {
      testProjectPath = Directory.systemTemp.createTempSync('fdd_test').path;
    });

    tearDown(() {
      Directory(testProjectPath).deleteSync(recursive: true);
    });

    test('returns empty result when pubspec.yaml does not exist', () {
      final scanner = DependencyScanner(testProjectPath);
      final result = scanner.scan();
      expect(result.hasIssues, isFalse);
      expect(result.unusedPackages, isEmpty);
    });

    test('detects unused packages', () {
      _createPubspec(testProjectPath, dependencies: {
        'used_pkg': '^1.0.0',
        'unused_pkg': '^1.0.0',
      });
      _createDartFile('$testProjectPath/lib/main.dart', '''
import 'package:used_pkg/used_pkg.dart';

void main() {}
''');

      final scanner = DependencyScanner(testProjectPath);
      final result = scanner.scan();

      expect(result.unusedPackages, contains('unused_pkg'));
      expect(result.unusedPackages, isNot(contains('used_pkg')));
    });

    test('excludes lints from unused (config-only package)', () {
      _createPubspec(testProjectPath, devDependencies: {'lints': '^6.0.0'});
      final scanner = DependencyScanner(testProjectPath);
      final result = scanner.scan();
      expect(result.unusedPackages, isNot(contains('lints')));
    });

    test('flags dev dependency used in lib/', () {
      _createPubspec(testProjectPath,
          dependencies: {},
          devDependencies: {'mock_pkg': '^1.0.0'});
      _createDartFile('$testProjectPath/lib/main.dart', '''
import 'package:mock_pkg/mock_pkg.dart';
void main() {}
''');

      final scanner = DependencyScanner(testProjectPath);
      final result = scanner.scan();

      expect(result.devDepsInProd, contains('mock_pkg'));
    });
  });

  group('extractPackageImports', () {
    test('extracts package names from single and double quotes', () {
      final content = '''
import 'package:foo/foo.dart';
import "package:bar/bar.dart";
''';
      expect(extractPackageImports(content), {'foo', 'bar'});
    });

    test('returns empty for non-package imports', () {
      expect(extractPackageImports("import 'dart:io';"), isEmpty);
      expect(extractPackageImports("import '../local.dart';"), isEmpty);
    });
  });
}

void _createPubspec(String path,
    {Map<String, String> dependencies = const {},
    Map<String, String> devDependencies = const {}}) {
  final buffer = StringBuffer('''
name: test_project
environment:
  sdk: ^3.0.0

dependencies:
''');
  for (final entry in dependencies.entries) {
    buffer.writeln('  ${entry.key}: ${entry.value}');
  }
  buffer.writeln('dev_dependencies:');
  for (final entry in devDependencies.entries) {
    buffer.writeln('  ${entry.key}: ${entry.value}');
  }
  File('$path/pubspec.yaml').writeAsStringSync(buffer.toString());
}

void _createDartFile(String path, String content) {
  File(path).createSync(recursive: true);
  File(path).writeAsStringSync(content);
}
