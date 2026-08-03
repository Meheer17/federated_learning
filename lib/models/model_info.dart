enum ModelStatus { notDownloaded, downloading, ready, error }

class ModelInfo {
  final String id;
  final String name;
  final String downloadUrl;
  final String localPath;
  final int sizeBytes;
  final String? sha256;
  final ModelStatus status;
  final double downloadProgress;

  ModelInfo({
    required this.id,
    required this.name,
    required this.downloadUrl,
    required this.localPath,
    required this.sizeBytes,
    this.sha256,
    this.status = ModelStatus.notDownloaded,
    this.downloadProgress = 0.0,
  });

  ModelInfo copyWith({
    ModelStatus? status,
    double? downloadProgress,
    String? localPath,
  }) {
    return ModelInfo(
      id: id,
      name: name,
      downloadUrl: downloadUrl,
      localPath: localPath ?? this.localPath,
      sizeBytes: sizeBytes,
      sha256: sha256,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}
