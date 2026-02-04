import 'package:flutter/material.dart';
import '../models/environment.dart';
import '../data/environment_data.dart';

class EnvironmentSearchScreen extends StatefulWidget {
  @override
  _EnvironmentSearchScreenState createState() => _EnvironmentSearchScreenState();
}

class _EnvironmentSearchScreenState extends State<EnvironmentSearchScreen> {
  String _searchTerm = '';
  Map<String, String> _filters = {
    'status': 'all',
    'deviceCount': 'all',
    'location': '',
    'hasAlerts': 'all'
  };

  final List<DeviceZone> _zones = EnvironmentData.mockZones;
  final List<EnvironmentAlert> _alerts = EnvironmentData.mockAlerts;
  final List<SensorDevice> _devices = EnvironmentData.mockDevices;

  List<DeviceZone> get _filteredZones {
    return _zones.where((zone) {
      final matchesText = _searchTerm.isEmpty ||
          zone.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          (zone.description?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          (zone.location.address.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false); // ✅ Fixed null safety

      final matchesStatus = _filters['status'] == 'all' ||
          zone.status.toString().split('.').last == _filters['status'];

      bool matchesDeviceCount = true;
      if (_filters['deviceCount'] != 'all') {
        final deviceCount = _getDevicesByZone(zone.id).length;
        switch (_filters['deviceCount']) {
          case 'low':
            matchesDeviceCount = deviceCount < 3;
            break;
          case 'medium':
            matchesDeviceCount = deviceCount >= 3 && deviceCount <= 5;
            break;
          case 'high':
            matchesDeviceCount = deviceCount > 5;
            break;
        }
      }

      final matchesLocation = (_filters['location'] ?? '').isEmpty ||
          (zone.location.address.toLowerCase().contains((_filters['location'] ?? '').toLowerCase()) ?? false); // ✅ Fixed null safety

      bool matchesAlerts = true;
      if (_filters['hasAlerts'] != 'all') {
        final hasActiveAlerts = _alerts.any((a) => a.zoneId == zone.id && !a.isResolved);
        matchesAlerts = _filters['hasAlerts'] == 'yes' ? hasActiveAlerts : !hasActiveAlerts;
      }

      return matchesText && matchesStatus && matchesDeviceCount && matchesLocation && matchesAlerts;
    }).toList();
  }

  List<SensorDevice> _getDevicesByZone(String zoneId) {
    return _devices.where((d) => d.zoneId == zoneId).toList();
  }

  Map<String, int> _getZoneData(String zoneId) {
    final zoneDevices = _getDevicesByZone(zoneId);
    final zoneAlerts = _alerts.where((a) => a.zoneId == zoneId && !a.isResolved).toList();

    return {
      'totalDevices': zoneDevices.length,
      'onlineDevices': zoneDevices.where((d) => d.status == DeviceStatus.online).length,
      'activeAlerts': zoneAlerts.length,
    };
  }

  void _resetFilters() {
    setState(() {
      _searchTerm = '';
      _filters = {
        'status': 'all',
        'deviceCount': 'all',
        'location': '',
        'hasAlerts': 'all'
      };
    });
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = status.toString().split('.').last;
    switch (statusStr) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm vùng'),
        actions: [
          IconButton(
            onPressed: _resetFilters,
            icon: Icon(Icons.refresh),
            tooltip: 'Đặt lại bộ lọc',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, size: 20),
                      SizedBox(width: 8),
                      Text('Tìm kiếm vùng', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Search input
                  TextField(
                    onChanged: (value) => setState(() => _searchTerm = value),
                    decoration: InputDecoration(
                      hintText: 'Tìm tên vùng, mô tả, địa chỉ...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),

                  SizedBox(height: 16),

                  // Filters
                  Text('Bộ lọc nâng cao', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filters['status'],
                          onChanged: (value) => setState(() => _filters['status'] = value!),
                          decoration: InputDecoration(
                            labelText: 'Trạng thái',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                            DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                            DropdownMenuItem(value: 'inactive', child: Text('Không hoạt động')),
                            DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì')),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filters['deviceCount'],
                          onChanged: (value) => setState(() => _filters['deviceCount'] = value!),
                          decoration: InputDecoration(
                            labelText: 'Số thiết bị',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                            DropdownMenuItem(value: 'low', child: Text('Ít (< 3)')),
                            DropdownMenuItem(value: 'medium', child: Text('TB (3-5)')),
                            DropdownMenuItem(value: 'high', child: Text('Nhiều (> 5)')),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) => setState(() => _filters['location'] = value),
                          decoration: InputDecoration(
                            labelText: 'Địa điểm',
                            hintText: 'Lọc theo địa chỉ...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _filters['hasAlerts'],
                          onChanged: (value) => setState(() => _filters['hasAlerts'] = value!),
                          decoration: InputDecoration(
                            labelText: 'Cảnh báo',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                            DropdownMenuItem(value: 'yes', child: Text('Có cảnh báo')),
                            DropdownMenuItem(value: 'no', child: Text('Không có cảnh báo')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Results
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kết quả (${_filteredZones.length} vùng)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                SizedBox(height: 8),

                Expanded(
                  child: _filteredZones.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không tìm thấy vùng nào'),
                        SizedBox(height: 8),
                        Text(
                          'Thử điều chỉnh bộ lọc',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _filteredZones.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final zone = _filteredZones[index];
                      final zoneData = _getZoneData(zone.id);

                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              zone.name,
                                              style: TextStyle(fontWeight: FontWeight.w500),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(zone.status).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                zone.status == ZoneStatus.active ? 'Hoạt động' : 'Offline',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: _getStatusColor(zone.status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (zone.description != null) ...[
                                          SizedBox(height: 4),
                                          Text(
                                            zone.description!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                        SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                zone.location.address ?? 'Không có địa chỉ', // ✅ Fixed null safety
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12),

                              // Zone stats
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${zoneData['totalDevices']}',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Thiết bị',
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${zoneData['onlineDevices']}',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Online',
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${zoneData['activeAlerts']}',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Cảnh báo',
                                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 12),

                              // Quick actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(zone.id);
                                      },
                                      child: Text('Xem chi tiết', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: Size(0, 32),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.of(context).pop({'action': 'viewDevices', 'zoneId': zone.id});
                                      },
                                      child: Text('Thiết bị', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: Size(0, 32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}