import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_bloc.dart';
import 'package:nestling/features/design_system_gallery/presentation/bloc/design_system_gallery_state.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_colors.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_forms.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_kid.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_overlays.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_parent_a.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_parent_b.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_screens.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_space.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/gallery_type.dart';
import 'package:provider/provider.dart';

/// Design-system catalogue: tokens plus every component in every state.
///
/// Mirrors `design/html-source/design-system.html`. The top bar toggles
/// light/dark through the app [ThemeModeController]; the kid section renders
/// inside a [KidScope]; the screens row composes P08 + K03 from DS widgets.
class DesignSystemGalleryView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design system'),
        actions: const [_MotionLabButton(), _ThemeToggle()],
      ),
      body: BlocBuilder<DesignSystemGalleryBloc, DesignSystemGalleryState>(
        builder: (context, state) {
          switch (state.status) {
            case DesignSystemGalleryStatus.initial:
            case DesignSystemGalleryStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case DesignSystemGalleryStatus.failure:
              return Center(
                child: Text(state.errorMessage ?? 'Something went wrong'),
              );
            case DesignSystemGalleryStatus.loaded:
              return const _GalleryBody();
          }
        },
      ),
    );
  }
}

class _MotionLabButton extends StatelessWidget {
  const _MotionLabButton();

  @override
  Widget build(BuildContext context) {
    // The path is spelled out rather than imported from the routes file, which
    // imports this one. It is `/motion-lab` -
    // DesignSystemGalleryRoutePaths.motionLab.
    return TextButton(
      onPressed: () => context.push('/motion-lab'),
      child: const Text('Motion'),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeModeController>(
      builder: (context, controller, child) {
        final isDark =
            controller.mode == ThemeMode.dark ||
            (controller.mode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        return IconButton(
          tooltip: 'Toggle light/dark',
          onPressed: () =>
              controller.selectMode(isDark ? ThemeMode.light : ThemeMode.dark),
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        );
      },
    );
  }
}

class _GalleryBody extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    // Full-bleed sections: full width with the 20px screen side padding,
    // separated by 32px + a hairline. Components inside get the real
    // 350px content width, exactly like production screens.
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      children: const [
        _Section(
          key: ValueKey('ds-section-colour'),
          title: 'Colour',
          child: GalleryColors(),
        ),
        _Section(
          key: ValueKey('ds-section-type'),
          title: 'Type scale',
          child: GalleryType(),
        ),
        _Section(
          key: ValueKey('ds-section-spacing'),
          title: 'Space · Radii · Shadows',
          child: GallerySpace(),
        ),
        _Section(title: 'Parent components', child: GalleryParentA()),
        _Section(
          title: 'Parent components · continued',
          child: GalleryParentB(),
        ),
        _Section(title: 'Forms', child: GalleryForms()),
        _Section(title: 'Overlays', child: GalleryOverlays()),
        _Section(
          key: ValueKey('ds-section-kid'),
          title: 'Kid',
          padChild: false,
          child: GalleryKid(),
        ),
        _Section(
          title: 'Screens',
          divider: false,
          padChild: false,
          child: GalleryScreens(),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    super.key,
    this.divider = true,
    this.padChild = true,
  });

  final String title;
  final Widget child;

  /// Whether a hairline separates this section from the next one.
  final bool divider;

  /// Whether [child] gets the 20px side padding. False for edge-to-edge
  /// panels (the kid sky), which pad their own content instead.
  final bool padChild;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final padded = padChild
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: child,
          )
        : child;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Text(title, style: context.nestText.h2),
        ),
        const SizedBox(height: NestSpacing.s2),
        padded,
        if (divider) ...[
          const SizedBox(height: NestSpacing.s4),
          Divider(
            height: 1,
            thickness: 1,
            indent: NestSpacing.padSide,
            endIndent: NestSpacing.padSide,
            color: tokens.line,
          ),
          const SizedBox(height: NestSpacing.s4),
        ] else
          const SizedBox(height: NestSpacing.s4),
      ],
    );
  }
}
