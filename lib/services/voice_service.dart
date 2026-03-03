import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt show SpeechListenOptions, ListenMode;

/// Voice Intent Type
enum VoiceIntent {
  addIngredients,
  showRecipes,
  unknown,
}

/// Voice Service with Keyword Detection
class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _errorMessage = '';
  double _confidence = 0.0;
  bool _hasPermission = false;
  VoiceIntent _detectedIntent = VoiceIntent.unknown;

  // Stream controllers
  final StreamController<String> _onResultController = StreamController<String>.broadcast();
  final StreamController<String> _onErrorController = StreamController<String>.broadcast();
  final StreamController<VoiceIntent> _onIntentController = StreamController<VoiceIntent>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedWords => _recognizedWords;
  String get errorMessage => _errorMessage;
  double get confidence => _confidence;
  bool get hasPermission => _hasPermission;
  VoiceIntent get detectedIntent => _detectedIntent;

  // Streams
  Stream<String> get onResult => _onResultController.stream;
  Stream<String> get onError => _onErrorController.stream;
  Stream<VoiceIntent> get onIntent => _onIntentController.stream;

  // Keywords for intent detection (English only)
  static const Set<String> _recipeKeywords = {
    // English keywords
    'what should i eat', 'what to eat', 'recommend menu', 'menu', 'recipe',
    'show recipes', 'calculate recipes', 'suggest recipe', 'food suggestion',
    'what can i cook', 'what to cook', 'meal plan', 'meal ideas',
    'find recipes', 'search recipes', 'recipe ideas', 'cook with',
  };

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      bool available = await _speech.initialize(
        onError: (error) {
          _errorMessage = error.errorMsg;
          _onErrorController.add(error.errorMsg);
          notifyListeners();
        },
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
          } else if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          notifyListeners();
        },
      );

      if (available) {
        _isInitialized = true;
        _errorMessage = '';
      } else {
        _errorMessage = 'Speech recognition not available on this device';
      }

      notifyListeners();
      return available;
    } catch (e) {
      _errorMessage = 'Failed to initialize speech: $e';
      _onErrorController.add(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        _hasPermission = true;
        _errorMessage = '';
      } else if (status.isPermanentlyDenied) {
        _hasPermission = false;
        _errorMessage = 'Microphone permission permanently denied. Please enable in app settings.';
        _onErrorController.add(_errorMessage);
      } else {
        _hasPermission = false;
        _errorMessage = 'Microphone permission denied';
        _onErrorController.add(_errorMessage);
      }

      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _errorMessage = 'Failed to request permission: $e';
      _onErrorController.add(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Check microphone permission status
  Future<PermissionStatus> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      _hasPermission = status.isGranted;
      notifyListeners();
      return status;
    } catch (e) {
      _errorMessage = 'Failed to check permission: $e';
      notifyListeners();
      return PermissionStatus.denied;
    }
  }

  /// Detect intent from recognized text
  VoiceIntent _detectIntent(String text) {
    final lowerText = text.toLowerCase();

    for (String keyword in _recipeKeywords) {
      if (lowerText.contains(keyword)) {
        return VoiceIntent.showRecipes;
      }
    }

    return VoiceIntent.addIngredients;
  }

  /// Start listening to speech
  Future<bool> startListening({
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
    Function(String)? onResult,
    Function(VoiceIntent)? onIntent,
  }) async {
    if (!_isInitialized) {
      bool initialized = await initialize();
      if (!initialized) {
        _errorMessage = 'Speech recognition not initialized';
        _onErrorController.add(_errorMessage);
        notifyListeners();
        return false;
      }
    }

    if (!_hasPermission) {
      bool granted = await requestMicrophonePermission();
      if (!granted) {
        _errorMessage = 'Microphone permission not granted';
        _onErrorController.add(_errorMessage);
        notifyListeners();
        return false;
      }
    }

    try {
      _isListening = true;
      _recognizedWords = '';
      _errorMessage = '';
      _detectedIntent = VoiceIntent.unknown;
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          _confidence = result.confidence;

          // Detect intent when we have results
          final intent = _detectIntent(result.recognizedWords);
          if (_detectedIntent != intent) {
            _detectedIntent = intent;
            _onIntentController.add(intent);
          }

          _onResultController.add(result.recognizedWords);

          if (onResult != null && result.finalResult) {
            onResult(result.recognizedWords);
          }

          if (onIntent != null && result.finalResult) {
            onIntent(_detectedIntent);
          }

          notifyListeners();

          if (result.finalResult) {
            _isListening = false;
            notifyListeners();
          }
        },
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: pauseFor ?? const Duration(seconds: 4),
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
          autoPunctuation: true,
          cancelOnError: false,
        ),
      );

      return true;
    } catch (e) {
      _isListening = false;
      _errorMessage = 'Failed to start listening: $e';
      _onErrorController.add(_errorMessage);
      notifyListeners();
      return false;
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    await _speech.cancel();
    _isListening = false;
    _recognizedWords = '';
    _detectedIntent = VoiceIntent.unknown;
    notifyListeners();
  }

  /// Clear recognized words
  void clearRecognizedWords() {
    _recognizedWords = '';
    notifyListeners();
  }

  /// Reset error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Reset intent
  void clearIntent() {
    _detectedIntent = VoiceIntent.unknown;
  }

  /// Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }

  /// Dispose resources
  @override
  void dispose() {
    _onResultController.close();
    _onErrorController.close();
    _onIntentController.close();
    super.dispose();
  }
}

/// Extension to convert locale name to display string
extension LocaleNameExtension on LocaleName {
  String get displayName {
    return '$name ($localeId)';
  }
}
