import 'package:flutter/material.dart';
import '../constants.dart';

class StatusMessageBanner extends StatelessWidget {
  final String message;
  final Function() onDismissed;

  const StatusMessageBanner(
      {super.key, required this.message, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: kTextColor, fontSize: 14),
            ),
          ),
          IconButton(
            onPressed: () => onDismissed(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
