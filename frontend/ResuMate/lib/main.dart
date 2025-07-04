import 'package:flutter/material.dart';
import 'package:ResuMate/services/auth_handler.dart';
import 'package:ResuMate/home_screen.dart';
import 'package:ResuMate/login_screen.dart';
import 'package:ResuMate/services/websocket_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        Provider<AuthHandler>(
          create: (_) => AuthHandler(
            userPoolId: dotenv.env['USER_POOL_ID'] ?? "",
            appClientId: dotenv.env['APP_CLIENT_ID'] ?? "",
          ),
        )
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var authHandler = Provider.of<AuthHandler>(context, listen: false);
    return MaterialApp(
      title: 'ResuMate',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: authHandler.getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            developer.log("Waiting");
            return const CircularProgressIndicator();
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              developer.log("User logged In");
              // Logged-In User
              return const HomeScreen();
            } else {
              developer.log("User not logged In"); 
              // Make User Login
              return const LoginScreen();
            }
          } else {
            return const SizedBox(
              child: Text("Something Went Wrong Xp"),
            );
          }
        },
      ),
    );
  }
}
