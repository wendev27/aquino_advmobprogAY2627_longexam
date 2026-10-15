import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String _userKey = 'authenticated_user';

  static final Map<int, User> _userCache = <int, User>{};

  Future<User> loginUser(String username, String password) async {
    final http.Response response = await http
        .post(
          Uri.parse('$kDummyJsonBaseUrl/auth/login'),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, String>{
            'username': username,
            'password': password,
            'expiresInMins': '60',
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Incorrect username or password.');
    }
    final dynamic body = jsonDecode(response.body);
    if (body is! Map<String, dynamic>) {
      throw Exception('Invalid sign-in response.');
    }
    final User user = User.fromJson(body);
    if (user.id == 0) throw Exception('The account did not include a user ID.');
    await saveUser(user);
    _userCache[user.id] = user;
    return user;
  }

  Future<void> saveUser(User user) async =>
      (await SharedPreferences.getInstance()).setString(
        _userKey,
        jsonEncode(user.toJson()),
      );

  Future<User?> getUser() async {
    final String? value = (await SharedPreferences.getInstance()).getString(
      _userKey,
    );
    if (value == null) return null;
    try {
      final dynamic json = jsonDecode(value);
      return json is Map<String, dynamic> ? User.fromJson(json) : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async => (await getUser()) != null;

  Future<void> logout() async =>
      (await SharedPreferences.getInstance()).remove(_userKey);

  Future<User?> getUserById(int id) async {
    if (id == 0) return null;
    if (_userCache.containsKey(id)) return _userCache[id];
    try {
      final http.Response response = await http
          .get(Uri.parse('$kDummyJsonBaseUrl/users/$id'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final dynamic body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final User user = User.fromJson(body);
      _userCache[id] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<List<User>> getUsers({int limit = kStoriesLimit, int skip = 0}) async {
    final Uri uri = Uri.parse(
      '$kDummyJsonBaseUrl/users?limit=$limit&skip=$skip',
    );
    final http.Response response = await http
        .get(uri)
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List usersJson = data['users'] ?? <dynamic>[];
    final List<User> users = usersJson
        .map((dynamic u) => User.fromJson(u))
        .toList();
    for (final User user in users) {
      _userCache[user.id] = user;
    }
    return users;
  }
}
