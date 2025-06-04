import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mr_mole/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:mr_mole/features/camera/presentation/constants/camera_constants.dart';
import 'package:mr_mole/core/constants/app_colors.dart';

class CameraControls extends StatelessWidget {
  const CameraControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(CameraConstants.controlsPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<CameraBloc, CameraState>(
            builder: (context, state) {
              if (state is CameraActive) {
                final double currentZoom;
                final double minZoom;
                final double maxZoom;

                if (state.isReady) {
                  currentZoom = state.currentZoom;
                  minZoom = state.minZoom;
                  maxZoom = state.maxZoom;
                } else {
                  currentZoom = state.currentZoom;
                  minZoom = state.minZoom;
                  maxZoom = state.maxZoom;
                }

                final bool zoomSupported = maxZoom > minZoom;

                if (!zoomSupported) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Зум не поддерживается на этом устройстве',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  );
                }

                return ZoomSlider(
                  currentZoom: currentZoom,
                  minZoom: minZoom,
                  maxZoom: maxZoom,
                  isEnabled: state.isReady,
                );
              }
              return const SizedBox();
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.info_outline,
                color: Colors.white,
                size: CameraConstants.controlIconSize,
                onPressed: () =>
                    context.read<CameraBloc>().add(ToggleInstructionEvent()),
                tooltip: 'Инструкция',
              ),
              _CaptureButton(),
              BlocBuilder<CameraBloc, CameraState>(
                builder: (context, state) {
                  if (state is CameraActive) {
                    final bool isFlashOn;
                    final bool isEnabled = state.isReady;

                    isFlashOn = state.isFlashOn;

                    return _buildControlButton(
                      icon: isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: isEnabled ? Colors.white : Colors.grey,
                      size: CameraConstants.controlIconSize,
                      onPressed: isEnabled
                          ? () =>
                              context.read<CameraBloc>().add(ToggleFlashEvent())
                          : null,
                      tooltip:
                          isFlashOn ? 'Выключить вспышку' : 'Включить вспышку',
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      width: CameraConstants.controlButtonSize,
      height: CameraConstants.controlButtonSize,
      decoration: const BoxDecoration(
        color: Colors.black26,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        final bool isReady = state is CameraActive && state.isReady;
        final bool isCapturing = state is CameraActive && state.isCapturing;
        final bool isEnabled = isReady && !isCapturing;

        return Container(
          width: CameraConstants.captureButtonSize,
          height: CameraConstants.captureButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: CameraConstants.captureButtonBorderWidth,
            ),
          ),
          child: Center(
            child: GestureDetector(
              onTap: isEnabled
                  ? () => context.read<CameraBloc>().add(
                        CaptureImageEvent(MediaQuery.of(context).size),
                      )
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: CameraConstants.captureButtonInnerSize,
                height: CameraConstants.captureButtonInnerSize,
                decoration: BoxDecoration(
                  color: isCapturing
                      ? AppColors.overlayDark
                      : isReady
                          ? Colors.white
                          : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ZoomSlider extends StatelessWidget {
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final bool isEnabled;

  const ZoomSlider({
    super.key,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4.0,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8.0,
            disabledThumbRadius: 6.0,
          ),
          overlayShape: const RoundSliderOverlayShape(
            overlayRadius: 12.0,
          ),
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
          thumbColor: Colors.white,
          overlayColor: Colors.white.withValues(alpha: 0.2),
        ),
        child: Slider(
          value: currentZoom,
          min: minZoom,
          max: maxZoom > CameraConstants.maxZoomForSlider
              ? CameraConstants.maxZoomForSlider
              : maxZoom,
          onChanged: isEnabled
              ? (value) {
                  context.read<CameraBloc>().add(ZoomChangedEvent(value));
                }
              : null,
        ),
      ),
    );
  }
}
