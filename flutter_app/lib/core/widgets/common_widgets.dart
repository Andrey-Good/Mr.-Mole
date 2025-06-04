import 'package:flutter/material.dart';
import 'package:mr_mole/core/constants/app_colors.dart';
import 'dart:io';

class CommonWidgets {
  static Widget backgroundGradient({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: child,
    );
  }

  static Widget reverseGradientBackground({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.reverseGradient,
      ),
      child: child,
    );
  }

  static AppBar commonAppBar({
    required String title,
    VoidCallback? onBackPressed,
    List<Widget>? actions,
    bool centerTitle = false,
  }) {
    return AppBar(
      backgroundColor: AppColors.transparent,
      elevation: 0,
      centerTitle: centerTitle,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back,
                  color: AppColors.iconPrimary, size: 32),
              onPressed: onBackPressed,
            )
          : null,
      actions: actions,
      iconTheme: const IconThemeData(color: AppColors.iconPrimary),
    );
  }

  static Widget commonCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  static Widget commonButton({
    required String text,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? AppColors.buttonPrimary,
        foregroundColor: textColor ?? AppColors.textSecondary,
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  static Widget loadingIndicator({String? text}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.iconPrimary,
            strokeWidth: 3,
          ),
          if (text != null) ...[
            const SizedBox(height: 16),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  static Widget errorWidget({
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  static Widget titleText(String text, {TextAlign? textAlign}) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  static Widget subtitleText(String text,
      {Color? color, TextAlign? textAlign}) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        color: color ?? AppColors.textForDetail,
      ),
    );
  }

  static Widget commonIcon(IconData icon, {double? size}) {
    return Icon(
      icon,
      color: AppColors.iconPrimary,
      size: size ?? 24,
    );
  }

  static Widget commonImage({
    required String imagePath,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Color? backgroundColor,
    IconData fallbackIcon = Icons.image_not_supported,
    IconData errorIcon = Icons.error,
    double iconSize = 48,
    Color iconColor = Colors.white70,
  }) {
    Widget buildFallback(IconData icon) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.cardBackground,
          borderRadius: borderRadius,
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: iconColor,
        ),
      );
    }

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        return buildFallback(fallbackIcon);
      }

      Widget imageWidget = Image.file(
        file,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return buildFallback(errorIcon);
        },
      );

      if (borderRadius != null) {
        imageWidget = ClipRRect(
          borderRadius: borderRadius,
          child: imageWidget,
        );
      }

      return imageWidget;
    } catch (e) {
      return buildFallback(errorIcon);
    }
  }
}
