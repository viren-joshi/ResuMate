import 'package:flutter/material.dart';
import 'package:ResuMate/services/auth_handler.dart';
import 'package:ResuMate/constants.dart';
import 'package:ResuMate/custom_button.dart';
import 'package:ResuMate/login_screen.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:provider/provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  String name = "";
  String email = "";
  String password = "";
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    AuthHandler authHandler = context.read<AuthHandler>();
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        body: Center(
          child: Container(
            height: 300,
            width: 300,
            decoration: const BoxDecoration(
              color: kSecondaryBackgroundColor,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "SignUp",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: kTextBoxColor,
                      hintText: "Name",
                      hintStyle: TextStyle(color: kTextColor.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        email = value;
                      });
                    },
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: kTextBoxColor,
                      hintText: "Email",
                      hintStyle: TextStyle(color: kTextColor.withOpacity(0.6)),
                    ),
                  ),
                  const SizedBox(
                    height: 15.0,
                  ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        password = value;
                      });
                    },
                    style: const TextStyle(color: kTextColor),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: kTextBoxColor,
                      hintText: "Password",
                      hintStyle: TextStyle(color: kTextColor.withOpacity(0.6)),
                    ),
                    obscureText: true,
                  ),
                  CustomButton(
                    onPressed: () async {
                      // Make User LogIn
                      setState(() {
                        isLoading = true;
                      });
                      await authHandler
                          .signUpUser(
                              email: email, password: password, name: name)
                          .then((value) {
                        if (value) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  backgroundColor: Colors.black,
                                  elevation: 2.5,
                                  content: Text(
                                    "SignUp Success",
                                    style: TextStyle(color: kTextColor),
                                  )));
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  backgroundColor: Colors.black,
                                  elevation: 2.5,
                                  content: Text(
                                    "SignUp Unsuccessful",
                                    style: TextStyle(color: kTextColor),
                                  )));
                        }
                      }).onError((e, _) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                                backgroundColor: Colors.black,
                                elevation: 2.5,
                                content: Text(
                                  "SignUp Unsuccessful",
                                  style: TextStyle(color: kTextColor),
                                )));
                      });
                      setState(() {
                        isLoading = false;
                      });
                    },
                    buttonText: "Proceed",
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


