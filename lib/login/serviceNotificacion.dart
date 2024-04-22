import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Instancia del package
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Este es el método que inicializa el objeto de notificaciones
Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@drawable/logodart');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings();

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// Este es el método que muestra la notificación
Future<void> showNotificacion() async {
  const AndroidNotificationDetails androidNotificationDetails =
      AndroidNotificationDetails(
    'your channel id',
    'your channel name',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidNotificationDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    1,
    'Titulo de notificacion',
    'Esta es una notificación de prueba para mostrar en el canal. Los quiero mucho.',
    notificationDetails,
  );
}
