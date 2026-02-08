import 'dependency_scanner.dart';
import 'version_resolver.dart';

/// Risk level for a package in upgrade scenarios.
enum RiskLevel { low, medium, high }

/// Per-package impact info for the report.
class PackageImpact {
  final String name;
  final String version;
  final RiskLevel risk;
  final String? note;

  const PackageImpact(this.name, this.version, this.risk, [this.note]);
}

/// Generates a dependency impact report.
class ImpactReport {
  final String projectPath;
  final DependencyScanner _scanner;
  final VersionResolver _resolver;

  ImpactReport(this.projectPath)
      : _scanner = DependencyScanner(projectPath),
        _resolver = VersionResolver(projectPath);

  /// Generates the full report.
  ReportResult   generate() {
    final scanResult = _scanner.scan();
    final versions = _resolver.getCurrentVersions();

    final packageImpacts = <PackageImpact>[];

    for (final pkg in versions.keys) {
      final version = versions[pkg] ?? '?';

      RiskLevel risk = RiskLevel.low;
      String? note;

      if (scanResult.unusedPackages.contains(pkg)) {
        risk = RiskLevel.low;
        note = 'Unused - safe to remove';
      } else if (scanResult.devDepsInProd.contains(pkg)) {
        risk = RiskLevel.medium;
        note = 'Dev dependency used in production - consider moving to dependencies';
      }

      packageImpacts.add(PackageImpact(pkg, version, risk, note));
    }

    return ReportResult(
      packages: packageImpacts,
      unusedCount: scanResult.unusedPackages.length,
      misclassifiedCount:
          scanResult.devDepsInProd.length + scanResult.prodDepsOnlyInDev.length,
    );
  }
}

/// Result of the impact report.
class ReportResult {
  final List<PackageImpact> packages;
  final int unusedCount;
  final int misclassifiedCount;

  const ReportResult({
    required this.packages,
    required this.unusedCount,
    required this.misclassifiedCount,
  });
}
