import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math' as math;

class SensorReading {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double rainfall;

  SensorReading({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.rainfall,
  });
}

class EnvironmentMonitorScreen extends StatefulWidget {
  final String? regionId;

  const EnvironmentMonitorScreen({
    Key? key,
    this.regionId = 'MT001',
  }) : super(key: key);

  @override
  _EnvironmentMonitorScreenState createState() => _EnvironmentMonitorScreenState();
}

class _EnvironmentMonitorScreenState extends State<EnvironmentMonitorScreen> {
  List<SensorReading> _sensorData = [];
  bool _isConnected = true;
  DateTime _lastUpdate = DateTime.now();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _generateInitialData();
    _startDataUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _generateInitialData() {
    final List<SensorReading> readings = [];
    final now = DateTime.now();

    // Generate last 24 hours of data (every 30 minutes)
    for (int i = 48; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * 30));
      readings.add(SensorReading(
        timestamp: timestamp,
        temperature: 18 + math.Random().nextDouble() * 8, // 18-26°C
        humidity: 65 + math.Random().nextDouble() * 20, // 65-85%
        soilMoisture: 55 + math.Random().nextDouble() * 25, // 55-80%
        rainfall: math.Random().nextDouble() < 0.1 ? math.Random().nextDouble() * 2 : 0, // 10% chance
      ));
    }

    setState(() {
      _sensorData = readings;
    });
  }

  void _startDataUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _updateData();
    });
  }

  void _updateData() {
    final now = DateTime.now();
    final newReading = SensorReading(
      timestamp: now,
      temperature: 18 + math.Random().nextDouble() * 8,
      humidity: 65 + math.Random().nextDouble() * 20,
      soilMoisture: 55 + math.Random().nextDouble() * 25,
      rainfall: math.Random().nextDouble() < 0.1 ? math.Random().nextDouble() * 2 : 0,
    );

    setState(() {
      _sensorData.add(newReading);
      // Keep only last 48 readings (24 hours)
      if (_sensorData.length > 48) {
        _sensorData.removeAt(0);
      }
      _lastUpdate = now;
      // Simulate occasional connection issues
      _isConnected = math.Random().nextDouble() > 0.05;
    });
  }

  SensorReading? get _currentReading => _sensorData.isNotEmpty ? _sensorData.last : null;

  Color _getStatusColor(double value, String type) {
    final Map<String, Map<String, double>> ranges = {
      'temp': {'min': 18, 'max': 25, 'idealMin': 20, 'idealMax': 24},
      'humidity': {'min': 60, 'max': 85, 'idealMin': 70, 'idealMax': 80},
      'soil': {'min': 50, 'max': 80, 'idealMin': 60, 'idealMax': 75},
    };

    final range = ranges[type];
    if (range == null) return Colors.grey;

    if (value >= range['idealMin']! && value <= range['idealMax']!) {
      return Colors.green;
    }
    if (value >= range['min']! && value <= range['max']!) {
      return Colors.orange;
    }
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentReading == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Đang tải dữ liệu cảm biến...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Header
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Giám sát môi trường - Vùng ${widget.regionId}',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isConnected ? Icons.wifi : Icons.wifi_off,
                                  size: 12,
                                  color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  _isConnected ? 'Kết nối' : 'Mất kết nối',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cập nhật lần cuối: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(_lastUpdate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Current Readings
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _buildReadingCard(
                    'Nhiệt độ',
                    '${_currentReading!.temperature.toStringAsFixed(1)}°C',
                    Icons.thermostat,
                    Colors.red.shade100,
                    Colors.red.shade600,
                    _getStatusColor(_currentReading!.temperature, 'temp'),
                  ),
                  _buildReadingCard(
                    'Độ ẩm KK',
                    '${_currentReading!.humidity.round()}%',
                    Icons.opacity,
                    Colors.blue.shade100,
                    Colors.blue.shade600,
                    _getStatusColor(_currentReading!.humidity, 'humidity'),
                  ),
                  _buildReadingCard(
                    'Độ ẩm đất',
                    '${_currentReading!.soilMoisture.round()}%',
                    Icons.grass,
                    Colors.amber.shade100,
                    Colors.amber.shade600,
                    _getStatusColor(_currentReading!.soilMoisture, 'soil'),
                  ),
                  _buildReadingCard(
                    'Lượng mưa',
                    '${_currentReading!.rainfall.toStringAsFixed(1)}mm',
                    Icons.cloud_queue,
                    Colors.cyan.shade100,
                    Colors.cyan.shade600,
                    Colors.grey,
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Charts
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nhiệt độ & Độ ẩm không khí (24h)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        child: _buildSimpleChart([
                          {'label': 'Nhiệt độ', 'color': Colors.red, 'values': _sensorData.map((r) => r.temperature).toList()},
                          {'label': 'Độ ẩm', 'color': Colors.blue, 'values': _sensorData.map((r) => r.humidity).toList()},
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Độ ẩm đất & Lượng mưa (24h)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        child: _buildSimpleChart([
                          {'label': 'Độ ẩm đất', 'color': Colors.orange, 'values': _sensorData.map((r) => r.soilMoisture).toList()},
                          {'label': 'Lượng mưa', 'color': Colors.cyan, 'values': _sensorData.map((r) => r.rainfall * 10).toList()}, // Scale rainfall for visibility
                        ]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Alerts & Recommendations
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber),
                          SizedBox(width: 8),
                          Text(
                            'Cảnh báo & Khuyến nghị',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Temperature Alert
                      if (_currentReading!.temperature < 18 || _currentReading!.temperature > 25)
                        _buildAlertCard(
                          'Nhiệt độ không lý tưởng',
                          'Nhiệt độ hiện tại ${_currentReading!.temperature.toStringAsFixed(1)}°C. Nên duy trì trong khoảng 20-24°C.',
                          Icons.warning,
                          Colors.red,
                        ),

                      // Soil Moisture Alert
                      if (_currentReading!.soilMoisture < 60)
                        _buildAlertCard(
                          'Đất khô',
                          'Độ ẩm đất ${_currentReading!.soilMoisture.round()}%. Cần tưới nước.',
                          Icons.warning,
                          Colors.orange,
                        ),

                      // Ideal Conditions
                      if (_currentReading!.temperature >= 20 &&
                          _currentReading!.temperature <= 24 &&
                          _currentReading!.soilMoisture >= 60 &&
                          _currentReading!.soilMoisture <= 75)
                        _buildAlertCard(
                          'Điều kiện lý tưởng',
                          'Môi trường hiện tại rất phù hợp cho sự phát triển của cây sâm.',
                          Icons.check_circle,
                          Colors.green,
                        ),

                      // No alerts state
                      if (_currentReading!.temperature >= 18 &&
                          _currentReading!.temperature <= 25 &&
                          _currentReading!.soilMoisture >= 60 &&
                          !(_currentReading!.temperature >= 20 &&
                              _currentReading!.temperature <= 24 &&
                              _currentReading!.soilMoisture >= 60 &&
                              _currentReading!.soilMoisture <= 75))
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey.shade600),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Điều kiện môi trường ổn định. Tiếp tục theo dõi.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(
      String title,
      String value,
      IconData icon,
      Color bgColor,
      Color iconColor,
      Color statusColor,
      ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleChart(List<Map<String, dynamic>> series) {
    return CustomPaint(
      size: Size.infinite,
      painter: SimpleLinePainter(series, _sensorData),
    );
  }

  Widget _buildAlertCard(String title, String message, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color.withOpacity(0.9)),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SimpleLinePainter extends CustomPainter {
  final List<Map<String, dynamic>> series;
  final List<SensorReading> data;

  SimpleLinePainter(this.series, this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || series.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Calculate scales
    final double xStep = size.width / (data.length - 1);

    for (final serie in series) {
      final List<double> values = serie['values'] as List<double>;
      final Color color = serie['color'] as Color;

      if (values.isEmpty) continue;

      final double minValue = values.reduce(math.min);
      final double maxValue = values.reduce(math.max);
      final double valueRange = maxValue - minValue;

      if (valueRange == 0) continue;

      paint.color = color;

      final path = Path();
      for (int i = 0; i < values.length; i++) {
        final double x = i * xStep;
        final double y = size.height - ((values[i] - minValue) / valueRange) * size.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Vertical grid lines
    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}