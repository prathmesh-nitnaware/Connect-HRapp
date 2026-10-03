import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (label.toLowerCase()) {
      case 'pending':
        bg = AppColors.warningContainer;
        fg = AppColors.onWarningContainer;
        break;
      case 'approved':
      case 'present':
        bg = AppColors.successContainer;
        fg = AppColors.onSuccessContainer;
        break;
      case 'rejected':
      case 'absent':
        bg = AppColors.errorContainer;
        fg = AppColors.onErrorContainer;
        break;
      case 'hr':
        bg = const Color(0xFFCCFBF1);
        fg = AppColors.teal700;
        break;
      default:
        bg = Theme.of(context).colorScheme.primaryContainer;
        fg = Theme.of(context).colorScheme.onPrimaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
