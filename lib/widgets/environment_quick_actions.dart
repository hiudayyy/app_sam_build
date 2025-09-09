import 'package:flutter/material.dart';
import '../models/environment.dart';
import '../models/user.dart';
import 'protected_route.dart';

class EnvironmentQuickActions extends StatelessWidget {
  final Function(String, CollectionInterval)? onStartCollection;
  final VoidCallback? onNavigateToSearch;
  final VoidCallback? onExportData;

  const EnvironmentQuickActions({
    Key? key,
    this.onStartCollection,
    this.onNavigateToSearch,
    this.onExportData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, size: 20),
                SizedBox(width: 8),
                Text('Thao tác nhanh', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                ProtectedRoute(
                  requiredPermission: Permission.manageEnvironment,
                  fallback: _buildDisabledActionButton('Thu thập tuần', Icons.play_circle),
                  child: _buildQuickActionButton(
                      'Thu thập tuần',
                      Icons.play_circle,
                          () => _showZoneSelectionDialog(context, CollectionInterval.weekly)
                  ),
                ),
                ProtectedRoute(
                  requiredPermission: Permission.manageEnvironment,
                  fallback: _buildDisabledActionButton('Thu thập tháng', Icons.calendar_today),
                  child: _buildQuickActionButton(
                      'Thu thập tháng',
                      Icons.calendar_today,
                          () => _showZoneSelectionDialog(context, CollectionInterval.monthly)
                  ),
                ),
                _buildQuickActionButton(
                    'Tìm kiếm',
                    Icons.search,
                    onNavigateToSearch ?? () {}
                ),
                _buildQuickActionButton(
                    'Xuất dữ liệu',
                    Icons.download,
                    onExportData ?? () {}
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12),
        elevation: 2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledActionButton(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showZoneSelectionDialog(BuildContext context, CollectionInterval interval) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chọn vùng thu thập'),
          content: Text('Chọn vùng để bắt đầu thu thập dữ liệu ${interval == CollectionInterval.weekly ? "hàng tuần" : "hàng tháng"}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onStartCollection != null) {
                  // In a real app, this would show a zone selection dialog
                  onStartCollection!('ZONE_001', interval);
                }
              },
              child: Text('Bắt đầu'),
            ),
          ],
        );
      },
    );
  }
}

class EnvironmentStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const EnvironmentStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 12, color: color),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.8)
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnvironmentAlertCard extends StatelessWidget {
  final String zoneId;
  final String zoneName;
  final String message;
  final String severity;
  final String timestamp;
  final VoidCallback? onView;
  final VoidCallback? onResolve;

  const EnvironmentAlertCard({
    Key? key,
    required this.zoneId,
    required this.zoneName,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.onView,
    this.onResolve,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color severityColor = _getSeverityColor(severity);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severity,
              style: TextStyle(fontSize: 10, color: severityColor),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    zoneName,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)
                ),
                Text(
                  message,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  timestamp,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (onView != null)
            IconButton(
              onPressed: onView,
              icon: Icon(Icons.visibility, size: 16),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          if (onResolve != null)
            IconButton(
              onPressed: onResolve,
              icon: Icon(Icons.check, size: 16),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
            ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'nghiêm trọng':
      case 'critical':
        return Colors.red;
      case 'cao':
      case 'high':
        return Colors.deepOrange;
      case 'tb':
      case 'medium':
        return Colors.orange;
      case 'thấp':
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}