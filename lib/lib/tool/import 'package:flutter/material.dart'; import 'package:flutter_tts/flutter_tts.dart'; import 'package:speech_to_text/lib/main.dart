import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'ai_client.dart';
import 'commands.dart';
import 'settings.dart';

void main() => runApp(const CapitaoApp());

class CapitaoApp extends StatefulWidget {
  const CapitaoApp({super.key});
  @override
  State<CapitaoApp> createState() => _CapitaoAppState();
}

class _CapitaoAppState extends State<CapitaoApp> {
  AppSettings? settings;

  @override
  void initState() {
    super.initState();
    AppSettings.load().then((s) => setState(() => settings = s));
  }

  @override
  Widget build(BuildContext context) {
    final s = settings;
    if (s == null) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      title: s.name,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(s.colorValue), brightness: Brightness.dark),
      ),
      home: ChatPage(settings: s, onChanged: () => setState(() {})),
    );
  }
}

class ChatPage extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onChanged;
  const ChatPage({super.key, required this.settings, required this.onChanged});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMsg> _msgs = [];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _stt = SpeechToText();
  final _tts = FlutterTts();
  bool _sttReady = false;
  bool _listening = false;
  bool _busy = false;

  AppSettings get s => widget.settings;

  @override
  void initState() {
    super.initState();
    _initVoice();
    _msgs.add(ChatMsg('assistant', 'Às ordens! Sou o ${s.name}. Pode digitar ou tocar no microfone.'));
  }

  Future<void> _initVoice() async {
    try {
      _sttReady = await _stt.initialize();
    } catch (_) {
      _sttReady = false;
    }
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(0.6); // tom grave
      final voices = await _tts.getVoices;
      if (voices is List) {
        final pt = voices.whereType<Map>().where((v) =>
            (v['locale'] ?? '').toString().toLowerCase().replaceAll('_', '-') == 'pt-br');
        Map? pick;
        for (final v in pt) {
          final n = (v['name'] ?? '').toString().toLowerCase();
          if (n.contains('ptd') || (n.contains('male') && !n.contains('female'))) {
            pick = v;
            break;
          }
        }
        if (pick != null) {
          await _tts.setVoice({'name': pick['name'].toString(), 'locale': pick['locale'].toString()});
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    _input.clear();
    setState(() {
      _msgs.add(ChatMsg('user', t));
      _busy = true;
    });
    _toBottom();

    String reply;
    try {
      reply = await PhoneCommands.tryHandle(t) ?? await AiClient.ask(s, _msgs);
    } catch (e) {
      reply = 'Não consegui executar isso no celular.';
    }

    if (!mounted) return;
    setState(() {
      _msgs.add(ChatMsg('assistant', reply));
      _busy = false;
    });
    _toBottom();
    if (s.speakReplies) {
      await _tts.stop();
      await _tts.speak(reply);
    }
  }

  Future<void> _toggleMic() async {
    if (!_sttReady) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Reconhecimento de voz indisponível. Permita o microfone nas configurações do Android.')));
      return;
    }
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    await _tts.stop();
    setState(() => _listening = true);
    await _stt.listen(
      localeId: 'pt_BR',
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (r) {
        _input.text = r.recognizedWords;
        if (r.finalResult) {
          setState(() => _listening = false);
          _send(r.recognizedWords);
        }
      },
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => SettingsPage(settings: s)));
    widget.onChanged();
    setState(() {});
  }

  @override
  void dispose() {
    _stt.stop();
    _tts.stop();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.name),
        actions: [
