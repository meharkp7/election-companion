import 'package:flutter/material.dart';
import '../../core/utils/accessibility_utils.dart';

/// Accessible button with semantic labels and proper touch targets
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;

  const AccessibleButton({
    super.key,
    required this.label,
    this.semanticLabel,
    this.hint,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                AccessibilityUtils.minTouchTargetSize * 4,
                AccessibilityUtils.minTouchTargetSize,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      )
                    : Text(label),
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(
                AccessibilityUtils.minTouchTargetSize * 4,
                AccessibilityUtils.minTouchTargetSize,
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 20),
                          const SizedBox(width: 8),
                          Text(label),
                        ],
                      )
                    : Text(label),
          );

    return AccessibilityUtils.semanticButton(
      child: button,
      label: semanticLabel ?? label,
      hint: hint,
      isEnabled: onPressed != null && !isLoading,
      onTap: onPressed,
    );
  }
}

/// Accessible text field with proper labels and hints
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final bool obscureText;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.keyboardType,
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.semanticInput(
      label: label,
      hint: hint,
      error: errorText,
      isRequired: isRequired,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        maxLength: maxLength,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: '$label${isRequired ? " *" : ""}',
          hintText: hint,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Accessible card with semantic container
class AccessibleCard extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;

  const AccessibleCard({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: backgroundColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    return Semantics(
      container: true,
      label: label,
      button: onTap != null,
      onTap: onTap,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: card,
            )
          : card,
    );
  }
}

/// Accessible heading with proper header semantics
class AccessibleHeading extends StatelessWidget {
  final String text;
  final int level; // 1-6
  final TextStyle? style;

  const AccessibleHeading(
    this.text, {
    super.key,
    this.level = 1,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? _getDefaultStyle(context, level);

    return AccessibilityUtils.semanticHeading(
      level: level,
      child: Text(
        text,
        style: textStyle,
      ),
    );
  }

  TextStyle _getDefaultStyle(BuildContext context, int level) {
    final baseStyle = Theme.of(context).textTheme;
    switch (level) {
      case 1:
        return baseStyle.headlineLarge!;
      case 2:
        return baseStyle.headlineMedium!;
      case 3:
        return baseStyle.headlineSmall!;
      case 4:
        return baseStyle.titleLarge!;
      case 5:
        return baseStyle.titleMedium!;
      case 6:
      default:
        return baseStyle.titleSmall!;
    }
  }
}

/// Accessible progress indicator with live region
class AccessibleProgress extends StatelessWidget {
  final String label;
  final double? value;
  final String? valueLabel;

  const AccessibleProgress({
    super.key,
    required this.label,
    this.value,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      value: valueLabel ?? '${((value ?? 0) * 100).toInt()}%',
      child: LinearProgressIndicator(
        value: value,
        semanticsLabel: label,
      ),
    );
  }
}

/// Accessible icon button with tooltip and semantic label
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? color;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.ensureMinimumTouchTarget(
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        tooltip: label,
      ),
    );
  }
}

/// Accessible image with proper alt text
class AccessibleImage extends StatelessWidget {
  final String imageUrl;
  final String altText;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final bool isDecorative;

  const AccessibleImage({
    super.key,
    required this.imageUrl,
    required this.altText,
    this.width,
    this.height,
    this.fit,
    this.isDecorative = false,
  });

  @override
  Widget build(BuildContext context) {
    return AccessibilityUtils.semanticImage(
      label: altText,
      isDecorative: isDecorative,
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}

/// Accessible switch with proper labels
class AccessibleSwitch extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AccessibleSwitch({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      toggled: value,
      child: SwitchListTile(
        title: Text(label),
        subtitle: hint != null ? Text(hint!) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// Accessible checkbox with proper labels
class AccessibleCheckbox extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AccessibleCheckbox({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      checked: value,
      child: CheckboxListTile(
        title: Text(label),
        subtitle: hint != null ? Text(hint!) : null,
        value: value,
        onChanged: onChanged != null ? (v) => onChanged!(v ?? false) : null,
      ),
    );
  }
}

/// Accessible alert/live region for dynamic updates
class AccessibleAlert extends StatelessWidget {
  final String message;
  final AlertType type;
  final bool isLiveRegion;

  const AccessibleAlert({
    super.key,
    required this.message,
    this.type = AlertType.info,
    this.isLiveRegion = true,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getAlertStyles(type);

    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
        ],
      ),
    );

    if (isLiveRegion) {
      content = AccessibilityUtils.liveRegion(
        polite: true,
        child: content,
      );
    }

    return Semantics(
      label: '${type.name} alert: $message',
      child: content,
    );
  }

  (IconData, Color) _getAlertStyles(AlertType type) {
    switch (type) {
      case AlertType.success:
        return (Icons.check_circle, Colors.green);
      case AlertType.warning:
        return (Icons.warning, Colors.orange);
      case AlertType.error:
        return (Icons.error, Colors.red);
      case AlertType.info:
        return (Icons.info, Colors.blue);
    }
  }
}

enum AlertType { success, warning, error, info }
