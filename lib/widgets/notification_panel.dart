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
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / 375.0;
    final bool hasUnread = !_isInitialLoading && _notifications.any((n) => !n.seen);
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 56 * scale,
        titleSpacing: 0,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale), // Padding ngang theo scale
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông báo',
                style: TextStyle(
                  color: const Color(0xFF0F172A),
                  fontSize: 20 * scale, // Font tiêu đề theo scale
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (hasUnread)
                InkWell(
                  onTap: _markAllAsRead,
                  borderRadius: BorderRadius.circular(8 * scale),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w700,
                        fontSize: 11 * scale,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _buildBody(scale),
    );
  }
  Widget _buildBody(double scale) {
    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_apiError != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0 * scale),
          child: Text(_apiError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 14 * scale)),
        ),
      );
    }
    if (_notifications.isEmpty) {
      return _buildEmptyState(scale);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(16 * scale),
      itemCount: _notifications.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _notifications.length) {
          return Padding(
            padding: EdgeInsets.all(12.0 * scale),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final notification = _notifications[index];
        return _buildNotificationListItem(notification, scale);
      },
    );
  }

  Widget _buildNotificationListItem(ThongBaoModel notification, double scale) {
    final visuals = _getVisualsForNotification(notification.tieuDe);
    final isRead = notification.seen;
    final Color backgroundColor = isRead ? Colors.white : const Color(0xFFF0F7FF);
    final Color titleColor = isRead ? const Color(0xFF475569) : const Color(0xFF0F172A);
    final Color bodyColor = isRead ? const Color(0xFF64748B) : const Color(0xFF334155);

    return Container(
      margin: EdgeInsets.fromLTRB(0 * scale, 4 * scale, 0 * scale, 4 * scale),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            offset: const Offset(0, 2),
            blurRadius: 4,
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12 * scale),
          onTap: () => _markAsRead(notification.id),
          child: Padding(
            padding: EdgeInsets.all(12 * scale),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
              children: [
                Stack(
                  children: [
                    Container(
                      width: 42 * scale,
                      height: 42 * scale,
                      decoration: BoxDecoration(
                        color: isRead ? Colors.grey.shade100 : visuals.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10 * scale),
                      ),
                      child: Icon(
                          visuals.icon,
                          color: isRead ? Colors.grey.shade500 : visuals.color,
                          size: 20 * scale
                      ),
                    ),
                    if (!isRead)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10 * scale,
                          height: 10 * scale,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: backgroundColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 12 * scale),

                // === 2. NỘI DUNG ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hàng 1: Tiêu đề + Thời gian
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.tieuDe,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 13 * scale,
                                fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                                height: 1.2,
                              ),
                              maxLines: 1, // Chỉ hiện 1 dòng tiêu đề cho gọn
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          Text(
                            _formatTimestamp(notification.ngayKhoiTao),
                            style: TextStyle(
                              color: isRead ? Colors.grey.shade500 : Colors.blue.shade700,
                              fontSize: 9 * scale,
                              fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4 * scale),

                      // Hàng 2: Nội dung
                      Text(
                        notification.noiDung,
                        style: TextStyle(
                          color: bodyColor,
                          fontSize: 12 * scale,
                          height: 1.3,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // === 3. MŨI TÊN ĐIỀU HƯỚNG (QUAN TRỌNG) ===
                // Giúp người dùng biết đây là nút bấm được
                // SizedBox(width: 8 * scale),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isRead ? Colors.grey.shade300 : Colors.blue.shade300,
                  size: 20 * scale,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64 * scale,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(
              fontSize: 16 * scale,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
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