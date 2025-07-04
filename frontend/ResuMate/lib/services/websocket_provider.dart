import 'dart:convert';

import 'package:flutter/material.dart';
import 'network_handler.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class WebSocketProvider extends ChangeNotifier {
  final NetworkHandler _networkHandler = NetworkHandler();
  bool _isConnected = false;
  String? _statusMessage;
  String? _generatedText;
  List<String> _uploadedFiles = [];
  bool _isFilesLoaded = false;
  Uint8List? _pendingFileBytes;
  String? _pendingFileName;

  bool get isConnected => _isConnected;
  String? get generatedText => _generatedText;
  List<String> get uploadedFiles => _uploadedFiles;
  bool get isFilesLoaded => _isFilesLoaded;
  String? get statusMessage => _statusMessage;

  void clearStatusMessage() {
    _statusMessage = null;
    notifyListeners();
  }

  void init(BuildContext context, String idToken, String userId) {
    // Register handlers
    if (_networkHandler.registeredHandlers) {
      _networkHandler.registerHandler("userAuth", _userAuthHandler);
      _networkHandler.registerHandler(
          "processAndRespond", _processAndRespondHandler);
      _networkHandler.registerHandler("userDocUpload", _userDocUploadHandler);
      _networkHandler.registerHandler("userInference", _userInferenceHandler);
      _networkHandler.registerHandler("userInit", _userInitHandler);
      _networkHandler.registerHandler("fetchUserData", _fetchUserDataHandler);
    }

    _networkHandler.connect(
      idToken: idToken,
      onConnected: () {
        _isConnected = true;
        notifyListeners();
      },
      onConnectionError: () {
        _isConnected = false;
        _statusMessage = null;
        notifyListeners();
      },
      onClosed: () {
        _isConnected = false;
        _statusMessage = null;
        notifyListeners();
      },
    );

    if (!isFilesLoaded) {
      Map<String, dynamic> payload = {};
      payload["userId"] = userId;
      sendMessage('fetchUserData', payload);
    }
  }

  void clearGenText() {
    _generatedText = null;
    notifyListeners();
  }

  void setPendingUploadFile(Uint8List bytes, String fileName) {
    _pendingFileBytes = bytes;
    _pendingFileName = fileName;
  }

  void sendMessage(String action, Map<String, dynamic> payload) {
    _networkHandler.sendMessage(action, payload);
  }

  // Handlers

  void _userAuthHandler(Map<String, dynamic> data) {
    // Notification Response Just Show Snackbar
    _statusMessage = "Authenticated Successfully!";
    notifyListeners();
  }

  void _processAndRespondHandler(Map<String, dynamic> data) {
    // Response includes the output of the LLM (generated text). Need to change UI
    _generatedText = data["message"] ?? "";
    notifyListeners();
  }

  void _userDocUploadHandler(Map<String, dynamic> data) async {
    // Response includes S3 pre-signed url. Upload selected file.
    final uploadUrl = data["url"];

    developer.log("Starting Document Upload");

    try {
      //  response = await http.put(Uri.parse(uploadUrl),);
      var request = http.Request('PUT', Uri.parse(uploadUrl));

      request.headers['Content-Type'] = "application/pdf";

      request.bodyBytes = _pendingFileBytes!;

      var response = await request.send();

      developer.log(response.toString());
      if (response.statusCode == 200) {
        _statusMessage = "File $_pendingFileName uploaded successfully";
        _pendingFileBytes = null;
        _pendingFileName = null;
      } else {
        _statusMessage = "File $_pendingFileName upload failed.";
        developer.log("Upload Failed - ${response.toString()}");
      }
    } catch (e) {
      _statusMessage = "Something went wrong :(";

      developer.log("Error - ${e.toString()}");
    }
    notifyListeners();
  }

  void _userInferenceHandler(Map<String, dynamic> data) {
    // Notification Respones Just show Snackbar
    Map<String, dynamic> body = jsonDecode(data["body"]);
    _statusMessage = body["message"] ?? "Inference triggered.";
    notifyListeners();
  }

  void _userInitHandler(Map<String, dynamic> data) {
    // Notification Response Just show Snackbar
    Map<String, dynamic> body = jsonDecode(data["body"]);
    _statusMessage = body['message'] ?? "Your resume was parsed.";
    if (body['fileName'] != null) {
      _uploadedFiles.add(body['fileName']);
    }
    notifyListeners();
  }

  void _fetchUserDataHandler(Map<String, dynamic> data) {
    // Data about the user's uploaded files is returned. Need to change UI
    final files = List<String>.from(data['files'] ?? []);
    _isFilesLoaded = true;
    _uploadedFiles = files;
    notifyListeners();
  }

  void disposeConnection() {
    _networkHandler.disconnect();
    super.dispose();
  }
}
