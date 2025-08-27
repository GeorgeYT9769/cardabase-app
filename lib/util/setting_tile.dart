import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class MySetting extends StatelessWidget {

  final String settingHeader;
  final String aboutSettingHeader;
  final IconData settingIcon;
  final void Function() settingAction;
  final Color iconColor;


  const MySetting({super.key, required this.aboutSettingHeader, required this.settingAction, required this.settingHeader, required this.settingIcon, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.all(15),
        alignment: Alignment.center,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            backgroundColor: Colors.transparent,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
            ),
            minimumSize: const Size.fromHeight(100),
          ),
          onPressed: settingAction,
          child: Row(
            children: [
              const SizedBox(width: 10,),
              Icon(settingIcon, color: iconColor, size: 30,),
              const SizedBox(width: 20,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(settingHeader, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5,),
                  Text(aboutSettingHeader, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.inverseSurface, fontSize: 12.5, fontWeight: FontWeight.w400)),
                ],
              ),
            ],
          ),
        )
      ),
    );
  }
}
