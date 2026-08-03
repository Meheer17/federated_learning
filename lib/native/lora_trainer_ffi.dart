class LoraTrainerFfi {
  static Stream<double> trainLoraAdapter({
    required String modelPath,
    required String dataPath,
    required String outputAdapterPath,
    int loraRank = 8,
    double loraAlpha = 16.0,
    double learningRate = 0.0001,
    int epochs = 3,
  }) async* {
    // Stream simulated training progress (0.0 to 1.0)
    for (int step = 1; step <= 10; ++step) {
      await Future.delayed(const Duration(milliseconds: 200));
      yield step / 10.0;
    }
  }
}
