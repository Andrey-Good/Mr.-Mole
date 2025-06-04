import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:mr_mole/features/home/presentation/bloc/home_bloc.dart';
import 'package:mr_mole/features/camera/presentation/pages/camera_page.dart';
import 'package:mr_mole/features/settings/presentation/pages/settings_page.dart';
import 'package:mr_mole/features/analysis/presentation/pages/analys.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/features/camera/presentation/pages/mole_confirmation_screen.dart';
import 'package:mr_mole/features/home/presentation/widgets/main_tab.dart';
import 'package:mr_mole/features/home/presentation/widgets/history_tab.dart';
import 'package:mr_mole/features/home/presentation/widgets/faq_tab.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';
import 'package:mr_mole/features/home/presentation/pages/history_detail_page.dart';
import 'package:mr_mole/features/home/domain/models/scan_history_item.dart';

class HomePage extends StatefulWidget {
  final List<CameraDescription> cameras;
  final NotificationService notificationService;

  const HomePage({
    super.key,
    required this.cameras,
    required this.notificationService,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late HomeBloc _homeBloc;
  late PageController _pageController;
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _homeBloc = HomeBloc(widget.cameras);
    _pageController = PageController(initialPage: 1);
  }

  void _resetToMainTab() {
    if (mounted) {
      setState(() {
        _currentIndex = 1;
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Future<void> _navigateToCamera(List<CameraDescription> cameras,
      {String? presetMoleLocation, String? replaceHistoryItemId}) async {
    final String? croppedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => CameraPage(
          cameras: cameras,
          notificationService: widget.notificationService,
          presetMoleLocation: presetMoleLocation,
          replaceHistoryItemId: replaceHistoryItemId,
        ),
      ),
    );

    if (croppedPath != null) {
      _navigateToAnalysisWithPreset(croppedPath, presetMoleLocation,
          replaceHistoryItemId: replaceHistoryItemId);
    } else {
      _resetToMainTab();
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  void _navigateToConfirmation(String imagePath,
      {String? presetMoleLocation}) async {
    final String? croppedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => MoleConfirmationScreen(
          imagePath: imagePath,
          notificationService: widget.notificationService,
          presetMoleLocation: presetMoleLocation,
        ),
      ),
    );

    if (croppedPath != null) {
      _navigateToAnalysisWithPreset(croppedPath, presetMoleLocation);
    } else {
      _resetToMainTab();
    }
  }

  void _navigateToAnalysisWithPreset(
      String imagePath, String? presetMoleLocation,
      {String? replaceHistoryItemId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisScreen(
          imagePath: imagePath,
          notificationService: widget.notificationService,
          presetMoleLocation: presetMoleLocation,
          replaceHistoryItemId: replaceHistoryItemId,
          onRetake: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    ).then((_) {
      _resetToMainTab();
    });
  }

  void _navigateToHistoryDetail(ScanHistoryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailPage(
          item: item,
          onRescanPressed: () {
            Navigator.of(context).pop();
            _navigateToCamera(widget.cameras,
                presetMoleLocation: item.moleLocation,
                replaceHistoryItemId: item.id);
          },
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _homeBloc.close();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is GalleryImageSelected) {
            _navigateToConfirmation(state.imagePath);
          } else if (state is CameraReady) {
            _navigateToCamera(state.cameras);
          } else if (state is NavigateToSettings) {
            _navigateToSettings();
          }
        },
        child: Scaffold(
          body: CommonWidgets.backgroundGradient(
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return CommonWidgets.loadingIndicator();
                }

                if (state is HomeError) {
                  return CommonWidgets.errorWidget(
                    message: state.message,
                  );
                }

                return PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    HistoryTab(
                      onItemTap: _navigateToHistoryDetail,
                    ),
                    MainTab(
                      homeBloc: _homeBloc,
                    ),
                    const FAQTab(),
                  ],
                );
              },
            ),
          ),
          bottomNavigationBar: CommonWidgets.reverseGradientBackground(
            child: BottomNavigationBar(
              backgroundColor: AppColors.transparent,
              elevation: 0,
              currentIndex: _currentIndex,
              onTap: _onItemTapped,
              selectedItemColor: AppColors.textPrimary,
              unselectedItemColor: AppColors.textSecondary,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'История',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Главная',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.question_answer),
                  label: 'FAQ',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
