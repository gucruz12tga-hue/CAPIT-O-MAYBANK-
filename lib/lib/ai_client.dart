import 'package:android_intent_plus/android_intent.dart';

/// Comandos simples do celular. Retorna a resposta se o texto era um
/// comando, ou null para o texto seguir para a IA.
class PhoneCommands {
  static const Map<String, String> _apps = {
    'whatsapp': 'com.whatsapp',
    'youtube': 'com.google.android.youtube',
    'chrome': 'com.android.chrome',
    'câmera': 'com.android.camera',
    'camera': 'com.android.camera',
    'maps': 'com.google.android.apps.maps',
    'mapas': 'com.google.android.apps.maps',
    'gmail': 'com.google.android.gm',
    'instagram': 'com.instagram.android',
    'spotify': 'com.spotify.music',
    'telegram': 'org.telegram.messenger',
    'play store': 'com.android.vending',
  };

  static Future<String?> tryHandle(String raw) async {
    final t = raw.toLowerCase().trim();

    final alarm = RegExp(r'alarme.*?(\d{1,2})\s*(?:[:h]\s*(\d{2}))?').firstMatch(t);
    if (alarm != null) {
      final h = int.parse(alarm.group(1)!);
      final m = int.tryParse(alarm.group(2) ?? '0') ?? 0;
      if (h > 23 || m > 59) return 'Horário inválido para o alarme.';
      await AndroidIntent(
        action: 'android.intent.action.SET_ALARM',
        arguments: {
          'android.intent.extra.alarm.HOUR': h,
          'android.intent.extra.alarm.MINUTES': m,
          'android.intent.extra.alarm.SKIP_UI': false,
        },
      ).launch();
      return 'Abri o alarme das ${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}. Confirme na tela do relógio.';
    }

    final timer = RegExp(r'timer.*?(\d+)\s*(segundo|minuto|hora)').firstMatch(t);
    if (timer != null) {
      final n = int.parse(timer.group(1)!);
      final unit = timer.group(2)!;
      final seconds = unit == 'hora' ? n * 3600 : (unit == 'minuto' ? n * 60 : n);
      await AndroidIntent(
        action: 'android.intent.action.SET_TIMER',
        arguments: {
          'android.intent.extra.alarm.LENGTH': seconds,
          'android.intent.extra.alarm.SKIP_UI': false,
        },
      ).launch();
      return 'Timer de $n $unit(s) preparado. Confirme na tela do relógio.';
    }

    final open = RegExp(r'^(abrir|abre|abra)\s+(?:o |a )?(.+)$').firstMatch(t);
    if (open != null) {
      final name = open.group(2)!.trim();
      final pkg = _apps[name];
      if (pkg == null) {
        return 'Ainda não sei abrir "$name". Por enquanto abro: ${_apps.keys.join(', ')}.';
      }
      await AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: pkg,
      ).launch();
      return 'Abrindo $name.';
    }

    return null;
  }
}
