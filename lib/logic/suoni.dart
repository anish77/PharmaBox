import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:pharma_box/logic/preferenze_dispositivo.dart';

/// Suoni alla lettura dello scanner, se attivati nelle Opzioni.
/// Rispettano il silenzioso e non interrompono la musica di altre app.
abstract final class Suoni {
  static AudioPlayer? _lettura;
  static AudioPlayer? _avviso;
  static bool _configurato = false;

  static bool get _attivo => PreferenzeDispositivo.suonoLettura.value;

  /// Lettura andata a buon fine
  static void lettura() => _suona(_lettura ??= AudioPlayer(), 'lettura.wav');

  /// Confezione scaduta, in scadenza, già contata o prodotto non trovato
  static void avviso() => _suona(_avviso ??= AudioPlayer(), 'avviso.wav');

  static Future<void> _suona(AudioPlayer player, String file) async {
    if (!_attivo) return;
    try {
      if (!_configurato) {
        _configurato = true;
        await AudioPlayer.global.setAudioContext(
          AudioContextConfig(
            respectSilence: true,
            focus: AudioContextConfigFocus.mixWithOthers,
          ).build(),
        );
      }
      await player.stop();
      await player.play(
        AssetSource('suoni/$file'),
        mode: PlayerMode.lowLatency,
      );
    } catch (e) {
      debugPrint('Suono non riprodotto: $e');
    }
  }
}
