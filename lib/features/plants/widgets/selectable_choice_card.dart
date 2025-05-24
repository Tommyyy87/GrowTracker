// lib/features/plants/widgets/selectable_choice_card.dart
import 'package:flutter/material.dart';
import 'package:grow_tracker/core/constants/app_colors.dart';

class SelectableChoiceCard<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final String label;
  final IconData? icon;
  final String? subtitle; // Optionaler Untertitel für mehr Kontext

  const SelectableChoiceCard({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;
    final Color selectedColor = AppColors.primaryColor;
    final Color unselectedColor = Colors.grey.shade700;
    final Color unselectedBackgroundColor = Colors.grey.shade50;
    final Color selectedTextColor = Colors.white;
    final Color unselectedTextColor = Colors.black87;

    // Umrechnung von Opacity (0.0 - 1.0) zu Alpha (0 - 255)
    final int selectedBorderAlpha = (0.7 * 255).round();
    final int subtitleSelectedTextAlpha = (0.8 * 255).round();
    final int subtitleUnselectedTextAlpha = (0.7 * 255).round();

    return Card(
      elevation: isSelected ? 4.0 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: isSelected
              ? selectedColor.withAlpha(selectedBorderAlpha)
              : Colors.grey.shade300,
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      color: isSelected ? selectedColor : unselectedBackgroundColor,
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? selectedTextColor : unselectedColor,
                ),
              if (icon != null) const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: isSelected ? selectedTextColor : unselectedTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? selectedTextColor.withAlpha(subtitleSelectedTextAlpha)
                        : unselectedTextColor
                            .withAlpha(subtitleUnselectedTextAlpha),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
