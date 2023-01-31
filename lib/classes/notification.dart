import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_config.dart';
import '../firebase_options.dart';
import '../globals/globals.dart';
import '../helpers/globals.dart';
import '../helpers/globals.dart';
import '../helpers/shared_preference_data.dart';

class NotificationController {
  Future<void> askPermissionsIfNeeded() async {
    await Permission.notification.isDenied.then((value) {
      if (value) {
        Permission.notification.request();
      }
    });

    FirebaseMessaging.instance.requestPermission();

    await Permission.microphone.request();
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await askPermissionsIfNeeded();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    Globals().flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_launcher_notification');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    await Globals().flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: foregroundClick, onDidReceiveBackgroundNotificationResponse: backgroundClick);

    await Globals()
        .flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // When the app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      print("Initial message clicked");

      if (message?.data == null) return;

      new Future.delayed(const Duration(milliseconds: 500), () async {
        String username = await getNameInStorage();

        String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

        String messageUrl = rootUrl + '/whisper';
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
        Globals().flutterLocalNotificationsPlugin.show(
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
  }
}

// When the app is in the foreground
Future<void> foregroundClick(NotificationResponse message) async {
  print('Foreground notification clicked');


  String username = await getNameInStorage();

  String rootUrl = 'https://' + username + AppConfig().freeFlowUrl();

  String messageUrl = rootUrl + '/whisper';
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

    String messageUrl = rootUrl + '/whisper';
    Uri newUrl = Uri.parse(messageUrl);

    URLRequest r = new URLRequest(url: newUrl);

    await webView.loadUrl(urlRequest: r);
  });
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}
