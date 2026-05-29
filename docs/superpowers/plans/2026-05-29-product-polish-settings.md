# Product Polish Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Polish the Flutter app into a more coherent product by unifying bottom navigation icon states, upgrading Settings into a product center, and adding user-facing legal, about, notification, and monetization guidance.

**Architecture:** Keep the current Flutter `AppState + ui` shape. This change is mostly presentation and interaction: `AppShell` owns tab icon consistency, while `SettingsScreen` owns product-center panels and modal detail pages. Notification and advertising are exposed as planned integration panels, not wired to native SDKs yet.

**Tech Stack:** Flutter, Material 3, `material_symbols_icons`, `flutter_animate`, existing widget tests.

---

### Task 1: Navigation Icon State Consistency

**Files:**
- Modify: `lib/src/app/app_shell.dart`
- Test: `test/ui/app_navigation_test.dart`

- [ ] Add a widget test that verifies every bottom navigation destination has a distinct selected and unselected icon widget.
- [ ] Run the navigation test and confirm it fails for the history and settings tabs.
- [ ] Update history and settings destinations to use different rounded Material Symbols for selected vs unselected states.
- [ ] Re-run the navigation test and confirm it passes.

### Task 2: Settings Product Center

**Files:**
- Modify: `lib/src/ui/settings/settings_screen.dart`
- Test: `test/ui/settings_screen_test.dart`

- [ ] Add widget tests for visible product-center entries: About, Copyright and Authorization, Privacy and Permissions, Notifications, Advertising and Monetization.
- [ ] Add widget tests that tap each entry and verify its detail page content.
- [ ] Run settings tests and confirm they fail because the entries do not exist yet.
- [ ] Implement reusable settings section and detail sheet/dialog widgets inside `settings_screen.dart`.
- [ ] Add the five new entries with concise copy and consistent Material Symbols Rounded icons.
- [ ] Re-run settings tests and confirm they pass.

### Task 3: Interaction And Motion Polish

**Files:**
- Modify: `lib/src/ui/settings/settings_screen.dart`
- Modify: `lib/src/app/app_theme.dart`
- Test: `test/ui/settings_screen_test.dart`

- [ ] Add stable keys or tooltips where needed so settings entries are testable and accessible.
- [ ] Keep card radius at 8 and use existing `AppPanel` patterns.
- [ ] Use existing `flutter_animate` entrance motion; avoid adding heavyweight animation dependencies.
- [ ] Ensure notification and advertising entries are explicitly marked as future integration guidance, not active SDK behavior.

### Task 4: Verification

**Files:**
- All touched Dart files

- [ ] Run `dart format` on modified Dart files.
- [ ] Run `flutter analyze --no-pub`.
- [ ] Run `flutter test --no-pub`.
- [ ] Run `flutter build apk --debug --no-pub`.
- [ ] If an emulator is available, install/launch the debug app and capture a quick visual check.
