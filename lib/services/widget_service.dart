import 'package:home_widget/home_widget.dart';

class WidgetService {
  // Gom nhóm vào một class để dễ quản lý
  static Future<void> updateAndroidWidget({String? title, String? message}) async {
    // 1. Lưu dữ liệu
    await HomeWidget.saveWidgetData<String>('title', title ?? 'Tiêu đề mặc định');
    await HomeWidget.saveWidgetData<String>('message', message ?? 'Nội dung mặc định');

    // 2. Yêu cầu Android cập nhật
    await HomeWidget.updateWidget(
      name: 'MyWidgetProvider', // Phải khớp với tên Class trong Kotlin
    );
  }
}