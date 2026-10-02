import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  String name;
  String apiKey;
  String model;
  String persona;
  bool speakReplies;
  int colorValue;

  AppSettings({
    this.name = 'CAPITÃO_MAYBANK',
    this.apiKey = '',
    this.model = 'claude-sonnet-4-6',
    this.persona =
        'Você é um assistente pessoal leal, direto e simpático. Responda sempre em português do Brasil, de forma clara e curta, a menos que o usuário peça mais detalhes.',
    this.speakReplies = true,
    this.colorValue = 0xFF1565C0,
  });

  static Future<AppSettings> load() async {
    final p = await SharedPreferences.getInstance();
    final d = AppSettings();
    return AppSettings(
      name: p.getString('name') ?? d.name,
      apiKey: p.getString('apiKey') ?? d.apiKey,
      model: p.getString('model') ?? d.model,
      persona: p.getString('persona') ?? d.persona,
      speakReplies: p.getBool('speakReplies') ?? d.speakReplies,
      colorValue: p.getInt('colorValue') ?? d.colorValue,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('name', name);
    await p.setString('apiKey', apiKey);
    await p.setString('model', model);
    await p.setString('persona', persona);
    await p.setBool('speakReplies', speakReplies);
    await p.setInt('colorValue', colorValue);
  }
}
