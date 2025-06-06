import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/core/utils/image_processor.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class MoleConfirmationScreen extends StatefulWidget {
  final String imagePath;
  final NotificationService notificationService;
  final String? presetMoleLocation;

  const MoleConfirmationScreen({
    super.key,
    required this.imagePath,
    required this.notificationService,
    this.presetMoleLocation,
  });

  @override
  State<MoleConfirmationScreen> createState() => _MoleConfirmationScreenState();
}

class _MoleConfirmationScreenState extends State<MoleConfirmationScreen> {
  final double _cropSquareSize = 260.0;
  bool _isProcessing = false;

  Offset _squarePosition = Offset.zero;
  Size _screenSize = Size.zero;
  Widget? _cachedImage;

  @override
  void initState() {
    super.initState();
    _isProcessing = false;

    _cachedImage = Image.file(
      File(widget.imagePath),
      fit: BoxFit.cover,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _screenSize = MediaQuery.of(context).size;
        _squarePosition = Offset(
          (_screenSize.width - _cropSquareSize) / 2,
          (_screenSize.height - _cropSquareSize) / 2,
        );
        _isProcessing = false;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenSize == Size.zero) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CommonWidgets.commonAppBar(
          title: 'Подтверждение',
          onBackPressed: () {
            _isProcessing = false;
            Navigator.of(context).pop();
          },
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _cachedImage!,
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) {
        _isProcessing = false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: CommonWidgets.commonAppBar(
          title: 'Подтверждение',
          onBackPressed: () {
            _isProcessing = false;
            Navigator.of(context).pop();
          },
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: _cachedImage!),
            RepaintBoundary(
              child: CustomPaint(
                painter: _CropOverlayPainter(
                  screenSize: _screenSize,
                  cropSquareLeft: _squarePosition.dx,
                  cropSquareTop: _squarePosition.dy,
                  cropSquareSize: _cropSquareSize,
                ),
                size: _screenSize,
              ),
            ),
            Positioned(
              left: _squarePosition.dx,
              top: _squarePosition.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final newPosition = _squarePosition + details.delta;
                    _squarePosition = Offset(
                      newPosition.dx
                          .clamp(0, _screenSize.width - _cropSquareSize),
                      newPosition.dy
                          .clamp(0, _screenSize.height - _cropSquareSize),
                    );
                  });
                },
                child: Container(
                  width: _cropSquareSize,
                  height: _cropSquareSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.cameraFrame,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 50,
              child: CommonWidgets.commonButton(
                text: _isProcessing ? 'Обработка...' : 'Подтвердить',
                onPressed: _isProcessing ? () {} : () => _confirmCrop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCrop() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final croppedPath = await _cropImageByCenterSquare();
      if (mounted) {
        Navigator.of(context).pop(croppedPath);
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка обработки изображения: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String> _cropImageByCenterSquare() async {
    final imageInfo = await ImageProcessor.getImageInfo(widget.imagePath);

    if (imageInfo.containsKey('error')) {
      throw Exception('Ошибка обработки изображения: ${imageInfo['error']}');
    }

    final int imageWidth = imageInfo['width'] as int;
    final int imageHeight = imageInfo['height'] as int;

    final squareCenterX = _squarePosition.dx + _cropSquareSize / 2;
    final squareCenterY = _squarePosition.dy + _cropSquareSize / 2;

    final imageAspect = imageWidth / imageHeight;
    final screenAspect = _screenSize.width / _screenSize.height;

    double scaleX, scaleY;
    double imageLeft = 0, imageTop = 0;

    if (imageAspect > screenAspect) {
      scaleY = imageHeight / _screenSize.height;
      scaleX = scaleY;
      imageLeft = (imageWidth - _screenSize.width * scaleX) / 2;
    } else {
      scaleX = imageWidth / _screenSize.width;
      scaleY = scaleX;
      imageTop = (imageHeight - _screenSize.height * scaleY) / 2;
    }

    final imageCenterX = imageLeft + squareCenterX * scaleX;
    final imageCenterY = imageTop + squareCenterY * scaleY;

    final int cropSize =
        (imageWidth < imageHeight ? imageWidth : imageHeight) ~/ 2;

    final int x =
        (imageCenterX - cropSize / 2).round().clamp(0, imageWidth - cropSize);
    final int y =
        (imageCenterY - cropSize / 2).round().clamp(0, imageHeight - cropSize);

    return ImageProcessor.cropByCoordinates(
      imagePath: widget.imagePath,
      x: x,
      y: y,
      width: cropSize,
      height: cropSize,
    );
  }
}

class _CropOverlayPainter extends CustomPainter {
  final Size screenSize;
  final double cropSquareLeft;
  final double cropSquareTop;
  final double cropSquareSize;

  _CropOverlayPainter({
    required this.screenSize,
    required this.cropSquareLeft,
    required this.cropSquareTop,
    required this.cropSquareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(
            cropSquareLeft, cropSquareTop, cropSquareSize, cropSquareSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    final Paint darkPaint = Paint()
      ..color = AppColors.overlay
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, darkPaint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter oldDelegate) {
    return oldDelegate.cropSquareLeft != cropSquareLeft ||
        oldDelegate.cropSquareTop != cropSquareTop;
  }
}
