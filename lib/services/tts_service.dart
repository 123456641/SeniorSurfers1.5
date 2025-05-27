import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    // Set default settings
    await _flutterTts!.setLanguage("en-US");
    await _flutterTts!.setSpeechRate(0.5);
    await _flutterTts!.setVolume(1.0);
    await _flutterTts!.setPitch(1.0);

    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _flutterTts!.speak(text);
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    await _flutterTts!.stop();
  }

  Future<void> pause() async {
    if (!_isInitialized) return;
    await _flutterTts!.pause();
  }

  Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();
    await _flutterTts!.setSpeechRate(rate);
  }

  Future<void> setVolume(double volume) async {
    if (!_isInitialized) await initialize();
    await _flutterTts!.setVolume(volume);
  }
}
