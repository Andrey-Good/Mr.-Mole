import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mr_mole/features/home/domain/models/scan_history_item.dart';
import 'package:mr_mole/features/home/presentation/bloc/history_bloc.dart';
import 'package:mr_mole/features/home/data/repositories/scan_history_repository.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class HistoryTab extends StatefulWidget {
  final Function(ScanHistoryItem)? onItemTap;
  final ScanHistoryRepository? repository;

  const HistoryTab({
    super.key,
    this.onItemTap,
    this.repository,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late HistoryBloc _historyBloc;
  late ScanHistoryRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? ScanHistoryRepository();
    _historyBloc = HistoryBloc(_repository)..add(LoadHistoryEvent());
  }

  @override
  void dispose() {
    _historyBloc.close();
    super.dispose();
  }

  void _showDeleteConfirmationDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: CommonWidgets.titleText(
          'Удаление записи',
        ),
        content: CommonWidgets.subtitleText(
          'Вы уверены, что хотите удалить эту запись из истории?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CommonWidgets.commonButton(
                  text: 'Отмена',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonWidgets.commonButton(
                  text: 'Удалить',
                  onPressed: () {
                    _historyBloc.add(RemoveHistoryItemEvent(id));
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteAllHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: CommonWidgets.titleText(
          'Очистка истории',
        ),
        content: CommonWidgets.subtitleText(
          'Вы уверены, что хотите удалить всю историю сканирований?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: CommonWidgets.commonButton(
                  text: 'Отмена',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CommonWidgets.commonButton(
                  text: 'Очистить',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  onPressed: () {
                    _historyBloc.add(ClearHistoryEvent());
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, ScanHistoryItem item) {
    if (widget.onItemTap != null) {
      widget.onItemTap!(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocProvider.value(
        value: _historyBloc,
        child: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (context, state) {
            if (state is HistoryInitial || state is HistoryLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is HistoryError) {
              return CommonWidgets.errorWidget(
                message: state.message,
              );
            }

            if (state is HistoryEmpty) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: CommonWidgets.titleText(
                            'История сканирования',
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'История пуста',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Здесь будут отображаться ваши сканирования',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (state is HistoryLoaded) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: CommonWidgets.titleText(
                            'История сканирования',
                            textAlign: TextAlign.left,
                          ),
                        ),
                        CommonWidgets.commonButton(
                          text: 'Очистить',
                          onPressed: () => _showDeleteAllHistoryDialog(context),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return HistoryItemCard(
                          item: item,
                          onTap: () => _navigateToDetail(context, item),
                          onDelete: () =>
                              _showDeleteConfirmationDialog(context, item.id),
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text('Неизвестное состояние'),
            );
          },
        ),
      ),
    );
  }
}

class HistoryItemCard extends StatelessWidget {
  final ScanHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const HistoryItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final bool isHighRisk = item.result.toLowerCase().contains('высокая');
    final bool isMediumRisk = item.result.toLowerCase().contains('возможны');

    final Color statusColor = isHighRisk
        ? AppColors.riskHigh
        : isMediumRisk
            ? AppColors.riskMedium
            : AppColors.riskLow;

    return CommonWidgets.commonCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Место:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textForDetail,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.moleLocation ?? 'Не указано',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Результат:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textForDetail,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.result,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Дата:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textForDetail,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(item.timestamp),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                CommonWidgets.commonImage(
                  imagePath: item.imagePath,
                  width: 80,
                  height: 80,
                  borderRadius: BorderRadius.circular(8),
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: onDelete,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
