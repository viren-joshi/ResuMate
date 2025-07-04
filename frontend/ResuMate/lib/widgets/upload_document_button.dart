import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:developer' as developer;
import '../constants.dart';
import 'package:ResuMate/services/auth_handler.dart';
import 'package:ResuMate/services/websocket_provider.dart';

class UploadDocumentButton extends StatelessWidget {
  const UploadDocumentButton({
    super.key,
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
          onTap: () async {
            // Upload Document
            // Call file picker and Send message.
            await FilePicker.platform
                .pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    withData: true)
                .then((result) async {
              if (result != null && result.files.single.bytes != null) {
                var wsProvider = context.read<WebSocketProvider>();

                final fileBytes = result.files.single.bytes!;
                final fileName = result.files.single.name;

                wsProvider.setPendingUploadFile(fileBytes, fileName);

                String userId =
                    await context.read<AuthHandler>().getUserId() ?? "";

                Map<String, dynamic> payload = {};
                payload["userId"] = userId;
                payload["fileName"] = fileName;

                wsProvider.sendMessage("uploadResume", payload);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No File Chosen or file is empty."),
                  ),
                );
              }
            }).onError((e, _) {
              developer.log(e.toString());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("File Picking Error."),
                ),
              );
            });
          },
          dense: false,
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          selected: false,
          title: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}