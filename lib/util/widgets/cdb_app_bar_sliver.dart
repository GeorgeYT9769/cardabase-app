import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../feature/settings/get_it.dart';
import '../../feature/settings/model.dart';
import 'blur_app_bar_background.dart';

class CdbAppBarSliver extends StatefulWidget {
  const CdbAppBarSliver({
    super.key,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.onBackPressed,
    this.leading,
    this.showBackButton = true,
    this.floating = true,
    this.snap = false,
    this.pinned = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final Widget? leading;
  final bool showBackButton;
  final bool floating;
  final bool snap;
  final bool pinned;

  @override
  State<CdbAppBarSliver> createState() => _CdbAppBarSliverState();
}

class _CdbAppBarSliverState extends State<CdbAppBarSliver> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, box, _) {
        final settings = box.value;
        final rightBackButton = settings.theme.rightBackButton;
        final advancedTextures = settings.theme.advancedTextures;

        final backButton = IconButton(
          onPressed: widget.onBackPressed,
          icon: const Icon(Icons.arrow_back_ios_new),
          color: theme.colorScheme.tertiary,
        );

        Widget? leading;
        List<Widget> actions = [...widget.actions];

        if (widget.showBackButton) {
          if (rightBackButton) {
            leading = widget.leading;
            actions.add(backButton);
          } else {
            leading = backButton;
            if (widget.leading != null) {
              actions.add(widget.leading!);
            }
          }
        } else {
          leading = widget.leading;
        }

        return SliverAppBar(
          automaticallyImplyLeading: false,
          leading: leading,
          actions: actions,
          title: widget.titleWidget ??
              (widget.title != null
                  ? Text(
                      widget.title!,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.tertiary,
                      ),
                    )
                  : null),
          centerTitle: true,
          elevation: 0.0,
          backgroundColor: advancedTextures
              ? Colors.transparent
              : theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: advancedTextures ? const BlurAppBarBackground() : null,
          floating: widget.floating,
          snap: widget.snap,
          pinned: widget.pinned,
        );
      },
    );
  }
}
