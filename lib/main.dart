import 'dart:convert';
import 'dart:math';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:freeflow/app_config.dart';
import 'package:freeflow/classes/notifications.dart';
import 'package:freeflow/globals/globals.dart';
import 'package:freeflow/helpers/shared_preference_data.dart';
import 'package:freeflow/screens/webview_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'helpers/api_helpers.dart';
import 'helpers/globals.dart';
import 'screens/enter_username_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationController.initializeLocalNotifications();
  NotificationController.startListeningNotificationEvents();


  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Permission.microphone.request();
  FirebaseMessaging.instance.requestPermission();
  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  // When the app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message?.data == null) return;

    new Future.delayed(const Duration(milliseconds: 500), () async {
      String username = await getNameInStorage();

      String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

      String? target = message?.data['sender'];
      print('This is the target: ');
      print(target);

      String messageUrl = rootUrl + '/whisper/$target';
      Uri newUrl = Uri.parse(messageUrl);

      URLRequest r = new URLRequest(url: newUrl);

      print("Redirecting to: ");
      print(messageUrl);

      await webView.loadUrl(urlRequest: r);
    });
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null) {
      NotificationController.createNewNotification(notification.title!);
    }
  });

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

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();


  final res = await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: Random().nextInt(1000000),
      channelKey: 'channel_name',
      title: 'Hello!',
      body: 'World!',
      notificationLayout: NotificationLayout.Default,
    ),
  );

  // print("Handling a background message: ${message.messageId}");
  // NotificationController.createNewNotification(message.data['sender']);
}

// // When the app is in the foreground
// Future<void> foregroundClick(NotificationResponse message) async {
//   print('Foreground notification clicked');
//
//   String username = await getNameInStorage();
//
//   String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
//
//   dynamic target = jsonDecode(message.payload!)['sender'];
//
//   String messageUrl = rootUrl + '/whisper/$target';
//   Uri newUrl = Uri.parse(messageUrl);
//
//   URLRequest r = new URLRequest(url: newUrl);
//
//   await webView.loadUrl(urlRequest: r);
// }
//
// // When the app is in the background
// Future<void> backgroundClick(NotificationResponse message) async {
//   print('Background notification clicked');
//
//   new Future.delayed(const Duration(milliseconds: 500), () async {
//     String username = await getNameInStorage();
//
//     String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
//
//     dynamic target = jsonDecode(message.payload!)['sender'];
//
//     String messageUrl = rootUrl + '/whisper/$target';
//     Uri newUrl = Uri.parse(messageUrl);
//
//     URLRequest r = new URLRequest(url: newUrl);
//
//     await webView.loadUrl(urlRequest: r);
//   });
// }

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
    print("APP LIFE CYCLE STATE DID CHANGE");
    print(state);
    //
    // Uri? currentUrl = await webView.getUrl();
    // String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
    //
    // if (state == AppLifecycleState.paused && currentUrl.toString().startsWith(rootUrl)) {
    //   setState(() {
    //     lastUrl = currentUrl;
    //   });
    //
    //   Uri newUrl = Uri.parse(rootUrl);
    //
    //   URLRequest r = new URLRequest(url: newUrl);
    //
    //   await webView.loadUrl(urlRequest: r);
    // }
    //
    // if (state == AppLifecycleState.resumed && currentUrl.toString().startsWith(rootUrl)) {
    //   if (lastUrl != null) {
    //     URLRequest r = new URLRequest(url: lastUrl);
    //
    //     await webView.loadUrl(urlRequest: r);
    //   }
    // }
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
    WidgetsBinding.instance.removeObserver(this);
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
