import '../models/message.dart';
import '../models/model_info.dart';
import '../models/user_profile.dart';
import '../native/llama_ffi_bindings.dart';
import 'model_manager.dart';
import 'prompt_builder.dart';

class LlmService {
  final ModelManager _modelManager = ModelManager();
  bool _isModelLoaded = false;
  bool get isModelLoaded => _isModelLoaded;

  Future<void> loadModel(String modelPath) async {
    LlamaFfiBindings.initialize();
    _isModelLoaded = true;
  }

  Future<void> unloadModel() async {
    _isModelLoaded = false;
  }

  Stream<String> generateResponse({
    required List<ChatMessage> history,
    StyleProfile? styleProfile,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async* {
    LlamaFfiBindings.initialize();

    final modelInfo = await _modelManager.getModelInfo();
    final bool isDownloaded = modelInfo.status == ModelStatus.ready;

    final prompt = PromptBuilder.buildChatMLPrompt(
      history: history,
      styleProfile: styleProfile,
    );

    yield* LlamaFfiBindings.generateTokenStream(
      prompt,
      modelPath: isDownloaded ? modelInfo.localPath : null,
      isModelDownloaded: isDownloaded,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}

