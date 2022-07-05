import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:keycloak_flutter/env/environment.dart';
import 'package:keycloak_flutter/helpers/helpers.dart';
import 'package:keycloak_flutter/widgets/login_view.dart';
import 'package:keycloak_flutter/widgets/profile_view.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final FlutterAppAuth appAuth = const FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool isBusy = false;
  bool isLoggedIn = false;
  String? errorMessage;
  late String name;
  late String? picture;
  late String? idTokenUser;

  @override
  void initState() {
    initAction();
    super.initState();
  }

  Future<void> loginAction() async {
    setState(() {
      isBusy = true;
      errorMessage = '';
    });

    try {
      final AuthorizationTokenResponse? result =
          await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Environment.clientId!,
          Environment.redirectUri!,
          discoveryUrl: 'example/realm-name',
          clientSecret: 'client-secret',
          scopes: ['openid', 'profile', 'email', 'offline_access'],
          promptValues: ['login'],
        ),
      );

      final profile = await getUserDetails(result!.accessToken!);
      setState(() {
        isBusy = false;
        isLoggedIn = true;
        name = profile!['name'];
        picture = profile!['picture'];
        idTokenUser = result.idToken;
      });

      await secureStorage.write(
          key: 'refresh_token', value: result.refreshToken);
    } catch (e, s) {
      print('login error: $e - stack: $s');
      setState(() {
        isBusy = false;
        isLoggedIn = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> logoutAction() async {
    await secureStorage.delete(key: 'refresh_token');

    final request = EndSessionRequest(
      idTokenHint: idTokenUser,
      postLogoutRedirectUrl: Environment.redirectUri,
    );
    appAuth.endSession(request);

    setState(() {
      isLoggedIn = false;
      isBusy = false;
      name = '';
    });
  }

  Future<void> initAction() async {
    final String? storedRefreshToken =
        await secureStorage.read(key: 'refresh_token');

    if (storedRefreshToken == null) return;

    setState(() {
      isBusy = true;
    });

    try {
      final TokenResponse? response = await appAuth.token(
        TokenRequest(
          Environment.clientId!,
          Environment.redirectUri!,
          clientSecret: 'client-secret',
          discoveryUrl: 'example/realm-name',
          refreshToken: storedRefreshToken,
        ),
      );

      final profile = await getUserDetails(response!.accessToken!);

      await secureStorage.write(
          key: 'refresh_token', value: response.refreshToken);

      setState(() {
        isBusy = false;
        isLoggedIn = true;
        name = profile['name'].toString();
        picture = profile['picture'] as String?;
      });
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: isBusy
              ? const CircularProgressIndicator()
              : isLoggedIn
                  ? Profile(logoutAction, name, picture)
                  : Login(loginAction, errorMessage),
        ),
      ],
    );
  }
}
