import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:equatable/equatable.dart';
import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/core/utils/model_cache.dart';
import 'package:mr_mole/features/home/data/repositories/scan_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'analysis_event.dart';
part 'analysis_state.dart';

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final String imagePath;
  final NotificationService notificationService;
  final ScanHistoryRepository historyRepository;
  final SharedPreferences prefs;
  final String? replaceHistoryItemId;
  Interpreter? _interpreter;

  AnalysisBloc({
    required this.imagePath,
    required this.notificationService,
    required this.historyRepository,
    required this.prefs,
    this.replaceHistoryItemId,
  }) : super(AnalysisInitial()) {
    on<AnalyzeImageEvent>(_onAnalyzeImage);
    on<SaveResultEvent>(_onSaveResult);
  }

  Future<void> _onAnalyzeImage(
    AnalyzeImageEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    if (isClosed) return;

    try {
      emit(AnalysisLoading());

      _interpreter = ModelCache.interpreter;
      if (_interpreter == null) {
        emit(const AnalysisError('Модель недоступна'));
        return;
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        emit(const AnalysisError('Изображение не найдено'));
        return;
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        emit(const AnalysisError('Не удалось декодировать изображение'));
        return;
      }

      final inputShape = _interpreter!.getInputTensor(0).shape;
      final outputShape = _interpreter!.getOutputTensor(0).shape;

      final inputBuffer =
          Float32List(inputShape[1] * inputShape[2] * inputShape[3]);
      final outputBuffer = Float32List(outputShape[1]);

      var index = 0;
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          inputBuffer[index++] = r / 255.0;
          inputBuffer[index++] = g / 255.0;
          inputBuffer[index++] = b / 255.0;
        }
      }

      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);

      final probability = outputBuffer[0];
      final result = probability < 0.3
          ? 'Отрицательный.'
          : probability < 0.7
              ? 'Возможны признаки меланомы. Рекомендуется консультация врача.'
              : 'Высокая вероятность меланомы. Срочно обратитесь к врачу!';

      if (!isClosed) {
        emit(AnalysisSuccess(result));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AnalysisError('Ошибка при анализе: ${e.toString()}'));
      }
    }
  }

  Future<void> _onSaveResult(
    SaveResultEvent event,
    Emitter<AnalysisState> emit,
  ) async {
    if (isClosed) return;

    try {
      if (state is AnalysisSuccess) {
        final result = (state as AnalysisSuccess).result;

        bool saveSuccess = false;
        if (replaceHistoryItemId != null) {
          saveSuccess = await historyRepository.replaceInHistory(
            replaceHistoryItemId!,
            imagePath,
            result,
            moleLocation: event.moleLocation,
          );
        } else {
          saveSuccess = await historyRepository.addToHistory(
            imagePath,
            result,
            moleLocation: event.moleLocation,
          );
        }

        if (!saveSuccess) {
          final errorMessage = historyRepository.lastError ??
              'Неизвестная ошибка при сохранении';
          emit(AnalysisError('Не удалось сохранить результат: $errorMessage'));
          return;
        }

        await _scheduleReminders(emit);
      } else {
        emit(AnalysisError(
            'ОШИБКА: Состояние не AnalysisSuccess, текущее: ${state.runtimeType}'));
      }
    } catch (e) {
      if (!isClosed) {
        emit(
            AnalysisError('Ошибка при сохранении результата: ${e.toString()}'));
      }
    }
  }

  Future<void> _scheduleReminders(Emitter<AnalysisState> emit) async {
    try {
      final notificationsEnabled = prefs.getBool('notifications') ?? true;
      if (!notificationsEnabled) return;

      final durationMonths = prefs.getInt('notification_duration') ?? 3;
      final now = DateTime.now();

      await notificationService.scheduleNotification(
        title: 'Напоминание о проверке родинок',
        body: 'Время для регулярной проверки родинок',
        scheduledDate: now.add(Duration(days: durationMonths * 30)),
        id: 1001,
      );
    } catch (e) {
      if (!isClosed) {
        emit(AnalysisError('Ошибка при планировании напоминаний: $e'));
      }
    }
  }
}
