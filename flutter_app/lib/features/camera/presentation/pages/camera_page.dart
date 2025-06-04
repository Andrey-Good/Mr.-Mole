import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mr_mole/features/camera/presentation/bloc/camera_bloc.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/features/camera/presentation/widgets/camera_controls.dart';
import 'package:mr_mole/features/camera/presentation/widgets/camera_preview.dart';
import 'package:mr_mole/features/camera/presentation/widgets/instruction_overlay.dart';
import 'package:mr_mole/features/camera/presentation/constants/camera_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class CameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final NotificationService notificationService;
  final String? presetMoleLocation;
  final String? replaceHistoryItemId;

  const CameraPage({
    super.key,
    required this.cameras,
    required this.notificationService,
    this.presetMoleLocation,
    this.replaceHistoryItemId,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraBloc? _cameraBloc;
  bool _isPermissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();

    _isPermissionRequested = true;

    if (cameraStatus.isGranted) {
      if (_cameraBloc == null) {
        _cameraBloc = CameraBloc(widget.cameras);
        if (mounted) {
          setState(() {});
        }
      }
      _cameraBloc?.add(CameraInitializeEvent());
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Для работы приложения необходим доступ к камере'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed &&
        _isPermissionRequested &&
        _cameraBloc != null) {
      if (_cameraBloc!.state is ImageCaptured) {
        _cameraBloc!.add(ResetStateEvent());
      } else {
        _cameraBloc!.add(CameraInitializeEvent());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraBloc?.add(CameraDisposeEvent());
    _cameraBloc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraBloc == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: CommonWidgets.commonAppBar(
          title: '',
          onBackPressed: () => Navigator.of(context).pop(),
        ),
        body: Center(
          child: CommonWidgets.loadingIndicator(),
        ),
      );
    }

    return BlocProvider.value(
      value: _cameraBloc!,
      child: BlocListener<CameraBloc, CameraState>(
        listener: (context, state) {
          if (state is ImageCaptured) {
            Navigator.of(context).pop(state.imagePath);
          } else if (state is CameraError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: CommonWidgets.commonAppBar(
            title: '',
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          body: _buildCameraPreview(),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return BlocBuilder<CameraBloc, CameraState>(
      builder: (context, state) {
        if (state is CameraInitial) {
          return Center(
            child: CommonWidgets.loadingIndicator(),
          );
        }

        if (state is CameraLoading) {
          return Center(
            child: CommonWidgets.loadingIndicator(),
          );
        }

        if (state is CameraError) {
          return CommonWidgets.errorWidget(
            message: state.message,
          );
        }

        if (state is CameraActive) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CameraPreviewWidget(
                  controller: state.controller,
                ),
              ),
              const Positioned(
                bottom: CameraConstants.controlsBottomOffset,
                left: 0,
                right: 0,
                child: SafeArea(
                  top: false,
                  child: CameraControls(),
                ),
              ),
              if (state.showInstruction)
                InstructionOverlay(
                  onClose: () {
                    context.read<CameraBloc>().add(ToggleInstructionEvent());
                  },
                ),
              if (state.isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...'),
            ],
          ),
        );
      },
    );
  }
}
