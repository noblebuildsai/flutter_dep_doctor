import 'package:flutter_dep_doctor/flutter_dep_doctor.dart';
import 'package:test/test.dart';

void main() {
  test('library exports work', () {
    final scanner = DependencyScanner('.');
    final result = scanner.scan();
    expect(result, isA<ScanResult>());
  });
}
