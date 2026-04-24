import 'package:flutter/material.dart';
import '../theme/background_styles.dart';

/// Drop-in replacement for [AppBar] that constrains its content
/// (back button, title, and actions) to [maxWidth] pixels.
///
/// This ensures the toolbar controls stay visually aligned with the
/// body content, which uses the same [maxWidth] constraint across
/// all screens.
///
/// Usage — identical to AppBar:
/// ```dart
/// appBar: ConstrainedAppBar(
///   title: Text('Mi Pantalla'),
///   actions: [IconButton(...)],
/// )
/// ```
class ConstrainedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double maxWidth;

  // Pass-through AppBar params used in existing screens
  final Color? backgroundColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final IconThemeData? iconTheme;
  final TextStyle? titleTextStyle;

  const ConstrainedAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.maxWidth = 900,
    this.backgroundColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.centerTitle,
    this.bottom,
    this.iconTheme,
    this.titleTextStyle,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  /// Sombra aplicada por defecto al título y al botón de retroceso
  /// para garantizar legibilidad sobre cualquier fondo (imagen, color, gradiente).
  static const _shadowedTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    shadows: BackgroundStyles.shadow,
  );

  static const _shadowedIconTheme = IconThemeData(
    color: Colors.white,
    shadows: BackgroundStyles.shadow,
  );

  @override
  Widget build(BuildContext context) {
    final bool canPop =
        automaticallyImplyLeading && (ModalRoute.of(context)?.canPop ?? false);

    // Merge caller overrides on top of the shadowed defaults
    final effectiveTitleStyle = titleTextStyle ?? _shadowedTitleStyle;
    final effectiveIconTheme = iconTheme ?? _shadowedIconTheme;

    return AppBar(
      // Disable the default leading so we handle layout ourselves
      automaticallyImplyLeading: false,
      // Passthrough visual params
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation ?? 0,
      iconTheme: effectiveIconTheme,
      titleTextStyle: effectiveTitleStyle,
      bottom: bottom,
      // titleSpacing: 0 lets the title widget fill the full width so we can
      // apply our own padding inside the constrained row.
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              // Back button or custom leading — always white+shadow
              if (leading != null)
                leading!
              else if (canPop)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.maybePop(context),
                  style: ButtonStyle(
                    iconColor: WidgetStateProperty.all(Colors.white),
                    iconSize: WidgetStateProperty.all(24),
                  ),
                ),

              // Title — expands to fill available space, inherits shadow style
              if (title != null)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: (canPop || leading != null) ? 4.0 : 16.0),
                    child: DefaultTextStyle.merge(
                      style: effectiveTitleStyle,
                      child: title!,
                    ),
                  ),
                ),

              // Actions — stay inside the 900px bound
              if (actions != null) ...actions!,

              // Right edge breathing room when no actions
              if (actions == null || actions!.isEmpty) const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
