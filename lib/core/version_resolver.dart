import '../utils/yaml_utils.dart';

/// Suggests compatible versions for resolving conflicts.
/// MVP: returns basic info; v0.2 can add smart conflict resolution.
class VersionResolver {
  final String projectPath;

  VersionResolver(this.projectPath);

  /// Returns current dependency versions from pubspec.
  Map<String, String> getCurrentVersions() {
    final pubspec = parsePubspec('$projectPath/pubspec.yaml');
    if (pubspec == null) return {};

    final versions = <String, String>{};
    versions.addAll(getDependencyVersions(pubspec));
    versions.addAll(getDevDependencyVersions(pubspec));
    return versions;
  }

  /// Returns resolved versions from pubspec.lock if present.
  Map<String, String>? getLockedVersions() {
    return parseLockFile('$projectPath/pubspec.lock');
  }
}
