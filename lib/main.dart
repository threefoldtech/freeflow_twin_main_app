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


const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
  requestAlertPermission: true,
  requestBadgePermission: true,
  requestSoundPermission: true,
);


  final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

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

  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    print('INITIALZE MESSAGE');
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
          ));
    }
  });

  String? identifier = await FirebaseMessaging.instance.getToken();

  print("THIS IS THE IDENTIFIER");
  print(await FirebaseMessaging.instance.getAPNSToken());

  if (identifier == null || identifier == '') identifier = '';
  await setIdentifierInStorage(identifier);

  runApp(LandingScreen());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

Future<void> foregroundClick(NotificationResponse message) async {
  String username = await getNameInStorage();

  String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
  print(rootUrl);

  String messageUrl = rootUrl + '/whisper';
  Uri newUrl = Uri.parse(messageUrl);

  URLRequest r = new URLRequest(url: newUrl);

  await webView.loadUrl(urlRequest: r);
}

Future<void> backgroundClick(NotificationResponse message) async {
  print('COMING HERE');

  String username = await getNameInStorage();

  String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();
  print(rootUrl);

  String messageUrl = rootUrl + '/whisper';
  Uri newUrl = Uri.parse(messageUrl);

  URLRequest r = new URLRequest(url: newUrl);

  new Future.delayed(const Duration(milliseconds: 5000), () async {
    await webView.loadUrl(urlRequest: r);
  });
}

class LandingScreen extends StatefulWidget with WidgetsBindingObserver {
  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String username = '';

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
