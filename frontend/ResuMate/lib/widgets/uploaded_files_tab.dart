import 'package:flutter/material.dart';
import 'package:ResuMate/services/websocket_provider.dart';
import 'package:ResuMate/widgets/document_list_tile.dart';
import 'package:ResuMate/widgets/upload_document_button.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'status_message_banner.dart';

class UploadedFilesTab extends StatelessWidget {
  const UploadedFilesTab({
    super.key,
  });

  List<Widget> getUploadedFilesList(List<String> uploadedFiles) {
    List<Widget> children = [];
    for (String file in uploadedFiles) {
      children.add(DocumentListTile(documentName: file));
    }
    children.add(const UploadDocumentButton());

    return children;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(builder: (context, wsProvider, child) {
      if (wsProvider.isFilesLoaded) {
        return Container(
          color: kSecondaryBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (wsProvider.statusMessage != null)
                StatusMessageBanner(
                  message: wsProvider.statusMessage!,
                  onDismissed: () {
                    wsProvider.clearStatusMessage();
                  },
                ),
              ...getUploadedFilesList(wsProvider.uploadedFiles)
            ],
          ),
        );
      } else {
        return Container(
          color: kSecondaryBackgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (wsProvider.statusMessage != null)
                StatusMessageBanner(
                    message: wsProvider.statusMessage!,
                    onDismissed: () {
                      wsProvider.clearStatusMessage();
                    }),
              const UploadDocumentButton(),
            ],
          ),
        );
      }
    });
  }
}