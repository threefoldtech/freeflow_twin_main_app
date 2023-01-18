import 'package:shared_preferences/shared_preferences.dart';

Future<String> getNameInStorage() async {
  final prefs = await SharedPreferences.getInstance();

  String? name = prefs.getString('name');

  if (name == null) {
    return '';
  }

  return name;
}

Future<void> setNameInStorage(String username) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('name', username);
}



Future<void> setIdentifierInStorage(String identifier) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('identifier', identifier);
}

Future<String> getIdentifierInStorage() async {
  final prefs = await SharedPreferences.getInstance();

  String? identifier = prefs.getString('identifier');

  if (identifier == null) {
    return '';
  }

  return identifier;
}