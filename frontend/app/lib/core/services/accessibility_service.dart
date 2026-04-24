import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccessibilityFeature {
  highContrast,
  largeText,
  screenReader,
  reducedMotion,
  colorBlindFriendly,
  voiceNavigation,
}

class AccessibilitySettings {
  final Map<AccessibilityFeature, bool> features;
  final double textScaleFactor;
  final double fontSizeMultiplier;

  const AccessibilitySettings({
    required this.features,
    this.textScaleFactor = 1.0,
    this.fontSizeMultiplier = 1.0,
  });

  AccessibilitySettings copyWith({
    Map<AccessibilityFeature, bool>? features,
    double? textScaleFactor,
    double? fontSizeMultiplier,
  }) {
    return AccessibilitySettings(
      features: features ?? this.features,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      fontSizeMultiplier: fontSizeMultiplier ?? this.fontSizeMultiplier,
    );
  }

  bool isFeatureEnabled(AccessibilityFeature feature) {
    return features[feature] ?? false;
  }
}

class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  AccessibilitySettings _settings = const AccessibilitySettings(
    features: {
      AccessibilityFeature.highContrast: false,
      AccessibilityFeature.largeText: false,
      AccessibilityFeature.screenReader: false,
      AccessibilityFeature.reducedMotion: false,
      AccessibilityFeature.colorBlindFriendly: false,
      AccessibilityFeature.voiceNavigation: false,
    },
  );

  AccessibilitySettings get settings => _settings;

  Future<void> initialize() async {
    await _loadSettings();
    _detectSystemAccessibility();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final features = <AccessibilityFeature, bool>{};
      for (final feature in AccessibilityFeature.values) {
        final isEnabled =
            prefs.getBool('accessibility_${feature.name}') ?? false;
        features[feature] = isEnabled;
      }

      final textScaleFactor =
          prefs.getDouble('accessibility_text_scale') ?? 1.0;
      final fontSizeMultiplier =
          prefs.getDouble('accessibility_font_multiplier') ?? 1.0;

      _settings = AccessibilitySettings(
        features: features,
        textScaleFactor: textScaleFactor,
        fontSizeMultiplier: fontSizeMultiplier,
      );
    } catch (e) {
      debugPrint('Failed to load accessibility settings: $e');
    }
  }

  Future<void> _detectSystemAccessibility() async {
    // Detect system accessibility features
    final mediaQueryData = MediaQueryData.fromView(
        WidgetsBinding.instance.platformDispatcher.views.first);

    // Check for large text
    if (mediaQueryData.textScaler.scale(1.0) > 1.0) {
      await enableFeature(AccessibilityFeature.largeText);
      _settings = _settings.copyWith(
          textScaleFactor: mediaQueryData.textScaler.scale(1.0));
    }

    // Check for high contrast (platform-specific)
    // This would need platform-specific implementation
  }

  Future<void> enableFeature(AccessibilityFeature feature) async {
    final updatedFeatures =
        Map<AccessibilityFeature, bool>.from(_settings.features);
    updatedFeatures[feature] = true;

    _settings = _settings.copyWith(features: updatedFeatures);
    await _saveSettings();
  }

  Future<void> disableFeature(AccessibilityFeature feature) async {
    final updatedFeatures =
        Map<AccessibilityFeature, bool>.from(_settings.features);
    updatedFeatures[feature] = false;

    _settings = _settings.copyWith(features: updatedFeatures);
    await _saveSettings();
  }

  Future<void> setTextScaleFactor(double scaleFactor) async {
    _settings = _settings.copyWith(textScaleFactor: scaleFactor);
    await _saveSettings();
  }

  Future<void> setFontSizeMultiplier(double multiplier) async {
    _settings = _settings.copyWith(fontSizeMultiplier: multiplier);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      for (final entry in _settings.features.entries) {
        await prefs.setBool('accessibility_${entry.key.name}', entry.value);
      }

      await prefs.setDouble(
          'accessibility_text_scale', _settings.textScaleFactor);
      await prefs.setDouble(
          'accessibility_font_multiplier', _settings.fontSizeMultiplier);
    } catch (e) {
      debugPrint('Failed to save accessibility settings: $e');
    }
  }

  // Accessibility utilities
  bool shouldUseHighContrast() {
    return _settings.isFeatureEnabled(AccessibilityFeature.highContrast);
  }

  bool shouldUseLargeText() {
    return _settings.isFeatureEnabled(AccessibilityFeature.largeText);
  }

  bool shouldReduceMotion() {
    return _settings.isFeatureEnabled(AccessibilityFeature.reducedMotion);
  }

  bool isColorBlindFriendly() {
    return _settings.isFeatureEnabled(AccessibilityFeature.colorBlindFriendly);
  }

  double getTextScaleFactor() {
    return _settings.textScaleFactor;
  }

  double getFontSizeMultiplier() {
    return _settings.fontSizeMultiplier;
  }

  // Color adjustments for accessibility
  Color adjustColorForAccessibility(Color color) {
    if (shouldUseHighContrast()) {
      // Convert to high contrast colors
      final luminance = color.computeLuminance();
      return luminance > 0.5 ? Colors.black : Colors.white;
    }

    if (isColorBlindFriendly()) {
      // Adjust colors for color blindness
      return _adjustForColorBlindness(color);
    }

    return color;
  }

  Color _adjustForColorBlindness(Color color) {
    // Simple color blind friendly adjustments
    // In a real implementation, you'd want more sophisticated color mapping
    final red = (color.r * 255.0).round().clamp(0, 255);
    final green = (color.g * 255.0).round().clamp(0, 255);
    final blue = (color.b * 255.0).round().clamp(0, 255);

    // Convert to grayscale for red-green color blindness
    final gray = (0.299 * red + 0.587 * green + 0.114 * blue).round();
    return Color.fromARGB(
        (color.a * 255.0).round().clamp(0, 255), gray, gray, blue);
  }

  // Text adjustments
  TextStyle adjustTextStyleForAccessibility(TextStyle textStyle) {
    double fontSize = textStyle.fontSize ?? 14.0;
    fontSize *= _settings.fontSizeMultiplier;

    return textStyle.copyWith(
      fontSize: fontSize,
      height: shouldUseLargeText() ? 1.5 : textStyle.height,
      letterSpacing: shouldUseLargeText() ? 0.5 : textStyle.letterSpacing,
    );
  }

  // Semantic labels and announcements
  void announceForAccessibility(BuildContext context, String message) {
    if (_settings.isFeatureEnabled(AccessibilityFeature.screenReader)) {
      // ignore: deprecated_member_use
      SemanticsService.announce(message, TextDirection.ltr);
    }
  }

  // Focus management
  void requestFocus(BuildContext context, FocusNode focusNode) {
    if (_settings.isFeatureEnabled(AccessibilityFeature.screenReader)) {
      focusNode.requestFocus();
    }
  }

  // Navigation helpers
  void handleAccessibilityNavigation(BuildContext context, KeyEvent event) {
    if (!_settings.isFeatureEnabled(AccessibilityFeature.voiceNavigation)) {
      return;
    }

    // Handle voice navigation commands
    switch (event.logicalKey.keyLabel) {
      case 'Arrow Up':
      case 'Arrow Down':
      case 'Arrow Left':
      case 'Arrow Right':
        // Handle directional navigation
        break;
      case 'Enter':
      case 'Space':
        // Handle activation
        break;
    }
  }
}

