import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// QUAN TRỌNG: Import thư viện mới (signalr_core)
import 'package:signalr_core/signalr_core.dart';
import 'dart:async';
import '../models/kttoken.dart';
import '../models/vuontrong/sensor_model.dart';

import '/app_config.dart';

class SignalRService {
  // --- (1) SINGLETON (Giữ nguyên) ---
  SignalRService._internal();
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() {
    return _instance;
  }
  // --- KẾT THÚC SINGLETON ---

  HubConnection? hubConnection;
  final String baseUrl = "https://samnft.vecoi.com";
  final String hubName = "NotificationHub";

  final StreamController<Map<String, dynamic>> _messageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  final StreamController<SensorDeviceModel> _sensorStreamController =
      StreamController<SensorDeviceModel>.broadcast();
  Stream<SensorDeviceModel> get sensorStream => _sensorStreamController.stream;
  Stream<Map<String, dynamic>> get messageStream =>
      _messageStreamController.stream;

  bool _isRetryScheduled = false;

  Future<void> initSignalR() async {
    if (hubConnection != null &&
        hubConnection!.state == HubConnectionState.connected) {
      AppConfig.printEx("SignalR (CORE) đã được kết nối trước đó.");
      return;
    }
    if (_isRetryScheduled) {
      AppConfig.printEx("Đang trong lịch kết nối lại (CORE), vui lòng đợi...");
      return;
    }
    AppConfig.printEx("Đang tạo HubConnection (CORE) mới...");
    final prefs = await SharedPreferences.getInstance();
    final tokenString = prefs.getString("ginseng_user");
    if (tokenString == null || tokenString.isEmpty) {
      AppConfig.printEx(
          "❌ LỖI SIGNALR (CORE): Không tìm thấy 'ginseng_user'. Sẽ thử lại sau 10s.");
      _handleConnectionError("Token not found");
      return;
    }
    final String bearerToken;
    try {
      final Map<String, dynamic> json = jsonDecode(tokenString);
      final user = Kttoken.fromJson(json);
      if (user.authenticateToken.isEmpty) {
        AppConfig.printEx("❌ LỖI SIGNALR (CORE): 'authenticateToken' bị rỗng");
        return;
      }
      bearerToken = user.authenticateToken;
    } catch (e) {
      AppConfig.printEx(
          "❌ LỖI GIẢI MÃ JSON TOKEN (CORE): $e. Sẽ thử lại sau 10s.");
      _handleConnectionError("Lỗi giải mã JSON");
      return;
    }
    final String urlWithToken =
        "$baseUrl/$hubName?AuthenticateToken=$bearerToken";

    AppConfig.printEx("🔑 Đang kết nối SignalR");
    hubConnection = HubConnectionBuilder()
        // (1) GỌI URL ĐÃ CHỨA TOKEN
        .withUrl(
      urlWithToken,
      HttpConnectionOptions(
        customHeaders: {
          'referrer': '',
        },
        transport: HttpTransportType.longPolling,
      ),
    )
        .withAutomaticReconnect(
            [1000, 2000, 4000, 8000, 15000, 30000, 60000]).build();
    hubConnection?.on("ReceiveNotification", (arguments) {
      AppConfig.printEx("✅ ĐÃ NHẬN ĐƯỢC THÔNG BÁO noti   (TỪ SERVICE):");
      if (arguments != null && arguments.isNotEmpty) {
        var messageObject = arguments[0] as Map<String, dynamic>;
        _messageStreamController.add(messageObject);
      }
    });
    hubConnection?.on("ReceiveSensorReading", (arguments) {
      if (arguments != null && arguments.isNotEmpty) {
        var messageList = arguments as List<dynamic>;
        try {
          SensorDeviceModel sensorDataList = new SensorDeviceModel(deviceId: 0);
          for (var item in messageList) {
            var messageObject = item as Map<String, dynamic>;
            final SensorDeviceModel deviceData =
                SensorDeviceModel.fromJson(messageObject);
            sensorDataList = deviceData;
          }
          _sensorStreamController.add(sensorDataList);
        } catch (e) {
          AppConfig.printEx("❌ Lỗi parse List<SensorDeviceModel>: $e");
        }
      }
    });

    hubConnection?.onclose((error) {
      AppConfig.printEx("!!! KẾT NỐI BỊ ĐÓNG (SERVICE): $error");
      _isRetryScheduled = false;
      initSignalR();
    });

    try {
      if (hubConnection?.state == HubConnectionState.disconnected) {
        AppConfig.printEx(
            "... Chuẩn bị gọi hubConnection.start() (dùng 'signalr_core')...");
        await hubConnection?.start();
        AppConfig.printEx("✅✅✅ ĐÃ KẾT NỐI SIGNALR (CORE) THÀNH CÔNG ✅✅✅");
        _isRetryScheduled = false; // Thành công, xóa cờ
      }
    } catch (e) {
      AppConfig.printEx("❌ LỖI KHI KẾT NỐI (CORE SERVICE): $e");
      _handleConnectionError(e);
    }
  }

  void _handleConnectionError(Object e) {
    if (_isRetryScheduled) return;
    _isRetryScheduled = true;
    AppConfig.printEx("... Sẽ thử kết nối lại SignalR sau 10 giây ...");
    Future.delayed(Duration(seconds: 10), () {
      AppConfig.printEx("Đang thử kết nối lại SignalR...");
      _isRetryScheduled = false;
      initSignalR();
    });
  }

  void disconnect() {
    _isRetryScheduled = false;
    if (hubConnection != null) {
      hubConnection!.stop();
      hubConnection = null;
      AppConfig.printEx("SignalR ĐÃ NGẮT KẾT NỐI (do đăng xuất).");
    }
  }

  void dispose() {
    hubConnection!.stop();
  }
}
