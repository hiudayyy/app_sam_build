import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_dashboard.dart';
import 'package:nftsam/screens/dashboardnew_screen.dart';
import '/app_config.dart';
import 'package:nftsam/screens/plant_detail_screen.dart';
import 'package:nftsam/services/http_override.dart';
import 'package:nftsam/services/phantom_service.dart';
import 'package:nftsam/services/signalr_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'api/api.dart';
import 'api/api_camera.dart';
import 'firebase_options.dart';
import 'models/vuontrong/caysam_model.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Key để điều hướng từ bất cứ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final SignalRService signalRService = SignalRService();

// Hàm điều hướng (top-level)
Future<void> _navigateToPlant(String plantId) async {
  final CaySamModel? model = await API().getCaySamById(plantId);
  if (navigatorKey.currentState != null) {
    if (model != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PlantDetailScreen(
              plant: model, onBack: () => Navigator.pop(context)),
        ),
      );
    } else {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text("Lỗi")),
            body: Center(child: Text("Không tìm thấy cây với ID: $plantId")),
          ),
        ),
      );
    }
  }
}

Future<void> onNotificationTapped(NotificationResponse response) async {
  final String? plantId = response.payload;
  if (plantId != null && plantId.isNotEmpty) {
    await _navigateToPlant(plantId);
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppConfig.printEx(
      "Thông báo nhận trong nền hoặc khi app bị tắt: ${message.notification?.title}");
}

// =========================================================================
// HÀM CHẠY NGẦM CỦA WORKMANAGER (ĐÃ ĐƯỢC CHUYỂN RA NGOÀI CÙNG LÀM TOP-LEVEL)
// =========================================================================
@pragma('vm:entry-point')
void myWidgetBackgroundWorker() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Cập nhật thời tiết
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=15.111&longitude=108.017&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final daily = data['daily'];
        await HomeWidget.saveWidgetData<String>('temp_range',
            "${daily['temperature_2m_min'][0].round()}° - ${daily['temperature_2m_max'][0].round()}°");
      }

      // 2. Cập nhật API Sâm Ngọc Linh
      try {
        final statRes = await API().getDashBoardSam();
        if (statRes?.oneItem != null) {
          String total = statRes!.oneItem!.totalCaySam.toString();
          await HomeWidget.saveWidgetData<String>(
              'total_plants', "Tổng số cây: $total");
        }
        final healthRes = await API().getDashBoardSucKhoe();
        if (healthRes?.oneItem != null) {
          double healthPercentage =
              healthRes!.oneItem!.HealthPercentage?.toDouble() ?? 0.0;
          String score = (5 * (healthPercentage / 100)).toStringAsFixed(2);
          await HomeWidget.saveWidgetData<String>(
              'health_score', "Tình trạng: $score/5");
        }
      } catch (e) {
        AppConfig.printEx("Lỗi API Sâm: $e");
      }

      // 3. Gọi Native cập nhật
      await HomeWidget.updateWidget(name: 'MyWidgetProvider');
    } catch (err) {
      AppConfig.printEx("Lỗi Workmanager: $err");
    }
    return Future.value(true);
  });
}
// =========================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authProvider = AuthProvider();
  await PhantomService().initialize(authProvider);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // KHỞI TẠO WORKMANAGER BẰNG HÀM MỚI Ở TRÊN
  Workmanager().initialize(myWidgetBackgroundWorker,
      isInDebugMode: true // Khi nào đẩy lên CH Play nhớ đổi thành false
      );

  // Đăng ký Task (Lưu ý: Dù bạn để seconds: 10, Android vẫn sẽ tự động ép thành 15 phút 1 lần để tiết kiệm pin)
  Workmanager().registerPeriodicTask(
    "test_task_1",
    "update_widget_task",
    frequency: const Duration(minutes: 15),
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  HttpOverrides.global = MyHttpOverrides();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: authProvider,
        ),
      ],
      child: OverlaySupport.global(
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _pendingPlantIdFromTerminated;

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    setupLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      final String? plantId = message.data['id'];
      if (notification != null && android != null) {
        AppConfig.printEx("Nhận thông báo: ${notification.title}");
        AppConfig.printEx("ID Cây nhận được: $plantId");
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'Thông báo quan trọng',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: plantId,
        );
      }
    });

    handleInitialMessage();

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppConfig.printEx("Ứng dụng mở từ thông báo (Background)!");
      final String? plantId = message.data['id'];
      if (plantId != null && plantId.isNotEmpty) {
        _navigateToPlant(plantId);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      void checkAndNavigate() {
        if (authProvider.isAuthenticated &&
            _pendingPlantIdFromTerminated != null) {
          AppConfig.printEx(
              "Đã xác thực, đang điều hướng từ trạng thái tắt...");
          _navigateToPlant(_pendingPlantIdFromTerminated!);
          _pendingPlantIdFromTerminated = null;
        }
      }

      authProvider.addListener(checkAndNavigate);
      checkAndNavigate();
    });
  }

  void requestNotificationPermission() async {
    if (await Permission.notification.request().isGranted) {
      AppConfig.printEx("Đã cấp quyền thông báo!");
    }
  }

  void setupLocalNotifications() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    String? initialPayload;
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      initialPayload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      AppConfig.printEx(
          "App được khởi chạy từ thông báo. Payload: $initialPayload");
      if (initialPayload != null && initialPayload.isNotEmpty) {
        _pendingPlantIdFromTerminated = initialPayload;
      }
    }
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Thông báo quan trọng',
      description: 'Dùng cho các thông báo quan trọng.',
      importance: Importance.high,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: onNotificationTapped);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void handleInitialMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      AppConfig.printEx("handleInitialMesssage (FCM)");
      final String? plantId = initialMessage.data['id'];
      if (plantId != null && plantId.isNotEmpty) {
        _pendingPlantIdFromTerminated = plantId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sâm Ngọc Linh',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF16A34A),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 1,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF16A34A),
          unselectedItemColor: Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isAuthenticated) {
          return HomeScreen();
           // return DashboardGuestScreen();
        } else {
          // return LoginScreen();
          return HomeScreen();
        }
      },
    );
  }
}
