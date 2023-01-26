import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

extension StringCasingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';

  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');
}

class NotificationController {
  static ReceivedAction? initialAction;

  ///  *********************************************
  ///     NOTIFICATION EVENTS LISTENER
  ///  *********************************************
  ///  Notifications events are only delivered after call this method
  static Future<void> startListeningNotificationEvents() async {
    print("Initialized listeners");
    AwesomeNotifications().setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  ///  *********************************************
  ///     NOTIFICATION EVENTS
  ///  *********************************************
  ///
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(ReceivedAction receivedAction) async {
    print("RECEIVED ACTION");
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // For background actions, you must hold the execution until the end
      print('Message sent via notification input: "${receivedAction.buttonKeyInput}"');
    }
  }

  ///  *********************************************
  ///     INITIALIZATIONS
  ///  *********************************************
  ///@drawable/ic_launcher_notification
  static Future<void> initializeLocalNotifications() async {
    await AwesomeNotifications().initialize(
        'resource://drawable/ic_launcher_notification',
        [
          NotificationChannel(
              channelKey: 'high_importance_channel',
              channelName: 'high_importance_channel',
              channelDescription: 'high_importance_channel',
              playSound: true,
              onlyAlertOnce: false,
              groupAlertBehavior: GroupAlertBehavior.Children,
              importance: NotificationImportance.High,
              defaultPrivacy: NotificationPrivacy.Private,
              defaultColor: Colors.white,
              ledColor: Colors.white)
        ],
        debug: true);

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications().getInitialNotificationAction(removeFromActionEvents: false);
  }

  ///  *********************************************
  ///     NOTIFICATION CREATION METHODS
  ///  *********************************************
  ///
  static Future<void> createNewNotification(String name) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
          id: 132565,
          groupKey: name,
          channelKey: 'high_importance_channel',
          summary: '',
          title: name.toCapitalized(),
          roundedLargeIcon: true,
          roundedBigPicture: true,
          body: 'has sent you a message',
          notificationLayout: NotificationLayout.MessagingGroup,
          category: NotificationCategory.Transport),
      // actionButtons: [
      //   NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
      //   NotificationActionButton(
      //       key: 'REPLY', label: 'Reply Message', requireInputText: true, actionType: ActionType.SilentAction),
      //   NotificationActionButton(
      //       key: 'DISMISS', label: 'Dismiss', actionType: ActionType.DismissAction, isDangerousOption: true)
      // ]
    );
  }
}
