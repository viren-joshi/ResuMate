import 'dart:convert';
import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefStorage extends CognitoStorage {
  final String prefix;

  SharedPrefStorage({this.prefix = 'cognito:'});

  @override
  Future<void> setItem(String key, value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$prefix$key', json.encode(value));
  }

  @override
  Future<dynamic> getItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final item = prefs.getString('$prefix$key');
    return item != null ? json.decode(item) : null;
  }

  @override
  Future<void> removeItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$prefix$key');
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(prefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
