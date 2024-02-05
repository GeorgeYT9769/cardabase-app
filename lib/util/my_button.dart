import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {

  final String text;
  VoidCallback onPressed;
  double width;
  double height;
  Color color;

  MyButton({super.key, required this.text, required this.onPressed, required this.width, required this.height, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      child: MaterialButton(
        onPressed: onPressed,
        color: color,
        child: Text(text, style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto-Regular.ttf',
        ),
        ),
      ),
    );
  }
}