import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AppPanel extends StatelessWidget {
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.emphasized = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized ? scheme.primaryContainer : scheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasized
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.outlineVariant.withValues(alpha: 0.58),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (emphasized ? scheme.primary : scheme.shadow).withValues(
              alpha: emphasized ? 0.12 : 0.075,
            ),
            blurRadius: emphasized ? 26 : 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.selected = false});

  final List<List<dynamic>> icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: 44,
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
          size: selected ? 30 : 28,
        ),
      ),
    );
  }
}

class AppHugeIcon extends StatelessWidget {
  const AppHugeIcon(this.icon, {super.key, this.size = 22, this.color});

  final List<List<dynamic>> icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(icon: icon, size: size, color: color);
  }
}

class AppPrefixIcon extends StatelessWidget {
  const AppPrefixIcon(this.icon, {super.key});

  final List<List<dynamic>> icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      widthFactor: 1,
      heightFactor: 1,
      child: HugeIcon(
        icon: icon,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class AppFlatActionButton extends StatelessWidget {
  const AppFlatActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.prominent = false,
    this.danger = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onPressed;
  final bool prominent;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final foreground = danger
        ? scheme.error
        : prominent
        ? scheme.primary
        : scheme.onSurface;
    final background = danger
        ? scheme.errorContainer.withValues(alpha: 0.62)
        : prominent
        ? scheme.primaryContainer.withValues(alpha: 0.78)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.62);
    return FilledButton.icon(
      onPressed: onPressed,
      icon: HugeIcon(
        icon: icon,
        size: 20,
        color: enabled ? foreground : scheme.onSurfaceVariant,
      ),
      label: FittedBox(child: Text(label)),
      style: FilledButton.styleFrom(
        backgroundColor: enabled
            ? background
            : scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        foregroundColor: enabled
            ? foreground
            : scheme.onSurfaceVariant.withValues(alpha: 0.62),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
