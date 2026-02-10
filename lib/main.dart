
import 'dart:io';

import 'package:nftsam/api/api_caysam.dart';
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
import 'api/api.dart';
import 'firebase_options.dart';
import 'models/vuontrong/caysam_model.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// === SỬA LỖI 1: DI CHUYỂN TẤT CẢ RA NGOÀI CLASS ===

// Key để điều hướng từ bất cứ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final SignalRService signalRService = SignalRService();
// Hàm điều hướng (giờ là top-level)
Future<void> _navigateToPlant(String plantId) async {
  // Logic này được chuyển từ onNotificationTapped
  final CaySamModel? model = await API().getCaySamById(plantId);
  if (navigatorKey.currentState != null) {
    if (model != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PlantDetailScreen(plant: model, onBack: () => Navigator.pop(context)),
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
  final String? plantId = response.payload; // Lấy ID cây từ payload
  if (plantId != null && plantId.isNotEmpty) {
    // Chỉ cần gọi hàm helper (giờ cũng là top-level)
    await _navigateToPlant(plantId);
  }
}


Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(
    "Thông báo nhận trong nền hoặc khi app bị tắt: ${message.notification?.title}",
  );
}

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
        child: MyApp(),
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

  // === SỬA LỖI 2: XÓA CÁC BIẾN VÀ HÀM ĐÃ DI CHUYỂN RA NGOÀI ===
  // (Đã xóa)

  // Biến này vẫn ở lại vì nó là state của app
  String? _pendingPlantIdFromTerminated;

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    setupLocalNotifications(); // Sẽ tự động dùng hàm top-level

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      final String? plantId = message.data['id'];
      if (notification != null && android != null) {
        print("Nhận thông báo: ${notification.title}");
        print("ID Cây nhận được: $plantId");
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
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
      print("Ứng dụng mở từ thông báo (Background)!");
      final String? plantId = message.data['id']; // Lấy ID từ data
      if (plantId != null && plantId.isNotEmpty) {
        _navigateToPlant(plantId); // Gọi hàm top-level
      }
    });

    // Logic chờ Auth này đã đúng, nó sẽ gọi hàm _navigateToPlant (top-level)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      void checkAndNavigate() {
        if (authProvider.isAuthenticated && _pendingPlantIdFromTerminated != null) {
          print("Đã xác thực, đang điều hướng từ trạng thái tắt...");
          _navigateToPlant(_pendingPlantIdFromTerminated!); // Gọi hàm top-level
          _pendingPlantIdFromTerminated = null;
        }
      }
      authProvider.addListener(checkAndNavigate);
      checkAndNavigate();
    });
  }

  void requestNotificationPermission() async {
    if (await Permission.notification.request().isGranted) {
      print("Đã cấp quyền thông báo!");
    }
  }

  void setupLocalNotifications() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    String? initialPayload;
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      initialPayload = notificationAppLaunchDetails!.notificationResponse?.payload;
      print("App được khởi chạy từ thông báo. Payload: $initialPayload");
      if (initialPayload != null && initialPayload.isNotEmpty) {
        _pendingPlantIdFromTerminated = initialPayload; // Lưu ID chờ
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

    // === SỬA LỖI 3: THÊM LẠI THAM SỐ BỊ THIẾU ===
    // Bạn đã quên "onDidReceiveBackgroundNotificationResponse"
    await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
        // THÊM DÒNG NÀY:
        onDidReceiveBackgroundNotificationResponse: onNotificationTapped
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void handleInitialMessage() async {
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("handleInitialMesssage (FCM)");
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
      // === SỬA LỖI 4: GÁN KEY TOP-LEVEL VÀO ĐÂY ===
      navigatorKey: navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: Color(0xFF16A34A),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
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
      home: AuthWrapper(),
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
        } else {
          return LoginScreen();
        }
      },
    );
  }
}