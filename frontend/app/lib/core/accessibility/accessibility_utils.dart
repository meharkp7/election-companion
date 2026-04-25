/// Accessibility utilities for VoteReady.
///
/// Centralises WCAG 2.1 AA helpers so every screen uses consistent patterns
/// rather than ad-hoc Semantics wrappers.
///
/// Usage:
/// ```dart
/// // Wrap a screen body for route announcement
/// AccessibilityUtils.screenWrapper(
///   label: 'Voter registration screen',
///   child: ...,
/// )
///
/// // Wrap a button with minimum touch target
/// AccessibilityUtils.touchTarget(child: IconButton(...))
///
/// // Announce a dynamic message to screen readers
/// AccessibilityUtils.announce(context, 'Your vote has been recorded');
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

abstract class AccessibilityUtils {
  // ── Minimum touch target (WCAG 2.5.5: 44×44 CSS px ≈ 48×48 dp) ──────────

  /// Wraps [child] in a [ConstrainedBox] that enforces the WCAG minimum
  /// touch target of 48×48 dp.
  static Widget touchTarget({required Widget child}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: child,
    );
  }

  // ── Route / screen announcement ───────────────────────────────────────────

  /// Wraps a screen body so TalkBack / VoiceOver announces the screen name
  /// when the user navigates to it.
  ///
  /// [label] should be a short, human-readable description of the screen,
  /// e.g. `'Voter eligibility check screen'`.
  static Widget screenWrapper({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      label: label,
      child: child,
    );
  }

  // ── Decorative content ────────────────────────────────────────────────────

  /// Marks [child] as purely decorative so screen readers skip it.
  /// Use for emoji, background illustrations, and icon-only decorations
  /// where the surrounding text already conveys the meaning.
  static Widget decorative({required Widget child}) {
    return ExcludeSemantics(child: child);
  }

  // ── Live regions ──────────────────────────────────────────────────────────

  /// Wraps [child] in a live region so TalkBack / VoiceOver announces
  /// content changes without the user navigating to the widget.
  ///
  /// Use for: error messages, status updates, AI assistant replies.
  static Widget liveRegion({
    required Widget child,
    String? label,
  }) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: child,
    );
  }

  // ── Programmatic announcements ────────────────────────────────────────────

  /// Announces [message] to the platform accessibility service immediately.
  ///
  /// Use when a state change happens without a visible widget update,
  /// e.g. after a background API call completes.
  static void announce(BuildContext context, String message) {
    // ignore: deprecated_member_use
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // ── Heading ───────────────────────────────────────────────────────────────

  /// Marks [child] as a heading so screen reader users can jump between
  /// sections using the "next heading" gesture.
  static Widget heading({required Widget child, String? label}) {
    return Semantics(
      header: true,
      label: label,
      child: child,
    );
  }

  // ── Button ────────────────────────────────────────────────────────────────

  /// Wraps [child] with button semantics and an accessible [label].
  /// Combines touch target enforcement with semantic annotation.
  static Widget button({
    required Widget child,
    required String label,
    String? hint,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      hint: hint,
      child: touchTarget(child: child),
    );
  }

  // ── Image / icon ──────────────────────────────────────────────────────────

  /// Wraps an image or icon with a descriptive [label] for screen readers.
  static Widget image({required Widget child, required String label}) {
    return Semantics(
      image: true,
      label: label,
      child: child,
    );
  }

  // ── Focus order ───────────────────────────────────────────────────────────

  /// Returns a [FocusTraversalGroup] with [OrderedTraversalPolicy] so
  /// TalkBack / VoiceOver traverse children in the order you specify via
  /// [FocusTraversalOrder] + [NumericFocusOrder].
  ///
  /// Wrap your form or interactive section with this to guarantee
  /// top-to-bottom focus order regardless of widget tree depth.
  static Widget orderedFocusGroup({required Widget child}) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }

  // ── Contrast helpers ──────────────────────────────────────────────────────

  /// Returns `true` when the current platform brightness is dark,
  /// useful for choosing icon colours that meet 4.5:1 contrast ratio.
  static bool isDark(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  // ── Text scale ────────────────────────────────────────────────────────────

  /// Returns the effective text scale factor, clamped to [min]–[max].
  /// Matches the clamp applied in [App.builder].
  static double clampedTextScale(
    BuildContext context, {
    double min = 1.0,
    double max = 1.4,
  }) {
    final raw = MediaQuery.textScalerOf(context).scale(1.0);
    return raw.clamp(min, max);
  }
}
