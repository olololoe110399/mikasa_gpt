import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static final Env _instance = Env._();

  Env._();

  static Env getInstance() {
    return _instance;
  }

  Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  String _get(String key) {
    return dotenv.env[key] ?? '';
  }

  String get elevenlabApiKey => _get('ELEVENLABS_API_KEY');
  String get anthropicApiKey => _get('ANTHROPIC_API_KEY');
  String get voiceId => 'IKne3meq5aSn9XLyUdCD';
}
