import '../models/message.dart';
import '../models/user_profile.dart';
import '../native/llama_ffi_bindings.dart';
import 'prompt_builder.dart';

class LlmService {
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
    if (!_isModelLoaded) {
      LlamaFfiBindings.initialize();
      _isModelLoaded = true;
    }

    final prompt = PromptBuilder.buildChatMLPrompt(
      history: history,
      styleProfile: styleProfile,
    );

    yield* LlamaFfiBindings.generateTokenStream(
      prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }
}
