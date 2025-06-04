import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mr_mole/features/home/domain/models/scan_history_item.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';
import 'package:mr_mole/core/constants/app_colors.dart';

class HistoryDetailPage extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback? onRescanPressed;

  const HistoryDetailPage({
    super.key,
    required this.item,
    this.onRescanPressed,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd MMMM yyyy', 'ru_RU').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighRisk =
        item.result.toLowerCase().contains('высокая вероятность') ||
            item.result.toLowerCase().contains('срочно');
    final bool isMediumRisk = item.result.toLowerCase().contains('возможны') ||
        item.result.toLowerCase().contains('рекомендуется консультация');

    final Color statusColor = isHighRisk
        ? AppColors.riskHigh
        : isMediumRisk
            ? AppColors.riskMedium
            : AppColors.riskLow;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: CommonWidgets.commonAppBar(
        title: 'Детали сканирования',
      ),
      body: CommonWidgets.backgroundGradient(
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CommonWidgets.commonImage(
                    imagePath: item.imagePath,
                    width: 240,
                    height: 240,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Результат анализа:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textForDetail,
                ),
              ),
              CommonWidgets.commonCard(
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.result,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Место родинки:',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textForDetail,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.moleLocation ?? 'Место не указано',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Дата сканирования:',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textForDetail,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(item.timestamp),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: CommonWidgets.commonButton(
                  text: 'Сканировать снова',
                  onPressed: onRescanPressed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
