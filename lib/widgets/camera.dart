import 'dart:convert';
import 'package:csam_mobile/api/api_camera.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../api/api.dart';
import '../models/camera.dart';
import '../models/kttoken.dart';
import '../models/vuontrong/losamcamera_model.dart';

class CameraView extends StatefulWidget {
  final List<LoSamCameraModel> cameras;
  final String areaName;

  const CameraView({
    Key? key,
    required this.cameras,
    required this.areaName,
  }) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  LoSamCameraModel? selectedCamera;
  bool isPlaying = true;
  String? urlcamera;
  bool _isPlaying = false; // mặc định chưa chạy
  VideoPlayerController? _controller;
  bool isLoading = false;
  bool _isVideoError = false;
  Kttoken? user;

  void startVideo() {
    if (urlcamera == null || urlcamera!.isEmpty) return;
    print(urlcamera);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(urlcamera!),
    )..initialize().then((_) {
        setState(() {});
        _controller!.play(); // Tự động phát sau khi load
      });
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString("ginseng_user");
    if (userJson != null) {
      user = Kttoken.fromJson(jsonDecode(userJson));
    }
    if (widget.cameras.length == 1) {
      setState(() {
        selectedCamera = widget.cameras.first;
        isLoading = true; // bật loading khi bắt đầu gọi API
      });

      try {
        final res = await API().startStreamCamera(widget.cameras.first);
        if (res != null) {
          setState(() {
            urlcamera = res.uri; // gán uri vào biến
          });
          startVideo();
        } else {
          print("❌ Không lấy được stream camera");
        }
      } catch (e) {
        print("❌ Lỗi startStreamCamera: $e");
      } finally {
        setState(() {
          isLoading = false; // tắt loading khi xong
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
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
            // Camera List
            if (selectedCamera?.trangThai != 0 || selectedCamera == null)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Danh sách camera (${widget.cameras.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width * 0.027),
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
                              color: isSelected
                                  ? Colors.green.shade50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              elevation: isSelected ? 3 : 1,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () async {
                                  setState(() {
                                    selectedCamera = camera;
                                    isLoading =
                                        true; // bật loading khi bắt đầu gọi API
                                  });

                                  try {
                                    final res =
                                        await API().startStreamCamera(camera);
                                    if (res != null) {
                                      setState(() {
                                        urlcamera = res.uri; // gán uri vào biến
                                      });
                                      startVideo();
                                    } else {
                                      print("❌ Không lấy được stream camera");
                                    }
                                  } catch (e) {
                                    print("❌ Lỗi startStreamCamera: $e");
                                  } finally {
                                    setState(() {
                                      isLoading = false; // tắt loading khi xong
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.green, width: 2)
                                        : Border.all(
                                            color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          // Icon(
                                          //   _getCameraTypeIcon(camera.loSamLoaiCamera?.ten ?? ""),
                                          //   size: 16,
                                          //   color: Colors.grey.shade600,
                                          // ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  camera.loSamLoaiCamera?.ten ??
                                                      "",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.024),
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 12,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        camera.loSam ?? "",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey.shade600,
                                                        ),
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
                                                camera.trangThai == 0
                                                    ? Icons.wifi
                                                    : Icons.wifi_off,
                                                size: 12,
                                                color: camera.trangThai == 0
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: camera.trangThai == 0
                                                      ? Colors.green.shade100
                                                      : Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  camera.trangThai == 0
                                                      ? 'Online'
                                                      : 'Offline',
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
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade400),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              camera.loSamLoaiCamera?.ten ?? "",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                              const SizedBox(width: 4),
                                              // Text(
                                              //   camera.formatLastUpdate(),
                                              //   style: TextStyle(
                                              //     fontSize: 10,
                                              //     color: Colors.grey.shade600,
                                              //   ),
                                              // ),
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
                ),
              ),
            const SizedBox(width: 16),
            // Camera View
            Expanded(
              flex: 2,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedCamera != null
                      ? _buildCameraView(selectedCamera!)
                      : _buildNoCameraSelected(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView(LoSamCameraModel camera) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Camera Info Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camera.loSamLoaiCamera?.ten ?? "",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  camera.loSam ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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

        // Video Player
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: camera.trangThai == 0
                ? _buildLiveView(camera)
                : _buildOfflineView(camera),
          ),
        ),

        const SizedBox(height: 16),

        // Camera Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loại camera',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          camera.loSamLoaiCamera?.ten ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vị trí',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          camera.loSam ?? "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          camera.trangThai == 0
                              ? 'Hoạt động'
                              : 'Ngưng hoạt động',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: camera.trangThai == 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cập nhật cuối',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          /*camera.formatLastUpdate()*/ "",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveView(LoSamCameraModel camera) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // 📹 Hiển thị video camera với chiều cao theo tỉ lệ
        if (_isVideoError)
          Container(
            width: screenWidth,
            height: screenWidth * 9 / 16,
            color: Colors.black12,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 40),
                  SizedBox(height: 8),
                  Text(
                    "Không thể phát video",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          )
        else if (_controller != null && _controller!.value.isInitialized)
          Padding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.1),
            child: SizedBox(
              width: screenWidth,
              height: screenWidth / _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          Container(
            width: screenWidth,
            height: screenWidth * 9 / 16,
            color: Colors.black12,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Đang tải video...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // 🔘 Hàng nút điều khiển
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 32),
              onPressed: () {
                setState(() {
                  selectedCamera = null;
                });
              },
            ),

            const SizedBox(width: 16),

            // ▶️ Play / Pause
            IconButton(
              icon: Icon(
                (_controller != null && _controller!.value.isPlaying)
                    ? Icons.pause
                    : Icons.play_arrow,
                size: 32,
              ),
              onPressed: () {
                if (_controller == null) {
                  startVideo();
                } else if (_controller!.value.isInitialized) {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                }
              },
            ),

            const SizedBox(width: 16),

            // ⏹ Stop
            IconButton(
              icon: const Icon(Icons.stop, size: 32),
              onPressed: () {
                if (_controller != null && _controller!.value.isInitialized) {
                  setState(() {
                    _controller!.pause();
                    _controller!.seekTo(Duration.zero);
                  });
                }
              },
            ),

            const SizedBox(width: 16),

            // 🔳 Fullscreen
            IconButton(
              icon: const Icon(Icons.fullscreen, size: 32),
              onPressed: () {
                if (_controller != null && _controller!.value.isInitialized) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        backgroundColor: Colors.black,
                        body: Stack(
                          children: [
                            // 📹 Video full màn hình – vẫn đúng tỉ lệ
                            Center(
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              ),
                            ),

                            // 🔙 Nút back nằm trên cùng bên trái
                            Positioned(
                              top: 24,
                              left: 16,
                              child: SafeArea(
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfflineView(LoSamCameraModel camera) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            color: Colors.grey.shade400,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera offline',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cập nhật lần cuối: {camera.formatLastUpdate()}',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
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
          Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.grey.shade400,
          ),
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
            'Chọn một camera từ danh sách bên trái để xem live stream',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
      ),
    );
  }

  // IconData _getCameraTypeIcon(CameraType type) {
  //   switch (type) {
  //     case CameraType.overview:
  //       return Icons.visibility;
  //     case CameraType.detail:
  //       return Icons.camera_alt;
  //     case CameraType.security:
  //       return Icons.security;
  //   }
  // }
}
