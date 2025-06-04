import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mr_mole/features/camera/presentation/constants/camera_constants.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: AppColors.cameraBackground,
        child: CommonWidgets.loadingIndicator(),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final double frameSize =
        screenSize.shortestSide * CameraConstants.captureFrameSizePercent;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        CustomPaint(
          painter: _FrameOverlayPainter(
            screenSize: screenSize,
            frameSize: frameSize,
          ),
          size: screenSize,
        ),
      ],
    );
  }
}

class _FrameOverlayPainter extends CustomPainter {
  final Size screenSize;
  final double frameSize;

  _FrameOverlayPainter({
    required this.screenSize,
    required this.frameSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (screenSize.width - frameSize) / 2;
    final double top = (screenSize.height - frameSize) / 2;

    final Path path = Path()
      ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, frameSize, frameSize),
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    final Paint darkPaint = Paint()
      ..color = AppColors.cameraOverlay
          .withValues(alpha: CameraConstants.overlayOpacity)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, darkPaint);

    final Paint borderPaint = Paint()
      ..color = AppColors.cameraFrame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, frameSize, frameSize),
        const Radius.circular(12),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
