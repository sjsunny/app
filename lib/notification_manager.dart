//import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class NotificationHandler {
  static Future<void> showNotification({
    int id = 0,
    String title = 'Notification Title',
    String body = 'Notification Body',
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id', // Change this to your channel ID
      'your_channel_name', // Change this to your channel name
      'your_channel_description', // Change this to your channel description
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);


    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
