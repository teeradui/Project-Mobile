import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt show SpeechListenOptions, ListenMode;

/// Voice Service
/// A reusable class to handle microphone permissions and Speech-to-Text logic
class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _errorMessage = '';
  double _confidence = 0.0;
  bool _hasPermission = false;

  // Stream controllers for real-time updates
  final StreamController<String> _onResultController = StreamController<String>.broadcast();
  final StreamController<String> _onErrorController = StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get recognizedWords => _recognizedWords;
  String get errorMessage => _errorMessage;
  double get confidence => _confidence;
  bool get hasPermission => _hasPermission;

  // Streams
  Stream<String> get onResult => _onResultController.stream;
  Stream<String> get onError => _onErrorController.stream;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      // Check if speech recognition is available
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

  /// Open app settings for permission
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Start listening to speech
  Future<bool> startListening({
    String? localeId,
    Duration? listenFor,
    Duration? pauseFor,
    Function(String)? onResult,
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
      notifyListeners();

      await _speech.listen(
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          _confidence = result.confidence;

          // Emit to stream
          _onResultController.add(result.recognizedWords);

          // Emit both partial and final text so UI can update while speaking.
          if (onResult != null && result.recognizedWords.trim().isNotEmpty) {
            onResult(result.recognizedWords);
          }

          notifyListeners();

          // Auto-stop on final result
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

  /// Get available locales
  Future<List<LocaleName>> getAvailableLocales() async {
    return await _speech.locales();
  }

  /// Dispose resources
  @override
  void dispose() {
    _onResultController.close();
    _onErrorController.close();
    super.dispose();
  }
}

/// Extension to convert locale name to display string
extension LocaleNameExtension on LocaleName {
  String get displayName {
    return '$name ($localeId)';
  }
}
