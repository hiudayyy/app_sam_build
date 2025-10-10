import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../models/vuontrong/losamcamera_model.dart';

// Camera configuration for PTZ controls
class CameraConfig {
  double angle;      // Góc quay (độ)
  int range;         // Khoảng cách nhìn (số hàng: 1-17)
  double spread;     // Độ rộng góc nhìn (độ)

  CameraConfig({
    this.angle = 0,
    this.range = 8,
    this.spread = 80,
  });

  CameraConfig copyWith({
    double? angle,
    int? range,
    double? spread,
  }) {
    return CameraConfig(
      angle: angle ?? this.angle,
      range: range ?? this.range,
      spread: spread ?? this.spread,
    );
  }
}

class CameraViewWithGrid extends StatefulWidget {
  final List<LoSamCameraModel> cameras; // LoSamCameraModel
  final String areaName;

  const CameraViewWithGrid({
    Key? key,
    required this.cameras,
    required this.areaName,
  }) : super(key: key);

  @override
  _CameraViewWithGridState createState() => _CameraViewWithGridState();
}

class _CameraViewWithGridState extends State<CameraViewWithGrid> with SingleTickerProviderStateMixin {
  LoSamCameraModel? selectedCamera;
  bool isPlaying = true;
  String? urlcamera;
  VideoPlayerController? _controller;
  bool isLoading = false;
  bool _isVideoError = false;

  // PTZ & Grid Map
  CameraConfig cameraConfig = CameraConfig();
  double pulseOpacity = 0.25;
  int pulseDirection = 1;
  Timer? pulseTimer;
  final GlobalKey gridMapKey = GlobalKey();

  // Grid configuration - 6 columns x 17 rows
  final List<String> cols = ['A', 'B', 'C', 'D', 'E', 'F'];
  final int rows = 17;

