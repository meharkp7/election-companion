# VoteReady — Accessibility Guide

VoteReady is built to WCAG 2.1 AA standards so every eligible voter can use it,
regardless of disability or assistive technology.

---

## Implemented Patterns

### 1. Semantic Labels (`Semantics` widget)
Every interactive element carries a `Semantics` wrapper with:
- `label` — human-readable description read by TalkBack / VoiceOver
- `hint` — additional context (e.g. "Tap to toggle")
- `button: true` on all tappable widgets
- `header: true` on section headings
- `liveRegion: true` on dynamic content (errors, AI replies, status banners)
- `toggled` on Switch widgets

### 2. Decorative Content (`ExcludeSemantics`)
Purely decorative widgets (trophy emoji, flag icons, background illustrations)
are wrapped in `ExcludeSemantics` so screen readers skip them and focus on
meaningful content.

### 3. Touch Target Size
All interactive elements meet the WCAG 2.5.5 minimum of **48 × 48 dp**:
```dart
ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
  child: ...,
)
```

### 4. Focus Traversal Order
`FocusTraversalGroup` with `OrderedTraversalPolicy` and `NumericFocusOrder`
ensures TalkBack / VoiceOver traverse form fields top-to-bottom:
- Age field → State dropdown → Submit button

### 5. High-Contrast Themes
Three themes are provided:
| Theme | Usage |
|---|---|
| `AppTheme.light` | Default |
| `AppTheme.lightHighContrast` | OS high-contrast mode (light) |
| `AppTheme.darkHighContrast` | OS high-contrast mode (dark) |

Activated automatically via `MaterialApp.highContrastTheme` and
`MaterialApp.highContrastDarkTheme`.

### 6. Text Scaling
Font size respects the OS accessibility setting, clamped to **1.0×–1.4×**
to prevent layout overflow while still honouring large-text preferences:
```dart
final clampedScaler = mediaQuery.textScaler.clamp(
  minScaleFactor: 1.0,
  maxScaleFactor: 1.4,
);
```

### 7. Localisation Delegates
`GlobalMaterialLocalizations`, `GlobalWidgetsLocalizations`, and
`GlobalCupertinoLocalizations` are registered so date pickers, alerts, and
other system widgets are correctly localised for screen readers.

### 8. Supported Locales
- `en_IN` (English, India) — primary
- `hi_IN` (Hindi, India) — secondary

### 9. Error Announcements
All error messages use `Semantics(liveRegion: true)` so TalkBack announces
them immediately without the user having to navigate to them.

### 10. Semantic Debug Mode
`showSemanticsDebugger: false` in `app.dart` — flip to `true` during QA to
visualise the semantic tree overlay.

---

## Screen-by-Screen Checklist

| Screen | Headings | Live Regions | Touch Targets | Decorative Exclusions |
|---|---|---|---|---|
| Onboarding | ✅ | ✅ (errors) | ✅ | ✅ (logo) |
| Eligibility | ✅ | ✅ (status) | ✅ | ✅ (icon) |
| Registration | ✅ | ✅ (errors) | ✅ | — |
| Verification | ✅ | ✅ | ✅ | — |
| Ready to Vote | ✅ | — | ✅ | — |
| Voting Day | ✅ | ✅ (election mode) | ✅ | — |
| Completed | ✅ | ✅ (heading) | ✅ | ✅ (trophy) |
| AI Assistant | — | ✅ (replies) | ✅ | — |
| Election Tracker | — | — | ✅ | — |
| Voter Rights | — | — | ✅ | — |
| Polling Day Kit | — | — | ✅ | — |
| Social Features | — | — | ✅ | — |

---

## Testing Accessibility

```bash
# Run widget tests (includes Semantics assertions)
cd frontend/app
flutter test test/widget/

# Enable semantic debugger overlay (flip in app.dart)
showSemanticsDebugger: true

# Manual testing
# Android: Enable TalkBack in Settings → Accessibility
# iOS: Enable VoiceOver in Settings → Accessibility
```

---

## Known Limitations

- Full WCAG validation requires manual testing with real assistive technologies
  and expert accessibility review.
- Hindi (`hi_IN`) content is currently limited to UI chrome; voter rights guides
  are English-only pending translation.
- Complex data visualisations (turnout charts, party seat bars) provide text
  alternatives via `Semantics(label: ...)` but do not yet have full data table
  alternatives.
