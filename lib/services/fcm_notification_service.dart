import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/repositories/notification_service.dart';
import '../data/firebase/firestore_paths.dart';

/// Background isolate entry — must be top-level. Notification payloads are
/// displayed by the OS tray; no client work is needed (and no message
/// content is ever processed here, per the title-only policy).
@pragma('vm:entry-point')
Future<void> fcmBackgroundMessageHandler(RemoteMessage message) async {}

/// FCM token registration with title-only / empty body policy (PR 12),
/// plus foreground display and notification tap routing.
class FcmNotificationService implements NotificationService {
  FcmNotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    this._allowBodies = false,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _allowBodies;
  String? _lastUserId;
  String? _lastToken;

  static const _channel = AndroidNotificationChannel(
    'messages',
    'Messages',
    description: 'New message notifications',
    importance: Importance.high,
  );

  /// Wire foreground display + tap routing. Call once after Firebase init.
  ///
  /// [onTap] receives the message data map (e.g. `{'sessionId': ...}`) when
  /// the user opens a notification — from a killed, background, or
  /// foreground state.
  Future<void> configureMessageHandling({
    void Function(Map<String, Object?> data)? onTap,
  }) async {
    // iOS shows the system banner in the foreground; Android needs a local
    // notification (below) because FCM only auto-displays in background.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final sessionId = response.payload;
        if (sessionId != null && sessionId.isNotEmpty) {
          onTap?.call({'sessionId': sessionId});
        }
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((message) {
      if (defaultTargetPlatform != TargetPlatform.android) return;
      final title = message.notification?.title ?? 'New message';
      final body = _allowBodies ? message.notification?.body : null;
      _local.show(
        id: message.hashCode,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['sessionId']?.toString(),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onTap?.call(Map<String, Object?>.from(message.data));
    });
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      onTap?.call(Map<String, Object?>.from(initial.data));
    }
  }

  @override
  bool get allowNotificationBodies => _allowBodies;

  @override
  Future<void> setAllowNotificationBodies(bool allow) async {
    _allowBodies = allow;
  }

  @override
  Future<void> registerToken(String userId) async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      _lastUserId = userId;
      _lastToken = token;
      final ref = _db.collection(FirestorePaths.fcmTokens(userId)).doc(token);
      await ref.set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'allowBodies': _allowBodies,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM: registered token for $userId (bodies=$_allowBodies)');
    } catch (e, st) {
      debugPrint('FCM register failed: $e\n$st');
    }
  }

  @override
  Future<void> clearToken(String userId) async {
    try {
      if (_lastToken != null && _lastUserId == userId) {
        await _db
            .collection(FirestorePaths.fcmTokens(userId))
            .doc(_lastToken)
            .delete();
      } else {
        final snap =
            await _db.collection(FirestorePaths.fcmTokens(userId)).get();
        for (final d in snap.docs) {
          await d.reference.delete();
        }
      }
      _lastToken = null;
      _lastUserId = null;
    } catch (e, st) {
      debugPrint('FCM clear failed: $e\n$st');
    }
  }
}
