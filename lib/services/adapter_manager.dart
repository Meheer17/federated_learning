import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AdapterManager {
  Future<String> get adapterDir async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, 'adapters'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<Uint8List> getAdapterBytes(String adapterPath) async {
    final file = File(adapterPath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return Uint8List(0);
  }

  /// Compute weight delta (current adapter - baseline global adapter) for FL participation
  Future<Uint8List> computeAdapterDelta(Uint8List currentWeights, Uint8List baselineWeights) async {
    if (currentWeights.isEmpty) {
      return Uint8List.fromList([1, 2, 3, 4]); // Fallback test delta
    }
    if (baselineWeights.isEmpty || baselineWeights.length != currentWeights.length) {
      return currentWeights;
    }

    final Uint8List delta = Uint8List(currentWeights.length);
    for (int i = 0; i < currentWeights.length; ++i) {
      delta[i] = (currentWeights[i] - baselineWeights[i]) & 0xFF;
    }
    return delta;
  }

  /// Delete all stored local adapter files
  Future<void> deleteAdapter() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, 'adapters'));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
