import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:mr_mole/features/home/domain/models/scan_history_item.dart';

class ScanHistoryRepository {
  static const String _historyKey = 'scan_history';
  final Uuid _uuid = const Uuid();

  String? lastError;

  Future<List<ScanHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_historyKey);

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final items = ScanHistoryItem.decode(historyJson);

      final validItems = <ScanHistoryItem>[];
      for (final item in items) {
        final file = File(item.imagePath);
        if (await file.exists()) {
          validItems.add(item);
        }
      }

      if (validItems.length != items.length) {
        await _saveHistory(validItems, prefs);
      }

      return validItems;
    } catch (e) {
      lastError = 'Ошибка загрузки истории: $e';
      return [];
    }
  }

  Future<bool> _saveHistory(
      List<ScanHistoryItem> items, SharedPreferences prefs) async {
    try {
      final encodedData = ScanHistoryItem.encode(items);
      final result = await prefs.setString(_historyKey, encodedData);

      final saved = prefs.getString(_historyKey);
      final success = saved != null && saved == encodedData;

      if (!success) {
        lastError = 'SharedPreferences не сохранил данные';
      }

      return result && success;
    } catch (e) {
      lastError = 'Ошибка при сохранении в SharedPreferences: $e';
      return false;
    }
  }

  Future<bool> addToHistory(
    String imagePath,
    String result, {
    String? moleLocation,
  }) async {
    try {
      lastError = null;

      final String savedImagePath = await _saveImageToLocalStorage(imagePath);

      if (lastError != null) {
        return false;
      }

      final historyItem = ScanHistoryItem(
        id: _uuid.v4(),
        imagePath: savedImagePath,
        result: result,
        timestamp: DateTime.now(),
        moleLocation: moleLocation,
      );

      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryItem> currentHistory = await getHistory();

      currentHistory.insert(0, historyItem);

      final List<ScanHistoryItem> trimmedHistory = currentHistory.length > 50
          ? currentHistory.sublist(0, 50)
          : currentHistory;

      final success = await _saveHistory(trimmedHistory, prefs);

      if (!success) {
        return false;
      }

      final verifyHistory = await getHistory();
      final found = verifyHistory.any((item) => item.id == historyItem.id);

      if (!found) {
        lastError = 'Элемент не найден после сохранения';
      }

      return found;
    } catch (e) {
      lastError = 'Общая ошибка сохранения: $e';
      return false;
    }
  }

  Future<bool> replaceInHistory(
    String id,
    String imagePath,
    String result, {
    String? moleLocation,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryItem> currentHistory = await getHistory();

      final itemIndex = currentHistory.indexWhere((item) => item.id == id);

      if (itemIndex == -1) {
        return false;
      }

      final String savedImagePath = await _saveImageToLocalStorage(imagePath);
      final oldItem = currentHistory[itemIndex];

      final oldImageFile = File(oldItem.imagePath);
      if (await oldImageFile.exists()) {
        await oldImageFile.delete();
      }

      final updatedItem = ScanHistoryItem(
        id: id,
        imagePath: savedImagePath,
        result: result,
        timestamp: DateTime.now(),
        moleLocation: moleLocation,
      );

      currentHistory[itemIndex] = updatedItem;

      return await _saveHistory(currentHistory, prefs);
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFromHistory(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryItem> currentHistory = await getHistory();

      final itemToRemove = currentHistory.firstWhere((item) => item.id == id);

      final imageFile = File(itemToRemove.imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }

      currentHistory.removeWhere((item) => item.id == id);

      return await _saveHistory(currentHistory, prefs);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<ScanHistoryItem> currentHistory = await getHistory();

      for (var item in currentHistory) {
        final imageFile = File(item.imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      final result = await prefs.remove(_historyKey);

      return result;
    } catch (e) {
      return false;
    }
  }

  Future<String> _saveImageToLocalStorage(String originalPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${directory.path}/history_images');

      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }

      final fileName = '${_uuid.v4()}.jpg';
      final destinationPath = '${historyDir.path}/$fileName';

      await File(originalPath).copy(destinationPath);

      final copiedFile = File(destinationPath);
      if (!await copiedFile.exists()) {
        lastError = 'Файл не был скопирован в $destinationPath';
        throw Exception('Файл не был скопирован');
      }

      return destinationPath;
    } catch (e) {
      lastError = 'Ошибка копирования файла: $e';
      return originalPath;
    }
  }
}
