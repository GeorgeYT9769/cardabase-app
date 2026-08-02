import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import '../../feature/settings/get_it.dart';
import '../../feature/settings/model.dart';

class CdbAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CdbAppBar({
    super.key,
    required this.title,
    this.actions = const [],
    this.onBackPressed,
    this.leading,
    this.bottom,
  });

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBackPressed;
  final IconButton? leading;
  final PreferredSizeWidget? bottom;

  @override
  State<CdbAppBar> createState() => _CdbAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

class _CdbAppBarState extends State<CdbAppBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: GetIt.I<SettingsBox>().listenable(),
      builder: (context, box, _) {
        final settings = box.value;
        final rightBackButton = settings.theme.rightBackButton;
        return AppBar(
          automaticallyImplyLeading: false,
          leading: !rightBackButton
              ? IconButton(
                  onPressed: widget.onBackPressed,
                  icon: const Icon(Icons.arrow_back_ios_new),
                  color: theme.colorScheme.tertiary,
                )
              : widget.leading,
          actions: [
            ...widget.actions,
            if (!rightBackButton && widget.leading != null) widget.leading!,
            if (rightBackButton)
              IconButton(
                onPressed: widget.onBackPressed,
                icon: const Icon(Icons.arrow_back_ios_new),
                color: theme.colorScheme.tertiary,
              ),
          ],
          title: Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
          backgroundColor: theme.colorScheme.surface,
          bottom: widget.bottom,
        );
      },
    );
  }
}
