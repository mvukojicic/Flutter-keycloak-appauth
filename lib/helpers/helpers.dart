import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:keycloak_flutter/env/environment.dart';

parseIdToken(String idToken) {
  final List<String> parts = idToken.split(r'.');
  assert(parts.length == 3);

  return jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
}

getUserDetails(String accessToken) async {
  final String url =
      'http://${Environment.domain}/protocol/openid-connect/userinfo';
  final http.Response response = await http.get(
    Uri.parse(url),
    headers: <String, String>{'Authorization': 'Bearer $accessToken'},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to get user details');
  }
}
