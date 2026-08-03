import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../app/constants.dart';
import '../models/model_info.dart';

class ModelManager {
  final Dio _dio = Dio();

  Future<String> get _modelsDir async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(join(docsDir.path, 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<ModelInfo> getModelInfo() async {
    final dir = await _modelsDir;
    final filePath = join(dir, AppConstants.defaultModelName);
    final file = File(filePath);

    if (await file.exists()) {
      final size = await file.length();
      return ModelInfo(
        id: 'smollm2_1.7b',
        name: AppConstants.defaultModelName,
        downloadUrl: AppConstants.defaultModelUrl,
        localPath: filePath,
        sizeBytes: size,
        status: ModelStatus.ready,
        downloadProgress: 1.0,
      );
    }

    return ModelInfo(
      id: 'smollm2_1.7b',
      name: AppConstants.defaultModelName,
      downloadUrl: AppConstants.defaultModelUrl,
      localPath: filePath,
      sizeBytes: 1000000000, // ~1 GB
      status: ModelStatus.notDownloaded,
      downloadProgress: 0.0,
    );
  }

  Future<void> downloadModel({
    required Function(double progress) onProgress,
    required Function() onCompleted,
    required Function(String error) onError,
  }) async {
    try {
      final dir = await _modelsDir;
      final savePath = join(dir, AppConstants.defaultModelName);

      // Download GGUF binary from HuggingFace with progress callback
      await _dio.download(
        AppConstants.defaultModelUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      onCompleted();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> deleteModel() async {
    final dir = await _modelsDir;
    final file = File(join(dir, AppConstants.defaultModelName));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
