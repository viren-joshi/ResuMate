import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import 'package:ResuMate/services/auth_handler.dart';
import 'package:ResuMate/services/websocket_provider.dart';
import 'package:ResuMate/custom_button.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    super.key,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  String prompt = "";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView(
        shrinkWrap: true,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 18.0),
                  child: Text(
                    "ResuMate",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      prompt = value;
                    });
                  },
                  style: const TextStyle(color: kTextColor),
                  textAlignVertical: TextAlignVertical.center,
                  maxLines: 10,
                  minLines: 5,
                  decoration: InputDecoration(
                    hintText: "Enter Job Description",
                    hintMaxLines: 10,
                    hintStyle: TextStyle(color: kTextColor.withOpacity(0.6)),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: kTextBoxColor,
                  ),
                ),
              ),
              Consumer<WebSocketProvider>(
                  builder: (context, wsProvider, child) {
                return Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText: "Send",
                        buttonBackgroundColor: kSecondaryBackgroundColor,
                        onPressed: () async {
                          Map<String, dynamic> payload = {};
                          payload["text"] = prompt;
                          payload["userId"] =
                              await context.read<AuthHandler>().getUserId();
                          wsProvider.sendMessage('createCoverLetter', payload);
                        },
                      ),
                    ),
                    Expanded(
                      child: CustomButton(
                        buttonText: "Reset",
                        buttonBackgroundColor: kSecondaryBackgroundColor,
                        onPressed: () {
                          setState(() {
                            prompt = "";
                          });
                          wsProvider.clearGenText();
                        },
                      ),
                    )
                  ],
                );
              }),
              Consumer<WebSocketProvider>(
                  builder: (context, wsProvider, child) {
                if (wsProvider.generatedText == null) {
                  return const SizedBox();
                } else {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "Generated Text",
                          style: TextStyle(
                            color: kTextColor,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.black87),
                          child: Text(
                            wsProvider.generatedText ?? "",
                            style: const TextStyle(
                                color: kTextColor,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w100),
                          ),
                        )
                      ],
                    ),
                  );
                }
              })
            ],
          ),
        ],
      ),
    );
  }
}