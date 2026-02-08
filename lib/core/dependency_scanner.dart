import '../utils/file_utils.dart';
import '../utils/yaml_utils.dart';

/// Result of scanning a project for dependency issues.
class ScanResult {
  /// Packages in pubspec but never imported in code.
  final List<String> unusedPackages;

  /// Dev dependencies used in production code (lib/).
  final List<String> devDepsInProd;

  /// Production dependencies used only in test/tool (could be dev_dependencies).
  final List<String> prodDepsOnlyInDev;

  const ScanResult({
    this.unusedPackages = const [],
    this.devDepsInProd = const [],
    this.prodDepsOnlyInDev = const [],
  });

  bool get hasIssues =>
      unusedPackages.isNotEmpty ||
      devDepsInProd.isNotEmpty ||
      prodDepsOnlyInDev.isNotEmpty;
}

/// Scans a Flutter/Dart project for unused and misclassified dependencies.
class DependencyScanner {
  final String projectPath;

  DependencyScanner(this.projectPath);

  /// Runs a full scan and returns results.
  ScanResult scan() {
    final pubspecPath = '$projectPath/pubspec.yaml';
    final pubspec = parsePubspec(pubspecPath);
    if (pubspec == null) {
      return const ScanResult();
    }

    final deps = getDependencies(pubspec);
    final devDeps = getDevDependencies(pubspec);

    // Collect imports by context: lib = prod, test/tool = dev
    final importsInProd = <String>{};
    final importsInDev = <String>{};

    final prodFiles = findDartFiles(projectPath, ['lib', 'bin']);
    final devFiles = findDartFiles(projectPath, ['test', 'tool', 'benchmark']);

    for (final path in prodFiles) {
      importsInProd.addAll(extractPackageImports(readFileSafe(path)));
    }
    for (final path in devFiles) {
      importsInDev.addAll(extractPackageImports(readFileSafe(path)));
    }

    final allImports = {...importsInProd, ...importsInDev};

    // Packages used outside code (analysis_options, build_runner, etc.)
    const configOnlyPackages = {'lints', 'flutter_lints'};

    // Unused: in pubspec but never imported
    final unusedPackages = <String>[];
    for (final pkg in deps) {
      if (!allImports.contains(pkg) && !configOnlyPackages.contains(pkg)) {
        unusedPackages.add(pkg);
      }
    }
    for (final pkg in devDeps) {
      if (!allImports.contains(pkg) && !configOnlyPackages.contains(pkg)) {
        unusedPackages.add(pkg);
      }
    }

    // Dev deps used in production code
    final devDepsInProd = devDeps.where(importsInProd.contains).toList();

    // Prod deps used only in dev code (never in lib)
    final prodDepsOnlyInDev = deps
        .where((p) => importsInDev.contains(p) && !importsInProd.contains(p))
        .toList();

    return ScanResult(
      unusedPackages: unusedPackages,
      devDepsInProd: devDepsInProd,
      prodDepsOnlyInDev: prodDepsOnlyInDev,
    );
  }
}
