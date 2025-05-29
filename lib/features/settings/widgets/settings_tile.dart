// lib/features/settings/widgets/settings_tile.dart
import 'package:flutter/material.dart';

enum SettingsTileType {
  simple,
  switchTile,
  navigation,
  multiChoice,
  slider,
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final SettingsTileType type;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final String? trailing;
  final double? sliderValue;
  final ValueChanged<double>? onSliderChanged;
  final double? sliderMin;
  final double? sliderMax;
  final int? sliderDivisions;
  final Widget? customTrailing;
  final bool isDestructive;
  final bool isDisabled;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.type = SettingsTileType.simple,
    this.onTap,
    this.switchValue,
    this.onSwitchChanged,
    this.trailing,
    this.sliderValue,
    this.onSliderChanged,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
    this.customTrailing,
    this.isDestructive = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = !isDisabled;

    Color? titleColor;
    Color? subtitleColor;
    Color? leadingColor;

    if (isDestructive && isEnabled) {
      titleColor = Colors.red.shade700;
      leadingColor = Colors.red.shade600;
    } else if (!isEnabled) {
      titleColor = Colors.grey.shade400;
      subtitleColor = Colors.grey.shade300;
      leadingColor = Colors.grey.shade300;
    } else {
      titleColor = theme.textTheme.bodyLarge?.color;
      subtitleColor = theme.textTheme.bodySmall?.color;
      leadingColor = iconColor ?? theme.iconTheme.color;
    }

    switch (type) {
      case SettingsTileType.switchTile:
        return _buildSwitchTile(
          theme,
          titleColor,
          subtitleColor,
          leadingColor,
          isEnabled,
        );

      case SettingsTileType.slider:
        return _buildSliderTile(
          theme,
          titleColor,
          subtitleColor,
          leadingColor,
          isEnabled,
        );

      case SettingsTileType.navigation:
      case SettingsTileType.multiChoice:
      case SettingsTileType.simple:
        // FIXED: Entfernt unreachable default case
        return _buildBasicTile(
          theme,
          titleColor,
          subtitleColor,
          leadingColor,
          isEnabled,
        );
    }
  }

  Widget _buildBasicTile(
    ThemeData theme,
    Color? titleColor,
    Color? subtitleColor,
    Color? leadingColor,
    bool isEnabled,
  ) {
    return ListTile(
      enabled: isEnabled,
      onTap: isEnabled ? onTap : null,
      leading: icon != null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (leadingColor ?? theme.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: leadingColor,
                size: 20,
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
            )
          : null,
      trailing: _buildTrailing(theme, isEnabled),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    Color? titleColor,
    Color? subtitleColor,
    Color? leadingColor,
    bool isEnabled,
  ) {
    return SwitchListTile(
      value: switchValue ?? false,
      onChanged: isEnabled ? onSwitchChanged : null,
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                color: subtitleColor,
                fontSize: 12,
              ),
            )
          : null,
      secondary: icon != null
          ? Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (leadingColor ?? theme.primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: leadingColor,
                size: 20,
              ),
            )
          : null,
      activeColor: theme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSliderTile(
    ThemeData theme,
    Color? titleColor,
    Color? subtitleColor,
    Color? leadingColor,
    bool isEnabled,
  ) {
    return Column(
      children: [
        ListTile(
          enabled: isEnabled,
          leading: icon != null
              ? Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (leadingColor ?? theme.primaryColor)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: leadingColor,
                    size: 20,
                  ),
                )
              : null,
          title: Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Text(
            trailing ?? sliderValue?.toStringAsFixed(0) ?? '0',
            style: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: sliderValue ?? 0,
            min: sliderMin ?? 0,
            max: sliderMax ?? 100,
            divisions: sliderDivisions,
            onChanged: isEnabled ? onSliderChanged : null,
            activeColor: theme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget? _buildTrailing(ThemeData theme, bool isEnabled) {
    if (customTrailing != null) {
      return customTrailing;
    }

    switch (type) {
      case SettingsTileType.navigation:
        return Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
        );

      case SettingsTileType.multiChoice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: isEnabled ? theme.primaryColor : Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade300,
            ),
          ],
        );

      case SettingsTileType.simple:
        if (trailing != null) {
          return Text(
            trailing!,
            style: TextStyle(
              color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
              fontSize: 14,
            ),
          );
        }
        return null;

      case SettingsTileType.switchTile:
      case SettingsTileType.slider:
        return null;
    }
  }
}

// Settings Section Widget
class SettingsSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const SettingsSection({
    super.key,
    this.title,
    required this.children,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title!,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: Colors.grey.shade200,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Info Card Widget
class SettingsInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const SettingsInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.1),
                color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: color.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withValues(alpha: 0.5),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
