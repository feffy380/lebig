import 'package:flutter/widgets.dart';
import 'package:lebig/world.dart';

/// Advance world state and notify UI
class SimController extends ChangeNotifier {
  final World _world;
  var tickRate = 1.0;  // updates per second
  var _isRunning = false;

  SimController({required World world}) : _world = world;

  World get world => _world;

  void start() async {
    _isRunning = true;
    while (_isRunning) {
      final stopwatch = Stopwatch()..start();

      // Tick
      _world.step();

      // Update UI
      notifyListeners();

      // Rate limit
      final elapsed = stopwatch.elapsedMilliseconds;
      final budget = 1000 / tickRate;
      if (elapsed < budget) {
        await Future.delayed(Duration(milliseconds: (budget - elapsed).toInt()));
      } else {
        // Don't pause if budget exceeded
        await Future.delayed(Duration.zero);
      }
    }
  }

  void stop() {
    _isRunning = false;
  }
}