  List<String> get leftCols => cols.sublist(0, 3);  // A, B, C
  List<String> get rightCols => cols.sublist(3, 6); // D, E, F

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startPulseAnimation();
  }

  @override
  void dispose() {
    _controller?.dispose();
    pulseTimer?.cancel();
    super.dispose();
  }

  void _startPulseAnimation() {
    pulseTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          pulseOpacity += 0.05 * pulseDirection;
          if (pulseOpacity >= 0.4) {
            pulseDirection = -1;
          } else if (pulseOpacity <= 0.1) {
            pulseDirection = 1;
          }
        });
      }
    });
  }

  // Convert range (số hàng) sang pixels dựa trên chiều cao grid map
  double getRangeInPixels() {
    final RenderBox? renderBox = gridMapKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 300.0;
    final gridHeight = renderBox.size.height;
    final rowHeight = gridHeight / rows;
    return cameraConfig.range * rowHeight;
  }

  // PTZ Control
  Future<void> handlePTZ(String action) async {
    // TODO: Gọi API PTZ ở đây
    // await API().controlCameraPTZ(cameraId: selectedCamera.id, action: action);
    print('PTZ command: $action for camera ${selectedCamera?.id}');

    if (mounted) {
      setState(() {
        CameraConfig newConfig = cameraConfig;

        switch (action) {
          case 'left':
            newConfig = newConfig.copyWith(angle: newConfig.angle - 10);
            break;
          case 'right':
            newConfig = newConfig.copyWith(angle: newConfig.angle + 10);
            break;
          case 'up':
            newConfig = newConfig.copyWith(
              range: (newConfig.range + 1).clamp(1, 9),
            );
            break;
          case 'down':
            newConfig = newConfig.copyWith(
              range: (newConfig.range - 1).clamp(1, 9),
            );
            break;
          case 'zoomIn':
            newConfig = newConfig.copyWith(
              spread: (newConfig.spread - 5).clamp(40, 100),
            );
            break;
          case 'zoomOut':
            newConfig = newConfig.copyWith(
              spread: (newConfig.spread + 5).clamp(40, 100),
            );
            break;
          case 'reset':
            newConfig = CameraConfig(angle: 0, range: 8, spread: 80);
            break;
        }

        cameraConfig = newConfig;
      });
    }
  }

  void startVideo() {
    if (urlcamera == null || urlcamera!.isEmpty) return;
    print(urlcamera);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(urlcamera!),
    )..initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller!.play();
      }
    });
  }

  Future<void> _initializeData() async {
    // Giữ nguyên logic init của bạn
    if (widget.cameras.length == 1) {
      setState(() {
        selectedCamera = widget.cameras.first;
        isLoading = true;
      });

      try {
        // TODO: Uncomment khi có API thật
        // final res = await API().startStreamCamera(widget.cameras.first);
        // if (res != null) {
        //   setState(() {
        //     urlcamera = res.uri;
        //   });
        //   startVideo();
        // }

        // Mock for testing
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          urlcamera = 'https://samnft.vecoi.com/streamfile/1/stream.m3u8';
        });
        startVideo();
      } catch (e) {
        print("❌ Lỗi startStreamCamera: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
    _controller = VideoPlayerController.network(urlcamera ?? "")
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _isVideoError = true; // ✅ đánh dấu lỗi
          });
        }
      });

    _controller!.addListener(() {
      if (_controller!.value.hasError) {
        setState(() {
          _isVideoError = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera giám sát - ${widget.areaName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Camera List (GIỮ NGUYÊN)
            if (selectedCamera?.trangThai != 0 || selectedCamera == null)
              Expanded(
                flex: 2,
                child: _buildCameraList(),
              ),
            const SizedBox(width: 16),

            // Camera View with Grid Map
            Expanded(
              flex: 2,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedCamera != null
                  ? _buildCameraViewWithGrid(selectedCamera!)
                  : _buildNoCameraSelected(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách camera (${widget.cameras.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.width * 0.027,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: widget.cameras.length,
            itemBuilder: (context, index) {
              final camera = widget.cameras[index];
              final isSelected = selectedCamera?.id == camera.id;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  elevation: isSelected ? 3 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      setState(() {
                        selectedCamera = camera;
                        isLoading = true;
                      });

                      try {
                        // TODO: Gọi API thật
                        // final res = await API().startStreamCamera(camera);
                        // if (res != null) {
                        //   setState(() {
                        //     urlcamera = res.uri;
                        //   });
                        //   startVideo();
                        // }

                        await Future.delayed(Duration(milliseconds: 500));
                        setState(() {
                          urlcamera = 'https://samnft.vecoi.com/streamfile/1/stream.m3u8';
                        });
                        startVideo();
                      } catch (e) {
                        print("❌ Lỗi startStreamCamera: $e");
                      } finally {
                        setState(() {
                          isLoading = false;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(color: Colors.green, width: 2)
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      camera.loSamLoaiCamera?.ten ?? "",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: MediaQuery.of(context).size.width * 0.024,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 12, color: Colors.black87),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            camera.loSam ?? "",
                                            style: TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(
                                    camera.trangThai == 0 ? Icons.wifi : Icons.wifi_off,
                                    size: 12,
                                    color: camera.trangThai == 0 ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: camera.trangThai == 0
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      camera.trangThai == 0 ? 'Online' : 'Offline',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: camera.trangThai == 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCameraViewWithGrid(LoSamCameraModel camera) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Camera Info Header (GIỮ NGUYÊN)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   camera.loSamLoaiCamera?.ten ?? "",
                //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
                Text(
                  "Sơ Đồ Camera",
                  style: TextStyle(fontSize: 18, color: Colors.black87,fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: camera.trangThai == 0
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    camera.trangThai == 0 ? Icons.wifi : Icons.wifi_off,
                    size: 14,
                    color: camera.trangThai == 0
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    camera.trangThai == 0 ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: camera.trangThai == 0
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // THÊM: Grid Map + Video Player - SCROLLABLE
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Grid Map với camera cone overlay
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(4),
                  height: (rows * 27.0) + 8,
                  child: Stack(
                    clipBehavior: Clip.none, // Allow cone overflow
                    children: [
                      // Grid cells
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left 3 columns
                          Expanded(
                            child: Container(
                              key: gridMapKey,
                              child: _buildGridColumn(leftCols),
                            ),
                          ),

                          // Camera path background
                          Container(
                            width: 30,
                            height: rows * 27.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),

                          // Right 3 columns
                          Expanded(child: _buildGridColumn(rightCols)),
                        ],
                      ),

                      // Camera cone - OVERLAY trên toàn bộ grid
                      Positioned.fill(
                        child: CustomPaint(
                          painter: CameraConePainter(
                            angle: cameraConfig.angle,
                            range: getRangeInPixels(),
                            spread: cameraConfig.spread,
                            pulseOpacity: pulseOpacity,
                            containerWidth: MediaQuery.of(context).size.width - 32, // Full width
                          ),
                        ),
                      ),

                      // Camera marker ở giữa
                      Positioned(
                        left: (MediaQuery.of(context).size.width - 70) / 2, // Center
                        top: ((rows * 27.0) / 2) - 8, // Center vertically
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [Colors.red, Colors.red.shade900],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Video Player + PTZ
                Container(
                  height: 400, // Fixed height
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Video
                      Center(child: _buildVideoPlayer()),

                      // PTZ Controls - top right
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _buildPTZControls(),
                        ),
                      ),

                      // Camera Info - bottom left
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: _buildCameraInfo(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridColumn(List<String> columns) {
    // Tính toán cell height chính xác để không overflow
    final cellHeight = 27.0; // Giảm từ 28 xuống 27 để tránh overflow

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (r) {
        return Row(
          children: List.generate(columns.length, (c) {
            final col = columns[c];
            return Expanded(
              child: Container(
                height: cellHeight,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  border: Border.all(color: Colors.grey[600]!, width: 0.5),
                ),
                child: Center(
                  child: Text(
                    '$col${r + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildVideoPlayer() {
    if (_isVideoError) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text("Không thể phát video", style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }

    if (_controller != null && _controller!.value.isInitialized) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullscreenVideoPage(controller: _controller!),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          SizedBox(height: 8),
          Text("Đang tải video...", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPTZControls() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPTZButton(Icons.zoom_in, () => handlePTZ('zoomIn'), 'Zoom+'),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.rotate_left, () => handlePTZ('left'), 'Trái'),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.arrow_upward, () => handlePTZ('up'), 'Lên'),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.restore, () => handlePTZ('reset'), 'Reset', color: Colors.grey[300]),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.arrow_downward, () => handlePTZ('down'), 'Xuống'),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.rotate_right, () => handlePTZ('right'), 'Phải'),
                const SizedBox(width: 8),
                _buildPTZButton(Icons.zoom_out, () => handlePTZ('zoomOut'), 'Zoom-'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPTZButton(IconData icon, VoidCallback onPressed, String tooltip, {Color? color}) {
    return SizedBox(
      width: 40,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: color ?? Colors.white,
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 1,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _buildCameraInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            '↔️${cameraConfig.angle.toStringAsFixed(0)}°',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            '📏${cameraConfig.range}/$rows',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            '📐${cameraConfig.spread.toStringAsFixed(0)}°',
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCameraSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chọn camera để xem',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chọn một camera từ danh sách bên trái',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Custom painter for camera cone
class CameraConePainter extends CustomPainter {
  final double angle;
  final double range;
  final double spread;
  final double pulseOpacity;
  final double? containerWidth;

  CameraConePainter({
    required this.angle,
    required this.range,
    required this.spread,
    required this.pulseOpacity,
    this.containerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Camera position ở giữa container
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);

    // Giới hạn range tối đa 80% chiều cao
    final maxRange = math.min(range, size.height * 0.8);

    final paint = Paint()
      ..color = Colors.blue.withOpacity(pulseOpacity)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final angleRad = angle * math.pi / 180;
    final startAngle = angleRad - (spread / 2) * math.pi / 180;
    final endAngle = angleRad + (spread / 2) * math.pi / 180;

    final path = Path();
    path.moveTo(centerX, centerY);

    for (int i = 0; i <= 30; i++) {
      final t = startAngle + (i / 30) * (endAngle - startAngle);
      final x = centerX + maxRange * math.sin(t);
      final y = centerY - maxRange * math.cos(t);
      path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(CameraConePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.range != range ||
        oldDelegate.spread != spread ||
        oldDelegate.pulseOpacity != pulseOpacity;
  }

}
class FullscreenVideoPage extends StatelessWidget {
  final VideoPlayerController controller;

  const FullscreenVideoPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          Positioned(
            top: 32,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
