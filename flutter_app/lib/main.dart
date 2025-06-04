import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/core/utils/camera_repo.dart';
import 'package:mr_mole/core/utils/model_cache.dart';
import 'package:mr_mole/features/home/presentation/pages/home_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsBinding.instance);

  await initializeDateFormatting('ru_RU', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    final cameras = await CameraHandler.getAvailableCameras();

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    final notificationService =
        NotificationService(flutterLocalNotificationsPlugin);

    await ModelCache.getInstance('assets/model.tflite');

    FlutterNativeSplash.remove();

    runApp(MyApp(
      cameras: cameras,
      notificationService: notificationService,
    ));
  } catch (e) {
    final notificationService =
        NotificationService(FlutterLocalNotificationsPlugin());
    FlutterNativeSplash.remove();
    runApp(MyApp(
      cameras: const [],
      notificationService: notificationService,
    ));
  }
}

class MyApp extends StatefulWidget {
  final List<CameraDescription> cameras;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.cameras,
    required this.notificationService,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ModelCache.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached) {
      ModelCache.release();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mr. Mole',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: PopScope(
        canPop: true,
        child: HomePage(
          cameras: widget.cameras,
          notificationService: widget.notificationService,
        ),
      ),
    );
  }
}
