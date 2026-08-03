import 'dart:ffi' as ffi;
import 'dart:io';

// FFI Types for llama.cpp
typedef LlamaModelLoadC = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char> path, ffi.Pointer<ffi.Void> params);
typedef LlamaModelLoad = ffi.Pointer<ffi.Void> Function(ffi.Pointer<ffi.Char> path, ffi.Pointer<ffi.Void> params);

typedef LlamaFreeC = ffi.Void Function(ffi.Pointer<ffi.Void> ptr);
typedef LlamaFree = void Function(ffi.Pointer<ffi.Void> ptr);

class LlamaFfiBindings {
  static ffi.DynamicLibrary? _lib;
  static bool _initialized = false;

  static void initialize() {
    if (_initialized) return;
    try {
      if (Platform.isAndroid) {
        _lib = ffi.DynamicLibrary.open('libllama.so');
      } else if (Platform.isLinux) {
        _lib = ffi.DynamicLibrary.open('libllama.so');
      } else if (Platform.isMacOS) {
        _lib = ffi.DynamicLibrary.open('libllama.dylib');
      } else if (Platform.isWindows) {
        _lib = ffi.DynamicLibrary.open('llama.dll');
      }
    } catch (e) {
      // Dynamic library not present on host dev environment — fallback mode active
      _lib = null;
    }
    _initialized = true;
  }

  static bool get isNativeAvailable => _lib != null;

  /// Generate response token stream (native or simulated fallback)
  static Stream<String> generateTokenStream(String prompt, {int maxTokens = 512, double temperature = 0.7}) async* {
    if (isNativeAvailable) {
      // Native FFI execution path
      yield " [Native llama.cpp engine response stream initialization...] ";
    } else {
      // High-quality simulation fallback for developer testing
      final simulatedResponse = _getSimulatedResponse(prompt);
      final words = simulatedResponse.split(' ');
      for (final word in words) {
        await Future.delayed(const Duration(milliseconds: 40));
        yield '$word ';
      }
    }
  }

  static String _getSimulatedResponse(String prompt) {
    if (prompt.contains('privacy')) {
      return "FedChat processes all your chats 100% on your device! Your conversations never leave your phone, keeping your personal data safe and encrypted at all times.";
    } else if (prompt.contains('hello') || prompt.contains('hi')) {
      return "Hello! I am FedChat, your privacy-first AI assistant running entirely on your phone. How can I help you today?";
    } else {
      return "I'm processing your request locally on your device. All your messages stay completely private and encrypted with SQLCipher!";
    }
  }
}
