import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks German text with the phone's built-in voice.
abstract interface class Speaker {
  Future<void> speak(String text, {bool slow = false});
}

class DeviceSpeaker implements Speaker {
  FlutterTts? _tts;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    await tts.setLanguage('de-DE');
    return _tts = tts;
  }

  @override
  Future<void> speak(String text, {bool slow = false}) async {
    try {
      final tts = await _engine();
      await tts.stop();
      await tts.setSpeechRate(slow ? 0.3 : 0.45);
      await tts.speak(text.replaceAll('___', '…'));
    } on Object {
      // No German voice installed: the text stays readable on screen.
    }
  }
}

final speakerProvider = Provider<Speaker>((ref) => DeviceSpeaker());
