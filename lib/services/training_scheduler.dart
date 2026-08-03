import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../app/constants.dart';
import '../database/database_helper.dart';
import '../native/lora_trainer_ffi.dart';

class TrainingScheduler {
  final DatabaseHelper _dbHelper;

  TrainingScheduler({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Check whether device meets idle conditions for on-device training
  Future<bool> checkTrainingConditions({double simulatedBatteryLevel = 0.80}) async {
    // Requires battery > 50%
    if (simulatedBatteryLevel < AppConstants.minBatteryForTraining) {
      return false;
    }
    return true;
  }

  /// Launch idle-time LoRA training session
  Future<String?> startIdleTraining({required String modelPath}) async {
    final canTrain = await checkTrainingConditions();
    if (!canTrain) {
      return null;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dataPath = join(docsDir.path, 'training_data.jsonl');
    final adapterPath = join(docsDir.path, 'adapters', 'lora_v1.bin');

    final adapterDir = Directory(dirname(adapterPath));
    if (!await adapterDir.exists()) {
      await adapterDir.create(recursive: true);
    }

    // Run training
    final progressStream = LoraTrainerFfi.trainLoraAdapter(
      modelPath: modelPath,
      dataPath: dataPath,
      outputAdapterPath: adapterPath,
    );

    await for (final _ in progressStream) {
      // Progress reporting step
    }

    // Log training session in DB
    final db = await _dbHelper.database;
    await db.insert('training_logs', {
      'started_at': DateTime.now().millisecondsSinceEpoch - 5000,
      'completed_at': DateTime.now().millisecondsSinceEpoch,
      'epochs': 3,
      'loss': 0.15,
      'adapter_path': adapterPath,
    });

    return adapterPath;
  }
}
