import 'package:flutter/material.dart';

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
  Size get preferredSize => Size.fromHeight(
      kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final bool canPop = automaticallyImplyLeading &&
        (ModalRoute.of(context)?.canPop ?? false);

    return AppBar(
      // Disable the default leading so we handle layout ourselves
      automaticallyImplyLeading: false,
      // Passthrough visual params
      backgroundColor: backgroundColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation ?? 0,
      iconTheme: iconTheme,
      titleTextStyle: titleTextStyle,
      bottom: bottom,
      // titleSpacing: 0 lets the title widget fill the full width so we can
      // apply our own padding inside the constrained row.
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Row(
            children: [
              // Back button or custom leading
              if (leading != null)
                leading!
              else if (canPop)
                BackButton(
                    onPressed: () => Navigator.maybePop(context),
                    color: Colors.white),

              // Title — expands to fill available space
              if (title != null)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: (canPop || leading != null) ? 4.0 : 16.0),
                    child: title!,
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
