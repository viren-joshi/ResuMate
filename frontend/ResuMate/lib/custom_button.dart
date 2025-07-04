import 'package:flutter/material.dart';
import 'package:ResuMate/constants.dart';

class CustomButton extends StatelessWidget {
  final Function()? onPressed;
  final String buttonText;
  final Color buttonBackgroundColor;
  const CustomButton({
    super.key,
    this.onPressed,
    required this.buttonText, this.buttonBackgroundColor = kBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(buttonBackgroundColor),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            buttonText,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
