import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mr_mole/features/settings/presentation/bloc/settings_bloc.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<SharedPreferences> _prefsFuture;

  @override
  void initState() {
    super.initState();
    _prefsFuture = SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _prefsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: CommonWidgets.loadingIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: CommonWidgets.errorWidget(
              message: 'Ошибка: ${snapshot.error}',
            ),
          );
        }

        return BlocProvider(
          create: (context) =>
              SettingsBloc(snapshot.data!)..add(LoadSettingsEvent()),
          child: Scaffold(
            backgroundColor: AppColors.transparent,
            extendBodyBehindAppBar: true,
            appBar: CommonWidgets.commonAppBar(
              title: 'Настройки',
              onBackPressed: () => Navigator.pop(context),
            ),
            body: CommonWidgets.backgroundGradient(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  if (state is SettingsLoading) {
                    return CommonWidgets.loadingIndicator();
                  }

                  if (state is SettingsError) {
                    return CommonWidgets.errorWidget(
                      message: state.message,
                    );
                  }

                  if (state is SettingsLoaded) {
                    return ListView(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16,
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0,
                      ),
                      children: [
                        _buildNotificationsSection(context, state),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsSection(
      BuildContext context, SettingsLoaded state) {
    return CommonWidgets.commonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Настройка уведомлений
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonWidgets.subtitleText(
                'Уведомления',
                textAlign: TextAlign.left,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CommonWidgets.commonIcon(Icons.notifications),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Включить напоминания о проверке',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: AppColors.textForDetail,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Switch(
                    value: state.notificationsEnabled,
                    onChanged: (value) {
                      context
                          .read<SettingsBloc>()
                          .add(UpdateNotificationsEvent(value));
                    },
                    activeColor: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),

          if (state.notificationsEnabled) ...[
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommonWidgets.subtitleText(
                  'Интервал напоминаний',
                  textAlign: TextAlign.left,
                  color: AppColors.textPrimary,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CommonWidgets.commonIcon(Icons.timer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.buttonPrimary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CupertinoPicker(
                          backgroundColor: AppColors.transparent,
                          itemExtent: 40.0,
                          scrollController: FixedExtentScrollController(
                            initialItem: state.notificationDurationMonths - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            final durationValues = [
                              1,
                              2,
                              3,
                              4,
                              5,
                              6,
                              7,
                              8,
                              9,
                              10,
                              11,
                              12
                            ];
                            context.read<SettingsBloc>().add(
                                  UpdateNotificationsEvent(
                                    state.notificationsEnabled,
                                    durationMonths: durationValues[index],
                                  ),
                                );
                          },
                          children: _getDurationLabels()
                              .map((duration) => Center(
                                    child: CommonWidgets.subtitleText(
                                      duration,
                                      color: AppColors.textSecondary,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getDurationLabels() {
    return [
      '1 месяц',
      '2 месяца',
      '3 месяца',
      '4 месяца',
      '5 месяцев',
      '6 месяцев',
      '7 месяцев',
      '8 месяцев',
      '9 месяцев',
      '10 месяцев',
      '11 месяцев',
      '1 год'
    ];
  }
}
