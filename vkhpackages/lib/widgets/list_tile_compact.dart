import 'package:flutter/material.dart';

/// A custom ListTile widget with zero padding for child contents.
class ListTileCompact extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? infotext;
  final Widget? trailing;
  final bool enabled;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final bool selected;
  final Color? selectedTileColor;
  final Color? tileColor;
  final BorderRadius? borderRadius;

  const ListTileCompact({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.infotext,
    this.trailing,
    this.enabled = true,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectedTileColor,
    this.tileColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Color? effectiveTileColor =
        selected && selectedTileColor != null ? selectedTileColor : tileColor;
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Material(
        color: effectiveTileColor,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // leading
              if (leading != null) leading!,
              if (leading != null) SizedBox(width: 4),

              if (title != null || subtitle != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // title
                      if (title is Text)
                        Text(
                          (title as Text).data ?? '',
                          style: Theme.of(context).textTheme.headlineSmall,
                        )
                      else if (title != null)
                        title!,

                      // subtitle
                      if (subtitle is Text)
                        Text(
                          (subtitle as Text).data ?? '',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else if (subtitle != null)
                        subtitle!,

                      // infotext
                      if (infotext is Text)
                        Text(
                          (infotext as Text).data ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        )
                      else if (infotext != null)
                        infotext!,
                    ],
                  ),
                ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
