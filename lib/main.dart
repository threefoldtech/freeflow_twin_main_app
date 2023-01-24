import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freeflow/app_config.dart';
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  FirebaseMessaging.instance.requestPermission();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_launcher_notification');

  const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onDidReceiveNotificationResponse: foregroundClick, onDidReceiveBackgroundNotificationResponse: backgroundClick);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );


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
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              playSound: true,
              // icon: '@drawable/ic_launcher_notification',
              // styleInformation:
            ),
          ),
          payload: jsonEncode(message.data));
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
  print("Handling a background message: ${message.messageId}");
}

// When the app is in the foreground
Future<void> foregroundClick(NotificationResponse message) async {
  print('Foreground notification clicked');

  String username = await getNameInStorage();

  String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

  dynamic target = jsonDecode(message.payload!)['sender'];

  String messageUrl = rootUrl + '/whisper/$target';
  Uri newUrl = Uri.parse(messageUrl);

  URLRequest r = new URLRequest(url: newUrl);

  await webView.loadUrl(urlRequest: r);
}

// When the app is in the background
Future<void> backgroundClick(NotificationResponse message) async {
  print('Background notification clicked');

  new Future.delayed(const Duration(milliseconds: 500), () async {
    String username = await getNameInStorage();

    String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

    dynamic target = jsonDecode(message.payload!)['sender'];

    String messageUrl = rootUrl + '/whisper/$target';
    Uri newUrl = Uri.parse(messageUrl);

    URLRequest r = new URLRequest(url: newUrl);

    await webView.loadUrl(urlRequest: r);
  });
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
    if (state == AppLifecycleState.paused) {
      Uri? currentUrl = await webView.getUrl();
      setState(() {
        lastUrl = currentUrl;
      });

      String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
      Uri newUrl = Uri.parse(rootUrl);

      URLRequest r = new URLRequest(url: newUrl);

      await webView.loadUrl(urlRequest: r);
    }

    if (state == AppLifecycleState.resumed) {
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
