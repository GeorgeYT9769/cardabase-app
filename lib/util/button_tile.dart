import 'package:flutter/material.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';

class ButtonTile extends StatelessWidget {

  final String buttonText;
  final buttonAction;


  const ButtonTile({super.key, required this.buttonText, required this.buttonAction});

  @override
  Widget build(BuildContext context) {
    return Bounceable(
      onTap: () {},
      child: Container(
          margin: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(15),
              side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
              backgroundColor: Colors.transparent,
              elevation: 0.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size.fromHeight(65),
            ),
            onPressed: buttonAction,
            child: Text(buttonText, style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 20, fontFamily: 'Roboto-Regular.ttf',)),
          )
      ),
    );
  }
}
