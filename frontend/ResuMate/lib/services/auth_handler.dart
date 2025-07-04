import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import 'package:ResuMate/utils/shared_pref_storage.dart';

class AuthHandler {
  late CognitoUserPool _userPool;
  AuthHandler({required String userPoolId, required String appClientId}) {
    _userPool =
        CognitoUserPool(userPoolId, appClientId, storage: SharedPrefStorage());
  }

  Future<CognitoUser?> getUser() async {
    return await _userPool.getCurrentUser();
  }

  Future<String?> getToken() async {
    return (await (await _userPool.getCurrentUser())?.getSession())
        ?.getAccessToken()
        .jwtToken;
  }

  Future<String?> getUserId() async {
    String? idToken = await getToken();
    if (idToken == null) {
      return null;
    }
    final payload = idToken.split('.')[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));

    final claims = json.decode(decoded);

    return claims['sub']; // This is the Cognito userId
  }

  String getUserIdFromIdToken(String idToken) {
    final payload = idToken.split('.')[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));

    final claims = json.decode(decoded);

    return claims['sub'];
  }

  Future<bool> logInUser(
      {required String email, required String password}) async {
    final cognitoUser = CognitoUser(email, _userPool);
    final authDetails = AuthenticationDetails(
      username: email,
      password: password,
    );
    // CognitoUserSession? session;
    try {
      var session = await cognitoUser.authenticateUser(authDetails);

      developer.log("User Authenticated - ${session?.accessToken.jwtToken}");
      return true;
    } on CognitoUserNewPasswordRequiredException catch (e) {
      // handle New Password challenge
      developer.log(e.toString());
    } on CognitoUserMfaRequiredException catch (e) {
      // handle SMS_MFA challenge
      developer.log(e.toString());
    } on CognitoUserSelectMfaTypeException catch (e) {
      // handle SELECT_MFA_TYPE challenge
      developer.log(e.toString());
    } on CognitoUserMfaSetupException catch (e) {
      // handle MFA_SETUP challenge
      developer.log(e.toString());
    } on CognitoUserTotpRequiredException catch (e) {
      // handle SOFTWARE_TOKEN_MFA challenge
      developer.log(e.toString());
    } on CognitoUserEmailOtpRequiredException catch (e) {
      // handle EMAIL_OTP challenge
      developer.log(e.toString());
    } on CognitoUserCustomChallengeException catch (e) {
      // handle CUSTOM_CHALLENGE challenge
      developer.log(e.toString());
    } on CognitoUserConfirmationNecessaryException catch (e) {
      // handle User Confirmation Necessary
      developer.log(e.toString());
    } on CognitoClientException catch (e) {
      // handle Wrong Username and Password and Cognito Client
      developer.log(e.toString());
    } catch (e) {
      developer.log(e.toString());
    }
    return false;
  }

  Future<void> logOut() async {
    CognitoUser? user = await _userPool.getCurrentUser();
    if (user != null) {
      await user.signOut();
    }
  }

  Future<bool> signUpUser(
      {required String email,
      required String password,
      required String name}) async {
    var userAttributes = [AttributeArg(name: "given_name", value: name)];
    try {
      var data = await _userPool.signUp(email, password,
          userAttributes: userAttributes);
      developer.log("AuthHandler - ${data.toString()}");
      return true;
    } catch (e) {
      developer.log("AuthHandler - ${e.toString()}");
    }
    return false;
  }
}
