import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class MySetting extends StatelessWidget {
  final String settingHeader;
  final String aboutSettingHeader;
  final IconData settingIcon;
  final void Function() settingAction;
  final Color iconColor;
  final Color borderColor;

  const MySetting({
    super.key,
    required this.aboutSettingHeader,
    required this.settingAction,
    required this.settingHeader,
    required this.settingIcon,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Bounceable(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        alignment: Alignment.center,
        child: GestureDetector(
          onLongPress: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side:
                      BorderSide(color: theme.colorScheme.tertiary, width: 2.0),
                ),
                content: Row(
                  children: [
                    const SizedBox(width: 5),
                    Icon(
                      Icons.info,
                      size: 15,
                      color: theme.colorScheme.inverseSurface,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        aboutSettingHeader,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 18,
                          color: theme.colorScheme.inverseSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 3000),
                padding: const EdgeInsets.all(5.0),
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                behavior: SnackBarBehavior.floating,
                dismissDirection: DismissDirection.vertical,
                backgroundColor: theme.colorScheme.surface,
              ),
            );
          },
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              side: BorderSide(color: borderColor, width: 2),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              minimumSize: const Size.fromHeight(80),
            ),
            onPressed: settingAction,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Icon(
                  settingIcon,
                  color: iconColor,
                  size: 30,
                ),
                const SizedBox(width: 20),
                Text(
                  settingHeader,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.inverseSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                //Column(
                //  crossAxisAlignment: CrossAxisAlignment.start,
                //  children: [
                //    Text(settingHeader, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 22, fontWeight: FontWeight.w600)),
                //    const SizedBox(height: 5),
                //    Text(aboutSettingHeader, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 12, fontWeight: FontWeight.w400)),
                //  ],
                //),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
