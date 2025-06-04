part of 'camera_bloc.dart';

abstract class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object> get props => [];
}

class CameraInitial extends CameraState {}

class CameraLoading extends CameraState {}

enum CameraStatus { ready, capturing }

class CameraActive extends CameraState {
  final CameraController controller;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final bool isFlashOn;
  final bool showInstruction;
  final Rect captureRect;
  final CameraStatus status;

  const CameraActive(
    this.controller, {
    this.currentZoom = 1.0,
    this.minZoom = 1.0,
    this.maxZoom = 1.0,
    this.isFlashOn = false,
    this.showInstruction = false,
    this.captureRect = const Rect.fromLTWH(0, 0, 224, 224),
    this.status = CameraStatus.ready,
  });

  CameraActive copyWith({
    CameraController? controller,
    double? currentZoom,
    double? minZoom,
    double? maxZoom,
    bool? isFlashOn,
    bool? showInstruction,
    Rect? captureRect,
    CameraStatus? status,
  }) {
    return CameraActive(
      controller ?? this.controller,
      currentZoom: currentZoom ?? this.currentZoom,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      showInstruction: showInstruction ?? this.showInstruction,
      captureRect: captureRect ?? this.captureRect,
      status: status ?? this.status,
    );
  }

  // Удобные геттеры
  bool get isReady => status == CameraStatus.ready;
  bool get isCapturing => status == CameraStatus.capturing;

  @override
  List<Object> get props => [
        controller,
        currentZoom,
        minZoom,
        maxZoom,
        isFlashOn,
        showInstruction,
        captureRect,
        status,
      ];
}

class ImageCaptured extends CameraState {
  final String imagePath;
  final Rect captureRect;

  const ImageCaptured(this.imagePath, {required this.captureRect});

  @override
  List<Object> get props => [imagePath, captureRect];
}

class CameraError extends CameraState {
  final String message;

  const CameraError(this.message);

  @override
  List<Object> get props => [message];
}
