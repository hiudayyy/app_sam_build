import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/environment.dart';
import '../data/environment_data.dart';

class EnvironmentManagementScreen extends StatefulWidget {
  @override
  _EnvironmentManagementScreenState createState() => _EnvironmentManagementScreenState();
}

class _EnvironmentManagementScreenState extends State<EnvironmentManagementScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String? _selectedZone;
  String _searchTerm = '';
  String _zoneSearchTerm = '';
  String _statusFilter = 'all';
  bool _isRefreshing = false;
  bool _showFilters = false;

  final Map<String, String> _searchFilters = {
    'status': 'all',
    'deviceCount': 'all',
    'location': '',
    'hasAlerts': 'all',
  };

  List<DeviceZone> get zones => EnvironmentData.mockZones;
  List<SensorDevice> get devices => EnvironmentData.mockDevices;
  List<DataCollection> get collections => EnvironmentData.mockCollections;
  List<EnvironmentAlert> get alerts => EnvironmentData.mockAlerts;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<SensorDevice> get filteredDevices {
    return devices.where((device) {
      if (_selectedZone != null && device.zoneId != _selectedZone) return false;

      final matchesSearch = device.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
          device.id.toLowerCase().contains(_searchTerm.toLowerCase());

      final matchesStatus = _statusFilter == 'all' || device.status.name == _statusFilter;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  DeviceZone? getZoneById(String zoneId) => zones.firstWhere((z) => z.id == zoneId);

  List<SensorDevice> getDevicesByZone(String zoneId) => devices.where((d) => d.zoneId == zoneId).toList();

  int getActiveAlertsCount() => alerts.where((a) => !a.isResolved).length;

  int getOfflineDevicesCount() => devices.where((d) => d.status == DeviceStatus.offline || d.status == DeviceStatus.error).length;

  Map<String, dynamic> getZoneOverview(String zoneId) {
    final zoneDevices = getDevicesByZone(zoneId);
    final zoneCollections = collections.where((c) => c.zoneId == zoneId).toList();
    final zoneAlerts = alerts.where((a) => a.zoneId == zoneId && !a.isResolved).toList();

    final latestCollection = zoneCollections.isNotEmpty
        ? zoneCollections.reduce((a, b) => DateTime.parse(a.collectionDate).isAfter(DateTime.parse(b.collectionDate)) ? a : b)
        : null;

    final onlineDevices = zoneDevices.where((d) => d.status == DeviceStatus.online).length;
    final offlineDevices = zoneDevices.where((d) => d.status == DeviceStatus.offline).length;
    final errorDevices = zoneDevices.where((d) => d.status == DeviceStatus.error).length;
    final lowBatteryDevices = zoneDevices.where((d) => d.batteryLevel != null && d.batteryLevel! < 20).length;
    final averageBattery = zoneDevices.isNotEmpty
        ? zoneDevices.map((d) => d.batteryLevel ?? 0).reduce((a, b) => a + b) / zoneDevices.length
        : 0;

    return {
      'deviceCount': zoneDevices.length,
      'onlineDevices': onlineDevices,
      'offlineDevices': offlineDevices,
      'errorDevices': errorDevices,
      'lowBatteryDevices': lowBatteryDevices,
      'averageBattery': averageBattery.round(),
      'activeAlerts': zoneAlerts.length,
      'latestCollection': latestCollection,
    };
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'online': return Colors.green;
      case 'offline': return Colors.red;
      case 'error': return Colors.red;
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'maintenance': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Color getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low: return Colors.blue;
      case AlertSeverity.medium: return Colors.orange;
      case AlertSeverity.high: return Colors.deepOrange;
      case AlertSeverity.critical: return Colors.red;
    }
  }

  Color getBatteryColor(int? level) {
    if (level == null) return Colors.grey;
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  IconData getDeviceTypeIcon(SensorType type) {
    switch (type) {
      case SensorType.temperature: return Icons.thermostat;
      case SensorType.humidity: return Icons.opacity;
      case SensorType.soilMoisture: return Icons.grass;
      case SensorType.ph: return Icons.science;
      case SensorType.light: return Icons.wb_sunny;
      case SensorType.rainfall: return Icons.cloud_queue;
    }
  }

  String getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low: return 'Thấp';
      case AlertSeverity.medium: return 'TB';
      case AlertSeverity.high: return 'Cao';
      case AlertSeverity.critical: return 'Nghiêm trọng';
    }
  }

  Future<void> handleRefreshData() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Enhanced Header
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.thermostat, color: Colors.white, size: 20),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Môi trường',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${zones.length} vùng • ${devices.where((d) => d.status == DeviceStatus.online).length}/${devices.length} thiết bị',
                                style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _isRefreshing ? null : handleRefreshData,
                          icon: Icon(
                            Icons.refresh,
                            color: _isRefreshing ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width * 0.04),

                    // Quick Stats
                    Row(
                      children: [
                        Expanded(child: _buildStatCard('Online', devices.where((d) => d.status == DeviceStatus.online).length, Colors.green, Icons.wifi)),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Expanded(child: _buildStatCard('Offline', getOfflineDevicesCount(), Colors.red, Icons.wifi_off)),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Expanded(child: _buildStatCard('Cảnh báo', getActiveAlertsCount(), Colors.orange, Icons.warning)),
                        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                        Expanded(child: _buildStatCard('Thu thập', collections.where((c) => c.status == CollectionStatus.collecting).length, Colors.blue, Icons.analytics)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.analytics, size: MediaQuery.of(context).size.width * 0.035),
                      SizedBox(height: MediaQuery.of(context).size.width * 0.004),
                      Text('Tổng quan', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.025)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, size: MediaQuery.of(context).size.width * 0.035),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                      Text('Vùng', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.025)),
                    ],
                  ),
                ),
                Tab(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.settings, size: MediaQuery.of(context).size.width * 0.035),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.004),
                      Text('Thiết bị', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.025)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildZonesTab(),
                _buildDevicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: MediaQuery.of(context).size.width * 0.04, color: color),
              SizedBox(width: MediaQuery.of(context).size.width * 0.007),
              Text(label, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.025, color: color)),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Critical Alerts
          if (getActiveAlertsCount() > 0) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange.shade700),
                        SizedBox(width: 8),
                        Text(
                          'Cảnh báo cần xử lý (${getActiveAlertsCount()})',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...alerts.where((a) => !a.isResolved).take(2).map((alert) {
                      final zone = getZoneById(alert.zoneId);
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: getSeverityColor(alert.severity).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                getSeverityText(alert.severity),
                                style: TextStyle(fontSize: 10, color: getSeverityColor(alert.severity)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(zone?.name ?? 'Unknown Zone', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                                  Text(alert.message, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: Icon(Icons.visibility, size: 16),
                              constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
          ],

          // Zone Status Overview
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 8),
                      Text('Trạng thái vùng', style: TextStyle(fontWeight: FontWeight.w600)),
                      Spacer(),
                      IconButton(
                        onPressed: () => _tabController.animateTo(1),
                        icon: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...zones.take(3).map((zone) {
                    final overview = getZoneOverview(zone.id);
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(zone.name, style: TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: getStatusColor(zone.status.name).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  zone.status == ZoneStatus.active ? 'Hoạt động' : 'Offline',
                                  style: TextStyle(fontSize: 10, color: getStatusColor(zone.status.name)),
                                ),
                              ),
                              if (overview['activeAlerts'] > 0)
                                Container(
                                  margin: EdgeInsets.only(left: 4),
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    overview['activeAlerts'].toString(),
                                    style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(overview['onlineDevices'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                                    Text('Online', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text((overview['offlineDevices'] + overview['errorDevices']).toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                                    Text('Offline', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text('${overview['averageBattery']}%', style: TextStyle(fontWeight: FontWeight.w600)),
                                    Text('Pin TB', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Recent Collections
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today),
                      SizedBox(width: 8),
                      Text('Thu thập gần đây', style: TextStyle(fontWeight: FontWeight.w600,fontSize: MediaQuery.of(context).size.width * 0.03)),
                    ],
                  ),
                  SizedBox(height: 12),
                  ...collections.take(3).map((collection) {
                    final zone = getZoneById(collection.zoneId);
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(zone?.name ?? 'Unknown Zone', style: TextStyle(fontWeight: FontWeight.w500,fontSize: MediaQuery.of(context).size.width * 0.03)),
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: getStatusColor(collection.status.name).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        collection.status == CollectionStatus.completed ? 'Hoàn thành' : 'Đang thu',
                                        style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.025, color: getStatusColor(collection.status.name)),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(DateTime.parse(collection.collectionDate)),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${collection.readingsCount} readings',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      collection.interval == CollectionInterval.weekly ? 'Tuần' : 'Tháng',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.trending_up, size: 16),
                            constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: zones.map((zone) {
          final overview = getZoneOverview(zone.id);

          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(zone.name, style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(zone.status.name).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              zone.status == ZoneStatus.active ? 'Hoạt động' : 'Offline',
                              style: TextStyle(fontSize: 10, color: getStatusColor(zone.status.name)),
                            ),
                          ),
                          if (overview['activeAlerts'] > 0)
                            Container(
                              margin: EdgeInsets.only(left: 4),
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                overview['activeAlerts'].toString(),
                                style: TextStyle(fontSize: 10, color: Colors.red.shade800),
                              ),
                            ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedZone = zone.id;
                                _tabController.animateTo(2);
                              });
                            },
                            icon: Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                      if (zone.description != null) ...[
                        SizedBox(height: 4),
                        Text(zone.description!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(zone.location.address ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.settings, size: 16),
                          SizedBox(width: 4),
                          Text('Thiết bị (${overview['deviceCount']})', style: TextStyle(fontWeight: FontWeight.w500)),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Text(overview['onlineDevices'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                                  Text('Online', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Text(overview['offlineDevices'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700)),
                                  Text('Offline', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Text(overview['errorDevices'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                                  Text('Lỗi', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  Text(overview['lowBatteryDevices'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: Colors.yellow.shade700)),
                                  Text('Pin yếu', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDevicesTab() {
    return Column(
      children: [
        // Search and Filters
        Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
          child: Column(
            children: [
              TextField(
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên, ID...',
                  hintStyle: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: MediaQuery.of(context).size.width * 0.05,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: MediaQuery.of(context).size.height * 0.01,
                    horizontal: MediaQuery.of(context).size.width * 0.04,
                  ),
                ),
                onChanged: (value) => setState(() => _searchTerm = value),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.008),
              Row(
                children: [
                  if (_selectedZone != null) ...[
                    Chip(
                      label: Text(
                        getZoneById(_selectedZone!)?.name ?? 'Unknown Zone',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.032,
                        ),
                      ),
                      onDeleted: () => setState(() => _selectedZone = null),
                      deleteIcon: Icon(Icons.close,
                        size: MediaQuery.of(context).size.width * 0.04,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  ],
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Trạng thái',
                        labelStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.034,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height * 0.01,
                          horizontal: MediaQuery.of(context).size.width * 0.03,
                        ),
                      ),
                      value: _statusFilter,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.034,
                              )),
                        ),
                        DropdownMenuItem(
                          value: 'online',
                          child: Text('Online',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.034,
                              )),
                        ),
                        DropdownMenuItem(
                          value: 'offline',
                          child: Text('Offline',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.034,
                              )),
                        ),
                        DropdownMenuItem(
                          value: 'error',
                          child: Text('Lỗi',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.034,
                              )),
                        ),
                      ],
                      onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Results Count
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tìm thấy ${filteredDevices.length} thiết bị',
              style: TextStyle(color: Colors.grey.shade600, fontSize: MediaQuery.of(context).size.width * 0.025),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.008),

        // Device List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.04),
            itemCount: filteredDevices.length,
            itemBuilder: (context, index) {
              final device = filteredDevices[index];
              final zone = getZoneById(device.zoneId);

              return Card(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.012),
                child: Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.016),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.008),
                            decoration: BoxDecoration(
                              color: getStatusColor(device.status.name).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height * 0.008),
                            ),
                            child: Icon(
                              getDeviceTypeIcon(device.type),
                              color: getStatusColor(device.status.name),
                              size: MediaQuery.of(context).size.height * 0.02,
                            ),
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.025 ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(device.name, style: TextStyle(fontWeight: FontWeight.w600,fontSize: MediaQuery.of(context).size.width * 0.025)),
                                Text('ID: ${device.id}', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(device.status.name).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              device.status.name.toUpperCase(),
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: getStatusColor(device.status.name)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.012),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: MediaQuery.of(context).size.width * 0.025, color: Colors.grey.shade600),
                                SizedBox(width: 4),
                                Text(zone?.name ?? 'Unknown Zone', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          if (device.batteryLevel != null) ...[
                            Icon(Icons.battery_full, size: 14, color: getBatteryColor(device.batteryLevel)),
                            SizedBox(width: 4),
                            Text('${device.batteryLevel}%', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: getBatteryColor(device.batteryLevel))),
                          ],
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.008,),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: MediaQuery.of(context).size.width * 0.025, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            'Sync: ${DateFormat('dd/MM HH:mm').format(DateTime.parse(device.lastSync))}',
                            style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (device.model != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: MediaQuery.of(context).size.width * 0.025, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(device.model!, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.02, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}