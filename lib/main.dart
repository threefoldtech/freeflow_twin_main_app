import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:freeflow/app_config.dart';
import 'package:freeflow/classes/notification.dart';
import 'package:freeflow/globals/globals.dart';
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

  AppLifecycleState? _notification;

  Uri? lastUrl;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    Uri? currentUrl = await webView.getUrl();
    String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

    if (state == AppLifecycleState.paused && currentUrl.toString().startsWith(rootUrl)) {
      setState(() {
        lastUrl = currentUrl;
      });

      Uri newUrl = Uri.parse(rootUrl);

      URLRequest r = new URLRequest(url: newUrl);

      await webView.loadUrl(urlRequest: r);
    }

    if (state == AppLifecycleState.resumed && currentUrl.toString().startsWith(rootUrl)) {
      if (lastUrl != null) {
        URLRequest r = new URLRequest(url: lastUrl);

        await webView.loadUrl(urlRequest: r);
      }
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getUsername();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
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
