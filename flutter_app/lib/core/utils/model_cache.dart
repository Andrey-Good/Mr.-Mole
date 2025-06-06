import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelCache {
  static Interpreter? _interpreter;
  static int _usersCount = 0;
  static bool _isInitializing = false;

  static void _resetState() {
    _interpreter = null;
    _usersCount = 0;
    _isInitializing = false;
  }

  static Future<Interpreter?> getInstance(String assetPath) async {
    if (_interpreter != null) {
      _usersCount++;
      return _interpreter;
    }

    if (_isInitializing) {
      if (_isInitializing) {
        _resetState();
      }
      return getInstance(assetPath);
    }

    _isInitializing = true;

    final modelData = await rootBundle.load(assetPath);

    if (modelData.lengthInBytes == 0) {
      throw Exception('Файл модели пуст');
    }

    final modelBytes = Uint8List.fromList(modelData.buffer.asUint8List());
    _interpreter = Interpreter.fromBuffer(modelBytes);

    _interpreter = await Interpreter.fromAsset(assetPath);

    if (_interpreter == null) {
      throw Exception('Не удалось загрузить модель');
    }

    if (!_interpreter!.isAllocated) {
      throw Exception('Модель не инициализирована');
    }

    _usersCount++;
    _isInitializing = false;
    return _interpreter;
  }

  static void release() {
    _usersCount--;
    if (_usersCount <= 0 && _interpreter != null) {
      if (_interpreter!.isAllocated) {
        _interpreter!.close();
      }
      _resetState();
    }
  }

  static Interpreter? get interpreter => _interpreter;
  static bool get isLoaded => _interpreter != null;
}
