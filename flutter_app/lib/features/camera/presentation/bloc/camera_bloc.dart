import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:mr_mole/core/utils/image_processor.dart';
import 'package:mr_mole/features/camera/presentation/constants/camera_constants.dart';

part 'camera_event.dart';
part 'camera_state.dart';

class CameraBloc extends Bloc<CameraEvent, CameraState> {
  final List<CameraDescription> cameras;
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  double _currentZoom = CameraConstants.defaultZoom;
  double _minZoom = CameraConstants.defaultMinZoom;
  double _maxZoom = CameraConstants.defaultMaxZoom;
  bool _isFlashOn = false;

  Rect _captureRect = const Rect.fromLTWH(0, 0, 224, 224);

  CameraBloc(this.cameras) : super(CameraInitial()) {
    on<CameraInitializeEvent>(_onInitializeCamera);
    on<CaptureImageEvent>(_onCaptureImage);
    on<CameraDisposeEvent>(_onDispose);
    on<ZoomChangedEvent>(_onZoomChanged);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<ToggleInstructionEvent>(_onToggleInstruction);
    on<ResetStateEvent>(_onResetState);
  }

  Future<void> _onInitializeCamera(
    CameraInitializeEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    try {
      if (state is CameraLoading) {
        return;
      }

      if (_controller != null && _controller!.value.isInitialized) {
        emit(CameraActive(
          _controller!,
          currentZoom: _currentZoom,
          minZoom: _minZoom,
          maxZoom: _maxZoom,
          isFlashOn: _isFlashOn,
          captureRect: const Rect.fromLTWH(0, 0, 224, 224),
          showInstruction: false,
          status: CameraStatus.ready,
        ));
        return;
      }

      emit(CameraLoading());

      if (cameras.isEmpty) {
        emit(const CameraError('Камера недоступна'));
        return;
      }

      _selectedCameraIndex = 0;
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].lensDirection == CameraLensDirection.back) {
          _selectedCameraIndex = i;
          break;
        }
      }

      await _controller?.dispose();
      _controller = null;

      _controller = CameraController(
        cameras[_selectedCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      try {
        await _initializeCameraController();

        if (isClosed) return;

        await _setupCameraSettings();
        _setupCaptureRect();

        if (!isClosed) {
          emit(CameraActive(
            _controller!,
            currentZoom: _currentZoom,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            isFlashOn: _isFlashOn,
            captureRect: _captureRect,
            showInstruction: false,
            status: CameraStatus.ready,
          ));
        }
      } catch (e) {
        if (!isClosed) {
          emit(CameraError('Ошибка инициализации камеры: ${e.toString()}'));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(CameraError('Ошибка инициализации камеры: ${e.toString()}'));
      }
    }
  }

  Future<void> _initializeCameraController() async {
    try {
      await _controller!.initialize().timeout(
            const Duration(seconds: CameraConstants.cameraInitTimeoutSeconds),
            onTimeout: () => throw Exception(
                'Превышено время ожидания инициализации камеры'),
          );
    } catch (e) {
      if (!isClosed && _controller != null) {
        await _controller?.dispose();
        _controller = CameraController(
          cameras[_selectedCameraIndex],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();
      } else {
        rethrow;
      }
    }
  }

  Future<void> _setupCameraSettings() async {
    try {
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      _currentZoom = _minZoom;

      if (_maxZoom > _minZoom) {
        await _controller!.setZoomLevel(_minZoom);
      }
    } catch (e) {
      _minZoom = CameraConstants.defaultMinZoom;
      _maxZoom = CameraConstants.defaultMaxZoom;
      _currentZoom = CameraConstants.defaultZoom;
    }

    await _controller!.setFlashMode(FlashMode.off);
    _isFlashOn = false;
  }

  void _setupCaptureRect() {
    if (_controller!.value.previewSize != null) {
      final previewSize = _controller!.value.previewSize!;
      final double centerX = previewSize.width / 2;
      final double centerY = previewSize.height / 2;

      _captureRect = Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: CameraConstants.modelImageSize,
        height: CameraConstants.modelImageSize,
      );
    } else {
      _captureRect = const Rect.fromLTWH(
        0,
        0,
        CameraConstants.modelImageSize,
        CameraConstants.modelImageSize,
      );
    }
  }

  Future<void> _onCaptureImage(
    CaptureImageEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (isClosed ||
        state is! CameraActive ||
        !(state as CameraActive).isReady) {
      return;
    }

    try {
      final currentState = state as CameraActive;
      emit(currentState.copyWith(status: CameraStatus.capturing));

      final XFile image = await _controller!.takePicture();

      final imageInfo = await ImageProcessor.getImageInfo(image.path);

      if (imageInfo.containsKey('error')) {
        emit(
            CameraError('Ошибка обработки изображения: ${imageInfo['error']}'));
        return;
      }

      final int imageWidth = imageInfo['width'] as int;
      final int imageHeight = imageInfo['height'] as int;

      final int cropSize =
          (imageWidth < imageHeight ? imageWidth : imageHeight) ~/ 2;
      final int centerX = imageWidth ~/ 2;
      final int centerY = imageHeight ~/ 2;
      final int x = (centerX - cropSize ~/ 2).clamp(0, imageWidth - cropSize);
      final int y = (centerY - cropSize ~/ 2).clamp(0, imageHeight - cropSize);

      final String croppedPath = await ImageProcessor.cropByCoordinates(
        imagePath: image.path,
        x: x,
        y: y,
        width: cropSize,
        height: cropSize,
        resizeToModelSize: true,
      );

      emit(ImageCaptured(croppedPath, captureRect: _captureRect));
    } catch (e) {
      if (!isClosed) {
        emit(CameraError('Ошибка при съемке: ${e.toString()}'));
      }
    }
  }

  void _onToggleInstruction(
    ToggleInstructionEvent event,
    Emitter<CameraState> emit,
  ) {
    if (state is CameraActive && (state as CameraActive).isReady) {
      final currentState = state as CameraActive;
      emit(currentState.copyWith(
        showInstruction: !currentState.showInstruction,
      ));
    }
  }

  void _onResetState(
    ResetStateEvent event,
    Emitter<CameraState> emit,
  ) {
    emit(CameraActive(
      _controller!,
      currentZoom: _currentZoom,
      minZoom: _minZoom,
      maxZoom: _maxZoom,
      isFlashOn: _isFlashOn,
      captureRect: _captureRect,
      showInstruction: false,
      status: CameraStatus.ready,
    ));
  }

  Future<void> _onDispose(
    CameraDisposeEvent event,
    Emitter<CameraState> emit,
  ) async {
    await _controller?.dispose();
    _controller = null;
    emit(CameraInitial());
  }

  @override
  Future<void> close() async {
    await _controller?.dispose();
    _controller = null;
    return super.close();
  }

  Future<void> _onZoomChanged(
    ZoomChangedEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    if (state is! CameraActive || !(state as CameraActive).isReady) {
      return;
    }

    try {
      final newZoom = event.zoomLevel.clamp(_minZoom, _maxZoom);
      await _controller!.setZoomLevel(newZoom);
      _currentZoom = newZoom;

      final currentState = state as CameraActive;
      emit(currentState.copyWith(currentZoom: _currentZoom));
    } catch (e) {
      if (!isClosed) {
        emit(CameraError('Ошибка при изменении масштаба: ${e.toString()}'));
      }
    }
  }

  Future<void> _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<CameraState> emit,
  ) async {
    if (isClosed) {
      return;
    }

    if (state is! CameraActive || !(state as CameraActive).isReady) {
      return;
    }

    try {
      final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _controller!.setFlashMode(newFlashMode);
      _isFlashOn = !_isFlashOn;

      final currentState = state as CameraActive;
      emit(currentState.copyWith(isFlashOn: _isFlashOn));
    } catch (e) {
      if (!isClosed) {
        emit(CameraError('Ошибка при переключении фонаря: ${e.toString()}'));
      }
    }
  }
}
