import 'package:async/async.dart';
import 'package:mikasa_gpt/core/env.dart';

class Config {
  factory Config.getInstance() {
    return _instance;
  }

  Config._();

  static final Config _instance = Config._();

  final AsyncMemoizer<void> _asyncMemoizer = AsyncMemoizer<void>();

  Future<void> init() => _asyncMemoizer.runOnce(config);

  Future<void> config() async {
    await Env.getInstance().init();
  }
}