// Accessibility-aware widgets
class AccessibleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? hint;
  final bool isSemanticButton;

  const AccessibleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.semanticLabel,
    this.hint,
    this.isSemanticButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: isSemanticButton,
      label: semanticLabel,
      hint: hint,
      enabled: onPressed != null,
      child: GestureDetector(
        onTap: onPressed,
        child: child,
      ),
    );
  }
}

class AccessibleText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final String? semanticLabel;
  final TextAlign? textAlign;

  const AccessibleText({
    super.key,
    required this.text,
    this.style,
    this.semanticLabel,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final accessibilityService = AccessibilityService();
    final adjustedStyle = accessibilityService.adjustTextStyleForAccessibility(
      style ?? const TextStyle(),
    );

    return Semantics(
      label: semanticLabel ?? text,
      child: Text(
        text,
        style: adjustedStyle,
        textAlign: textAlign,
      ),
    );
  }
}

class AccessibleCard extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? hint;
  final VoidCallback? onTap;

  const AccessibleCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.hint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: hint,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

// Accessibility settings screen
class AccessibilitySettingsScreen extends ConsumerStatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  ConsumerState<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState
    extends ConsumerState<AccessibilitySettingsScreen> {
  late AccessibilityService _accessibilityService;

  @override
  void initState() {
    super.initState();
    _accessibilityService = AccessibilityService();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Accessibility Features',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...AccessibilityFeature.values.map((feature) {
            return SwitchListTile(
              title: Text(_getFeatureTitle(feature)),
              subtitle: Text(_getFeatureDescription(feature)),
              value: _accessibilityService.settings.isFeatureEnabled(feature),
              onChanged: (value) {
                setState(() {
                  if (value) {
                    _accessibilityService.enableFeature(feature);
                  } else {
                    _accessibilityService.disableFeature(feature);
                  }
                });
              },
            );
          }),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Text Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Text Scale'),
            subtitle: Slider(
              value: _accessibilityService.settings.textScaleFactor,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              onChanged: (value) {
                setState(() {
                  _accessibilityService.setTextScaleFactor(value);
                });
              },
            ),
          ),
          ListTile(
            title: const Text('Font Size Multiplier'),
            subtitle: Slider(
              value: _accessibilityService.settings.fontSizeMultiplier,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              onChanged: (value) {
                setState(() {
                  _accessibilityService.setFontSizeMultiplier(value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getFeatureTitle(AccessibilityFeature feature) {
    switch (feature) {
      case AccessibilityFeature.highContrast:
        return 'High Contrast';
      case AccessibilityFeature.largeText:
        return 'Large Text';
      case AccessibilityFeature.screenReader:
        return 'Screen Reader';
      case AccessibilityFeature.reducedMotion:
        return 'Reduced Motion';
      case AccessibilityFeature.colorBlindFriendly:
        return 'Color Blind Friendly';
      case AccessibilityFeature.voiceNavigation:
        return 'Voice Navigation';
    }
  }

  String _getFeatureDescription(AccessibilityFeature feature) {
    switch (feature) {
      case AccessibilityFeature.highContrast:
        return 'Increase contrast for better visibility';
      case AccessibilityFeature.largeText:
        return 'Increase text size for better readability';
      case AccessibilityFeature.screenReader:
        return 'Enable screen reader support';
      case AccessibilityFeature.reducedMotion:
        return 'Reduce animations and transitions';
      case AccessibilityFeature.colorBlindFriendly:
        return 'Adjust colors for color blindness';
      case AccessibilityFeature.voiceNavigation:
        return 'Enable voice navigation commands';
    }
  }
}

// Accessibility provider for Riverpod
final accessibilityServiceProvider = Provider<AccessibilityService>((ref) {
  return AccessibilityService();
});
