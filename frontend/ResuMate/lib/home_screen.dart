import 'package:ResuMate/constants.dart';
import 'package:ResuMate/custom_button.dart';
import 'package:ResuMate/login_screen.dart';
import 'package:ResuMate/services/auth_handler.dart';
import 'package:ResuMate/services/websocket_provider.dart';
import 'package:ResuMate/widgets/chat_widget.dart';
import 'package:ResuMate/widgets/uploaded_files_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Consumer<WebSocketProvider>(builder: (context, wsProvider, child) {
        if (wsProvider.isConnected) {
          return const ConsoleSection();
        } else {
          // Render Connect to WebSocket UI
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              Center(
                child: CustomButton(
                  buttonText: "Connect To Creation",
                  buttonBackgroundColor: kSecondaryBackgroundColor,
                  onPressed: () async {
                    await context
                        .read<AuthHandler>()
                        .getToken()
                        .then((idToken) {
                      if (idToken != null) {
                        String userId = context
                            .read<AuthHandler>()
                            .getUserIdFromIdToken(idToken);
                        wsProvider.init(context, idToken, userId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.black,
                            elevation: 2.5,
                            content: Text(
                              "You are not logged in.",
                              style: TextStyle(color: kTextColor),
                            ),
                          ),
                        );
                      }
                    });
                  },
                ),
              ),
              Center(
                child: CustomButton(
                  buttonText: "Log Out",
                  buttonBackgroundColor: kSecondaryBackgroundColor,
                  onPressed: () async {
                    await context.read<AuthHandler>().logOut().then((value) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    });
                  },
                ),
              )
            ],
          );
        }
      }),
    );
  }
}

class ConsoleSection extends StatelessWidget {
  const ConsoleSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width / 4,
          height: MediaQuery.of(context).size.height,
          child: const UploadedFilesTab(),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width / 4) * 3,
          height: MediaQuery.of(context).size.height,
          child: const Center(child: ChatWidget()),
        )
      ],
    );
  }
}








