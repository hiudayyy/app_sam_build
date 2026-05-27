import 'package:flutter/foundation.dart';

class AppConfig {
  /// Biến kiểm soát việc in log ra console.
  /// Thiết lập thành false khi đóng gói ứng dụng (Release mode).
  static const bool isPrint = kDebugMode;

  /// Hàm in log tập trung. Thay thế cho AppConfig.printEx() hoặc debugAppConfig.printEx() mặc định.
  static void printEx(dynamic msg) {
    if (isPrint) {
      // Sử dụng debugPrint để đảm bảo log không bị cắt bớt trên một số thiết bị Android
      print("sam: " + msg.toString());
    }
  }
}
