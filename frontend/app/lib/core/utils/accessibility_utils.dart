import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Comprehensive accessibility utilities for the VoteReady app
/// Ensures WCAG 2.1 AA compliance and Indian government accessibility standards

class AccessibilityUtils {
  /// Semantic labels for common UI elements
  static const Map<String, String> semanticLabels = {
    'logo': 'VoteReady app logo',
    'backButton': 'Go back',
    'closeButton': 'Close',
    'menuButton': 'Open menu',
    'submitButton': 'Submit',
    'cancelButton': 'Cancel',
    'loading': 'Loading content, please wait',
    'error': 'Error occurred',
    'success': 'Success',
    'phoneField': 'Phone number input field',
    'ageField': 'Age input field',
    'stateDropdown': 'State selection dropdown',
    'aadhaarField': 'Aadhaar number input field',
    'otpField': 'One time password input field',
    'verifyButton': 'Verify identity',
    'scanDocument': 'Scan document using camera',
    'uploadDocument': 'Upload document from device',
    'readinessScore': 'Voter readiness score',
    'pollingStation': 'Polling station information',
    'electionDate': 'Election date countdown',
    'voterId': 'Voter ID card information',
  };

  /// High contrast color schemes for accessibility
  static ColorScheme getHighContrastScheme(bool isDark) {
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFF1A73E8),
      brightness: isDark ? Brightness.dark : Brightness.light,
      contrastLevel: 1.0,
    );
  }

  /// Check if color contrast meets WCAG AA standards (4.5:1 for normal text)
  static bool meetsContrastRequirement(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    final contrast = (lighter + 0.05) / (darker + 0.05);
    return contrast >= 4.5;
  }

  /// Get adjusted color for better contrast
  static Color ensureContrast(Color foreground, Color background) {
    if (meetsContrastRequirement(foreground, background)) {
      return foreground;
    }
    final backgroundLuminance = background.computeLuminance();
    return backgroundLuminance > 0.5 ? Colors.black : Colors.white;
  }

  /// Announce message to screen readers
  static void announceToScreenReader(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, Directionality.of(context));
  }

  /// Request focus for accessibility
  static void requestFocus(FocusNode node) {
    node.requestFocus();
  }

  /// Get text scale factor with clamping for accessibility
  static double getAccessibleTextScaleFactor(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScale = mediaQuery.textScaler;
    // Clamp between 0.8 and 2.0 to prevent layout issues
    final scale = textScale.scale(1.0);
    return scale.clamp(0.8, 2.0);
  }

  /// Check if reduce motion is enabled
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get duration respecting reduced motion preferences
  static Duration getAnimationDuration(
    BuildContext context, {
    Duration normal = const Duration(milliseconds: 300),
    Duration reduced = const Duration(milliseconds: 50),
  }) {
    return shouldReduceMotion(context) ? reduced : normal;
  }

  /// Build semantic wrapper for buttons
  static Widget semanticButton({
    required Widget child,
    required String label,
    String? hint,
    bool isEnabled = true,
    VoidCallback? onTap,
  }) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      hint: hint,
      onTap: onTap,
      child: child,
    );
  }

  /// Build semantic wrapper for input fields
  static Widget semanticInput({
    required Widget child,
    required String label,
    String? hint,
    String? error,
    bool isRequired = false,
  }) {
    return Semantics(
      textField: true,
      label: '$label${isRequired ? " (Required)" : ""}',
      hint: hint,
      onTap: () {},
      child: child,
    );
  }

  /// Build semantic wrapper for images
  static Widget semanticImage({
    required Widget child,
    required String label,
    bool isDecorative = false,
  }) {
    if (isDecorative) {
      return Semantics(
        image: true,
        label: label,
        child: ExcludeSemantics(child: child),
      );
    }
    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }

  /// Build heading semantics
  static Widget semanticHeading({
    required Widget child,
    required int level, // 1-6
  }) {
    return Semantics(
      header: true,
      child: child,
    );
  }

  /// Create a live region for dynamic content updates
  static Widget liveRegion({
    required Widget child,
    bool polite = true,
  }) {
    return Semantics(
      liveRegion: polite,
      child: child,
    );
  }

  /// Minimum touch target size (48x48dp as per WCAG and Material Design)
  static const double minTouchTargetSize = 48.0;

  /// Ensure minimum touch target size
  static Widget ensureMinimumTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }
}

/// Extension for easy color with values (replaces deprecated withOpacity)
extension ColorWithValues on Color {
  /// Returns color with specific alpha value (0-255)
  Color withAlphaValue(int alpha) {
    return withAlpha(alpha);
  }

  /// Returns color with specific opacity value (0.0-1.0)
  Color withOpacityValue(double opacity) {
    return withValues(alpha: opacity);
  }
}

