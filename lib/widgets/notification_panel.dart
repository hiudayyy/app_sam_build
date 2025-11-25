import 'dart:async';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/api/api_thongbao.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api.dart';
import '../models/message_enum.dart';
import '../models/thongbao_model.dart';
import '../screens/plant_detail_screen.dart';


class NotificationPanel extends StatefulWidget {
  const NotificationPanel({Key? key}) : super(key: key);

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel>
    with SingleTickerProviderStateMixin {
  List<ThongBaoModel> _notifications = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;
  bool _hasMore = true;
  int _skip = 0;
  final int _pageSize = 20;
  String? _apiError;

  final ScrollController _scrollController = ScrollController();
  String _currentFilter = 'all'; // 'all', 'unread'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _fetchNotifications();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (_skip == 0) _isInitialLoading = true;
      _apiError = null;
    });

    try {
      List<String>? searchByParams;
      final List<String> orderByParams = ["NgayKhoiTao desc"];
      if (_currentFilter == 'unread') {
        searchByParams = ["seen equals false"];
      }
      final response = await API().listThongBao(
        status: 'TatCa',
        skip: _skip,
        top: _pageSize,
        orderBy: orderByParams,
        searchBy: searchByParams,
      );

      if (mounted && response != null && response.items != null) {
        final newItems = response.items!;
        setState(() {
          _notifications.addAll(newItems);
          _notifications.sort((a, b) {
            if (!a.seen && b.seen) return -1;
            if (a.seen && !b.seen) return 1;
            final dateA = DateTime.tryParse(a.ngayKhoiTao) ?? DateTime(0);
            final dateB = DateTime.tryParse(b.ngayKhoiTao) ?? DateTime(0);
            return dateB.compareTo(dateA);
          });

          _skip += _pageSize;
          if (newItems.length < _pageSize) _hasMore = false;
        });
      } else if (mounted) {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _apiError = "Đã xảy ra lỗi khi tải dữ liệu.");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    final notification = _notifications[index];
    if (!notification.seen) {
      final success = await API().seenThongBao(id);
      if (success && mounted) {
        setState(() {
          _notifications[index] = ThongBaoModel(
            id: notification.id,
            taiKhoanId: notification.taiKhoanId,
            caySamId: notification.caySamId,
            tieuDe: notification.tieuDe,
            noiDung: notification.noiDung,
            ngayKhoiTao: notification.ngayKhoiTao,
            seen: true,
            htTaiKhoan: notification.htTaiKhoan,
          );
          _notifications.sort((a, b) {
            if (!a.seen && b.seen) return -1;
            if (a.seen && !b.seen) return 1;
            final dateA = DateTime.tryParse(a.ngayKhoiTao) ?? DateTime(0);
            final dateB = DateTime.tryParse(b.ngayKhoiTao) ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
        });
      }
    }
    final caySamId = notification.caySamId;
    if (caySamId != null && caySamId.isNotEmpty) {
      _navigateToPlantDetail(caySamId);
    }
  }
  // ( ... bên dưới hàm _navigateToPlantDetail ... )

  // <<< THÊM MỚI: Hàm đánh dấu tất cả là đã đọc
  Future<void> _markAllAsRead() async {
    // Kiểm tra xem có gì để đánh dấu không
    if (!_notifications.any((n) => !n.seen)) return;

    showLoadingDialog(context, message: 'Đang cập nhật...');

    try {
      final success = await API().seenThongBaoAll();

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (success?.messCode == MessCode.IsOK) {
        setState(() {
          // Cập nhật tất cả item trong danh sách sang
          // trạng thái 'seen: true'
          _notifications = _notifications.map((notification) {
            if (notification.seen) return notification; // Giữ nguyên nếu đã đọc

            // Tạo lại model với seen: true
            return ThongBaoModel(
              id: notification.id,
              taiKhoanId: notification.taiKhoanId,
              caySamId: notification.caySamId,
              tieuDe: notification.tieuDe,
              noiDung: notification.noiDung,
              ngayKhoiTao: notification.ngayKhoiTao,
              seen: true, // <<< Đây là thay đổi
              htTaiKhoan: notification.htTaiKhoan,
            );
          }).toList();
          _notifications.sort((a, b) {
            if (!a.seen && b.seen) return -1;
            if (a.seen && !b.seen) return 1;
            final dateA = DateTime.tryParse(a.ngayKhoiTao) ?? DateTime(0);
            final dateB = DateTime.tryParse(b.ngayKhoiTao) ?? DateTime(0);
            return dateB.compareTo(dateA);
          });
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật. Vui lòng thử lại.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ( ... hàm _getVisualsForNotification ... )
  Future<void> _navigateToPlantDetail(String caySamId) async {
    showLoadingDialog(context, message: 'Đang tải chi tiết cây...');

    final plant = await API().getCaySamById(caySamId);

    if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Đóng dialog
    if (!mounted) return;

    if (plant != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlantDetailScreen(
            plant: plant,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cây trồng không tồn tại hoặc đã bị xóa.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  ({IconData icon, Color color}) _getVisualsForNotification(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('cảnh báo') || lowerTitle.contains('lỗi') || lowerTitle.contains('bất thường')) {
      return (icon: Icons.warning_amber_rounded, color: Colors.orange.shade700);
    }
    if (lowerTitle.contains('thành công') || lowerTitle.contains('hoàn thành') || lowerTitle.contains('ổn định')) {
      return (icon: Icons.check_circle_outline_rounded, color: Colors.green.shade600);
    }
    if (lowerTitle.contains('nhật ký')) {
      return (icon: Icons.book_outlined, color: Colors.purple.shade600);
    }
    if (lowerTitle.contains('xác thực')) {
      return (icon: Icons.shield_outlined, color: Colors.indigo.shade600);
    }
    if (lowerTitle.contains('cây mới')) {
      return (icon: Icons.eco_outlined, color: Colors.teal.shade600);
    }
    return (icon: Icons.info_outline_rounded, color: Colors.blue.shade600);
  }

  String _formatTimestamp(String timestampString) {
    final timestamp = DateTime.tryParse(timestampString);
    if (timestamp == null) return '';
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return DateFormat('dd/MM/yyyy').format(timestamp);
  }
  @override
  // ( ... bên trong class _NotificationPanelState ... )

  @override
  Widget build(BuildContext context) {
    // <<< THAY ĐỔI: Tính toán 'hasUnread' ở đây
    // Thêm điều kiện !_isInitialLoading để nút không hiển thị
    // khi danh sách chưa tải xong
    final bool hasUnread =
        !_isInitialLoading && _notifications.any((n) => !n.seen);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // <<< THÊM MỚI: Thêm AppBar để chứa nút bấm
      appBar: AppBar(
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.black87, // Màu chữ cho tiêu đề
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white, // Nền trắng cho sạch
        elevation: 1, // Một chút bóng mờ
        // Dòng này sẽ tự thêm nút "Back" nếu trang này được push
        // từ một trang khác.
        // Bạn có thể không cần nếu đây là trang gốc trong Tab
        automaticallyImplyLeading: true,
        iconTheme: IconThemeData(color: Colors.black54), // Màu icon back

        actions: [
          // <<< THÊM MỚI: Nút "Đọc tất cả"
          // Chỉ hiển thị khi có thông báo chưa đọc
          if (hasUnread)
            Padding(
              // Đệm 1 chút bên phải
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Đọc tất cả', // Rút gọn cho vừa AppBar
                  style: TextStyle(
                    color: Theme.of(context).primaryColor, // Màu xanh chủ đạo
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                // Thêm hiệu ứng gợn sóng cho đẹp
                style: TextButton.styleFrom(
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
              ),
            ),
        ],
      ),

      // Body vẫn gọi hàm _buildBody như cũ
      body: _buildBody(),
    );
  }

  // ( ... bên trong class _NotificationPanelState ... )

  // <<< CẬP NHẬT: Thay thế toàn bộ hàm _buildBody
  // ( ... bên trong class _NotificationPanelState ... )

  Widget _buildBody() {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_apiError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_apiError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red)),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    // <<< XÓA BỎ: Toàn bộ phần Column, if(hasUnread), Padding
    // và Expanded đã bị xóa.
    // Trả về ListView.builder trực tiếp.
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16), // Padding cho toàn bộ danh sách
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final notification = _notifications[index];
        return _buildNotificationListItem(notification);
      },
    );
  }

  Widget _buildNotificationListItem(ThongBaoModel notification) {
    final visuals = _getVisualsForNotification(notification.tieuDe);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.08),
      color: notification.seen ? Colors.white : Colors.blue.shade50,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _markAsRead(notification.id);
        },
        child: Row(
          children: [
            if (!notification.seen)
              Container(
                width: 5,
                height: 80,
                color: Theme.of(context).primaryColor,
              ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: visuals.color.withOpacity(0.1),
                  child: Icon(visuals.icon, color: visuals.color, size: 24),
                ),
                title: Text(
                  notification.tieuDe,
                  style: TextStyle(
                    fontWeight: notification.seen ? FontWeight.w500 : FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    notification.noiDung,
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13
                    ),
                    maxLines: 1, // Giảm xuống 1 dòng để gọn hơn
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Text(
                  _formatTimestamp(notification.ngayKhoiTao),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _currentFilter == 'unread'
                ? 'Không có thông báo mới'
                : 'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tất cả thông báo của bạn sẽ xuất hiện ở đây.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

void showLoadingDialog(BuildContext context, {String message = 'Đang xử lý...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    },
  );
}