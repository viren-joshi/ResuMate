import 'package:flutter/material.dart';
import '../constants.dart';

class DocumentListTile extends StatelessWidget {
  final String documentName;
  const DocumentListTile({
    super.key,
    required this.documentName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 12.0),
      child: Material(
        borderRadius: BorderRadius.circular(10.0),
        color: kBackgroundColor,
        child: ListTile(
          tileColor: kBackgroundColor,
          dense: false,
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          selected: false,
          leading: const Icon(
            Icons.description,
            color: Colors.white,
          ),
          title: Text(
            documentName,
            style: const TextStyle(color: kTextColor),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}