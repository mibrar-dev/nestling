import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/colors.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Material themes built from the Nestling tokens.
///
/// Prefer the `Nest*` components over raw Material widgets; the component
/// themes below exist so anything Material (sheets, dialogs, snack bars,
/// switches, progress) still matches the spec.
abstract final class NestTheme {
  const new _();

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = brightness == Brightness.light
        ? NestColors.light
        : NestColors.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.leaf,
      onPrimary: colors.onLeaf,
      primaryContainer: colors.leafTint,
      onPrimaryContainer: colors.leafInk,
      secondary: colors.coin,
      onSecondary: colors.onWarm,
      secondaryContainer: colors.coinTint,
      onSecondaryContainer: colors.coinInk,
      tertiary: colors.lilac,
      onTertiary: colors.onAccent,
      tertiaryContainer: colors.lilacTint,
      onTertiaryContainer: colors.lilac,
      error: colors.danger,
      onError: colors.onHero,
      surface: colors.surface,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.surface2,
      onSurfaceVariant: colors.ink2,
      outline: colors.line,
      outlineVariant: colors.line,
      shadow: colors.groundShadow,
      scrim: colors.scrim,
      inverseSurface: colors.ink,
      onInverseSurface: colors.paper,
      inversePrimary: colors.leaf,
    );

    final text = TextTheme(
      displayLarge: NestType.display(color: colors.ink),
      displayMedium: NestType.h1(color: colors.ink),
      displaySmall: NestType.h2(color: colors.ink),
      headlineLarge: NestType.h1(color: colors.ink),
      headlineMedium: NestType.h2(color: colors.ink),
      headlineSmall: NestType.h3(color: colors.ink),
      titleLarge: NestType.h2(color: colors.ink),
      titleMedium: NestType.h3(color: colors.ink),
      titleSmall: NestType.bodyStrong(color: colors.ink),
      bodyLarge: NestType.body(color: colors.ink),
      bodyMedium: NestType.bodySmall(color: colors.ink),
      bodySmall: NestType.caption(color: colors.ink2),
      labelLarge: NestType.buttonLabel(color: colors.ink),
      labelMedium: NestType.fieldLabel(color: colors.ink2),
      labelSmall: NestType.tabLabel(color: colors.ink3),
    );

    final tokens = NestTokens(colors: colors, brightness: brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper,
      canvasColor: colors.surface,
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[tokens, const NestKidTheme()],
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: NestType.h3(color: colors.ink),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: NestRadii.allL),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colors.leaf,
          foregroundColor: colors.onLeaf,
          shape: const RoundedRectangleBorder(borderRadius: NestRadii.allPill),
          textStyle: NestType.buttonLabel(),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colors.leaf,
          foregroundColor: colors.onLeaf,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: NestRadii.allPill),
          textStyle: NestType.buttonLabel(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: colors.ink,
          side: BorderSide(color: colors.line),
          shape: const RoundedRectangleBorder(borderRadius: NestRadii.allPill),
          textStyle: NestType.buttonLabel(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.ink,
          textStyle: NestType.bodySmallStrong(),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: colors.ink,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        constraints: const BoxConstraints(minHeight: 52),
        hintStyle: NestType.body(color: colors.ink3),
        labelStyle: NestType.fieldLabel(color: colors.ink2),
        helperStyle: NestType.caption(color: colors.ink2),
        errorStyle: NestType.caption(color: colors.danger)
            .copyWith(fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: NestRadii.allM,
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: NestRadii.allM,
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: NestRadii.allM,
          borderSide: BorderSide(color: colors.leaf),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: NestRadii.allM,
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: NestRadii.allM,
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surface2,
        selectedColor: colors.leafTint,
        labelStyle: NestType.chipLabel(color: colors.ink),
        secondaryLabelStyle: NestType.chipLabel(color: colors.leafInk),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const RoundedRectangleBorder(borderRadius: NestRadii.allPill),
        side: BorderSide.none,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(colors.knob),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.leaf
              : colors.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.leaf
              : colors.surface,
        ),
        checkColor: WidgetStateProperty.all(colors.onLeaf),
        side: BorderSide(color: colors.line, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(borderRadius: NestRadii.topXl),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: NestRadii.allXl),
        titleTextStyle: NestType.h3(color: colors.ink),
        contentTextStyle: NestType.bodySmall(color: colors.ink2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.ink,
        contentTextStyle: NestType.bodySmallStrong(color: colors.paper),
        shape: const RoundedRectangleBorder(borderRadius: NestRadii.allM),
        behavior: SnackBarBehavior.floating,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.leaf,
        circularTrackColor: colors.surface2,
        linearTrackColor: colors.surface2,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.leaf,
        selectionColor: colors.leafTint,
        selectionHandleColor: colors.leaf,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          NestType.tabLabel(color: colors.ink3),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(44, 44),
          backgroundColor: Colors.transparent,
          foregroundColor: colors.ink2,
          selectedBackgroundColor: colors.surface,
          selectedForegroundColor: colors.ink,
          textStyle: NestType.chipLabel(),
          shape: const RoundedRectangleBorder(borderRadius: NestRadii.allPill),
          side: BorderSide.none,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: NestSpacing.s3,
        iconColor: colors.ink2,
        titleTextStyle: NestType.bodyStrong(color: colors.ink),
        subtitleTextStyle: NestType.bodySmall(color: colors.ink3),
      ),
      iconTheme: IconThemeData(color: colors.ink2, size: 24),
    );
  }
}
