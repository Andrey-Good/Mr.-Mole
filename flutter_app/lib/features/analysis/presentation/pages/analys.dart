import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mr_mole/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:mr_mole/core/utils/notification.dart';
import 'package:mr_mole/features/home/data/repositories/scan_history_repository.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mr_mole/core/constants/app_colors.dart';

class AnalysisScreen extends StatelessWidget {
  final String imagePath;
  final NotificationService notificationService;
  final VoidCallback onRetake;
  final String? presetMoleLocation;
  final String? replaceHistoryItemId;

  const AnalysisScreen({
    super.key,
    required this.imagePath,
    required this.notificationService,
    required this.onRetake,
    this.presetMoleLocation,
    this.replaceHistoryItemId,
  });

  void _showSaveMoleDialog(BuildContext context, String result) {
    final TextEditingController locationController = TextEditingController(
      text: presetMoleLocation ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: CommonWidgets.titleText(
          'Где находится родинка?',
        ),
        content: TextField(
          controller: locationController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Например: левая рука, спина, лицо...',
            hintStyle: TextStyle(color: AppColors.textForDetail),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textForDetail),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.textForDetail),
            ),
          ),
        ),
        actions: [
          CommonWidgets.commonButton(
            text: 'Отмена',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          CommonWidgets.commonButton(
            text: 'Сохранить',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AnalysisBloc>().add(
                    SaveResultEvent(
                        moleLocation: locationController.text.trim()),
                  );
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (context) => AnalysisBloc(
            imagePath: imagePath,
            notificationService: notificationService,
            historyRepository: ScanHistoryRepository(),
            prefs: snapshot.data!,
            replaceHistoryItemId: replaceHistoryItemId,
          )..add(AnalyzeImageEvent()),
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop) {
                onRetake();
              }
            },
            child: Scaffold(
              backgroundColor: Colors.transparent,
              extendBodyBehindAppBar: true,
              appBar: CommonWidgets.commonAppBar(
                title: 'Анализ родинки',
                onBackPressed: onRetake,
              ),
              body: CommonWidgets.backgroundGradient(
                child: BlocBuilder<AnalysisBloc, AnalysisState>(
                  builder: (context, state) {
                    if (state is AnalysisInitial) {
                      return CommonWidgets.loadingIndicator();
                    }

                    if (state is AnalysisLoading) {
                      return CommonWidgets.loadingIndicator();
                    }

                    if (state is AnalysisSuccess) {
                      return SingleChildScrollView(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top +
                              kToolbarHeight +
                              16,
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CommonWidgets.titleText(state.description),
                            const SizedBox(height: 32),
                            _buildImagePreview(),
                            const SizedBox(height: 32),
                            const Text(
                              'Результат анализа:',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textForDetail,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: CommonWidgets.titleText(
                                state.result,
                              ),
                            ),
                            const SizedBox(height: 32),
                            CommonWidgets.commonButton(
                              text: 'Сохранить результат',
                              onPressed: () {
                                _showSaveMoleDialog(context, state.result);
                              },
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is AnalysisError) {
                      return CommonWidgets.errorWidget(
                        message: state.message,
                      );
                    }

                    return CommonWidgets.loadingIndicator();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePreview() {
    return CommonWidgets.commonImage(
      imagePath: imagePath,
      width: 224,
      height: 224,
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.grey[300],
    );
  }
}
