import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

abstract class DawaGameFeedback {
  Future<void> correct();
  Future<void> wrong();
  Future<void> completed();
  Future<void> dispose();
}

class DawaGameFeedbackService implements DawaGameFeedback {
  DawaGameFeedbackService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> correct() async {
    await HapticFeedback.selectionClick();
  }

  @override
  Future<void> wrong() async {
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> completed() async {
    await HapticFeedback.mediumImpact();
    try {
      await _player.stop();
      await _player.play(
        BytesSource(_completionChime),
        volume: .16,
      );
    } catch (_) {
      // Sound support varies by platform and browser policy. Haptics remain
      // available as a quiet, non-blocking completion cue.
    }
  }

  @override
  Future<void> dispose() => _player.dispose();

  static final Uint8List _completionChime = _buildWav();

  static Uint8List _buildWav() {
    const sampleRate = 22050;
    const durationSeconds = .42;
    const channels = 1;
    const bitsPerSample = 16;
    final sampleCount = (sampleRate * durationSeconds).round();
    final dataLength = sampleCount * channels * (bitsPerSample ~/ 8);
    final bytes = ByteData(44 + dataLength);

    void ascii(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        bytes.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    ascii(0, 'RIFF');
    bytes.setUint32(4, 36 + dataLength, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, channels, Endian.little);
    bytes.setUint32(24, sampleRate, Endian.little);
    bytes.setUint32(
      28,
      sampleRate * channels * (bitsPerSample ~/ 8),
      Endian.little,
    );
    bytes.setUint16(32, channels * (bitsPerSample ~/ 8), Endian.little);
    bytes.setUint16(34, bitsPerSample, Endian.little);
    ascii(36, 'data');
    bytes.setUint32(40, dataLength, Endian.little);

    for (var index = 0; index < sampleCount; index++) {
      final time = index / sampleRate;
      final progress = index / sampleCount;
      final fade = math.sin(math.pi * progress);
      final frequency = time < .2 ? 523.25 : 659.25;
      final overtone = math.sin(2 * math.pi * frequency * 2 * time) * .12;
      final signal =
          (math.sin(2 * math.pi * frequency * time) + overtone) * fade;
      final sample = (signal * 32767 * .44).round().clamp(-32768, 32767);
      bytes.setInt16(44 + index * 2, sample, Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

class DawaSilentGameFeedback implements DawaGameFeedback {
  const DawaSilentGameFeedback();

  @override
  Future<void> completed() async {}

  @override
  Future<void> correct() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> wrong() async {}
}
