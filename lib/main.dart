import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:freeflow/app_config.dart';
import 'package:freeflow/classes/notification.dart';
import 'package:freeflow/helpers/shared_preference_data.dart';
import 'package:freeflow/screens/webview_screen.dart';
import 'helpers/api_helpers.dart';
import 'helpers/globals.dart';
import 'screens/enter_username_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationController().initializeFirebase();

  String? identifier = await FirebaseMessaging.instance.getToken();

  if (identifier == null || identifier == '') identifier = '';
  await setIdentifierInStorage(identifier);

  String versionStored = await getFreeFlowVersionInStorage();
  String liveVersion = await getCurrentFreeFlowVersion();

  print("CURRENT VERSION: $liveVersion");
  print("STORED VERSION: $versionStored");

  if (versionStored != liveVersion) {
    Globals().clearWebViewCache = true;
    await setFreeFlowVersionInStorage(liveVersion);
  }

  runApp(LandingScreen());
}

class LandingScreen extends StatefulWidget {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with WidgetsBindingObserver {
  String username = '';

  Uri? lastUrl;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getUsername();
    });
  }

  Future<void> getUsername() async {
    String? user = await getNameInStorage();
    username = user;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'FreeFlow',
        debugShowCheckedModeBanner: false,
        home: username != ''
            ? WebViewScreen(url: 'https://' + username + AppConfig().freeFlowUrl())
            : EnterUsernameScreen());
  }
}
