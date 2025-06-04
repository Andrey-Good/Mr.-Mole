import 'package:flutter/material.dart';
import 'package:mr_mole/features/camera/presentation/constants/camera_constants.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'package:mr_mole/core/widgets/common_widgets.dart';

class InstructionOverlay extends StatelessWidget {
  final VoidCallback onClose;

  const InstructionOverlay({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.overlayDark,
        child: Center(
          child: CommonWidgets.commonCard(
            backgroundColor: AppColors.instructionBackground,
            margin: EdgeInsets.symmetric(
              horizontal: screenSize.width *
                  (1 - CameraConstants.instructionWidthPercent) /
                  2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CommonWidgets.commonIcon(Icons.camera_alt),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonWidgets.titleText(
                        'Как сделать снимок родинки',
                        textAlign: TextAlign.left,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: CommonWidgets.commonIcon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const InstructionStep(
                  icon: Icons.center_focus_strong,
                  text: 'Поместите родинку в белую рамку',
                ),
                const SizedBox(height: 16),
                const InstructionStep(
                  icon: Icons.wb_sunny,
                  text: 'Обеспечьте хорошее освещение',
                ),
                const SizedBox(height: 16),
                const InstructionStep(
                  icon: Icons.straighten,
                  text: 'Держите камеру на расстоянии 10-15 см',
                ),
                const SizedBox(height: 16),
                const InstructionStep(
                  icon: Icons.photo_size_select_actual,
                  text: 'Родинка должна полностью помещаться в рамку',
                ),
                const SizedBox(height: 16),
                const InstructionStep(
                  icon: Icons.camera,
                  text: 'Нажмите белую кнопку для съемки',
                ),
                const SizedBox(height: 24),
                CommonWidgets.commonButton(
                  text: 'Понятно',
                  onPressed: onClose,
                  backgroundColor: AppColors.cardBackground,
                  textColor: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class InstructionStep extends StatelessWidget {
  final IconData icon;
  final String text;

  const InstructionStep({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CommonWidgets.commonIcon(icon),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: CameraConstants.instructionFontSize,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
