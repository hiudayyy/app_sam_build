import 'dart:convert';
import 'dart:io';

import 'package:nftsam/api/api_caytrong.dart';
import 'package:nftsam/api/api_option.dart';
import 'package:nftsam/models/option_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api.dart';
import '../models/vuontrong/losam_model.dart';
import '../models/vuontrong/losamcamera_model.dart';
import '../models/vuontrong/losamchitiet_model.dart';
import '../models/vuontrong/sensor_model.dart';

class LoSamFormData {
  String maLo;
  String tenLo;
  int soHang;
  int soCot;
  double dienTich;
  String ghiChu;
  String loai;
  int trangThai;
  int vuonTrongId;

  LoSamFormData({
    required this.maLo,
    required this.tenLo,
    required this.soHang,
    required this.soCot,
    required this.dienTich,
    required this.ghiChu,
    required this.loai,
    required this.trangThai,
    required this.vuonTrongId,
  });
}

class AddLoSamScreen extends StatefulWidget {
  final int farmId;
  final int? zoneid;
  final Function(Map<String, dynamic> data, int id, {File? image}) onSubmit;

  const AddLoSamScreen({
    Key? key,
    required this.farmId,
    this.zoneid,
    required this.onSubmit,
  }) : super(key: key);

  @override
  _AddLoSamScreenState createState() => _AddLoSamScreenState();
}

class _AddLoSamScreenState extends State<AddLoSamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  File? _selectedImage;
  String? _selectedImageUrl;
  final ImagePicker _picker = ImagePicker();
  TextEditingController? maLoController;
  TextEditingController? tenLoController;
  TextEditingController? loaiLoController;
  TextEditingController? ghichuLoController;
  List<TextEditingController?> rtspControllers = [];
  List<TextEditingController?> userNameControllers = [];
  List<TextEditingController?> passwordControllers = [];
  List<TextEditingController?> ipCameraControllers = [];
  List<TextEditingController?> onvifCameraControllers = [];
  // Form data
  late LoSamFormData loSamData;
  List<LoSamChiTietModel> chiTiets = [];
  List<LoSamCameraModel> cameras = [];
  List<int> sensorid = [];
  List<OptionModel> OptionLoSamLoaiTuoi = [];
  List<OptionModel> OptionLoaiCamera = [];
  List<SensorModel>? OptionSensor = [];
  LoSamModel? losam;
  Map<String, String> errors = {};
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadData(); // Gọi hàm async để chờ xong việc khởi tạo
  }

  Future<void> _loadData() async {
    loSamData = LoSamFormData(
      maLo: '',
      tenLo: '',
      soHang: 1,
      soCot: 1,
      dienTich: 0,
      ghiChu: '',
      loai: '',
      trangThai: 1,
      vuonTrongId: widget.farmId ?? 0,
    );
    await _initializeData();
    if (mounted) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    maLoController?.dispose();
    tenLoController?.dispose();
    ghichuLoController?.dispose();
    loaiLoController?.dispose();
    for (var c in rtspControllers) {
      c?.dispose();
    }
    super.dispose();
  }

  // void _removeImage() {
  //   setState(() {
  //     _selectedImage = null;
  //   });
  // }

  Future<void> _initializeData() async {
    final api = API();

    final apiOptinlt = await api.OptionLoSamLoaiTuoi();
    if (!mounted) return;
    if (apiOptinlt != null) {
      setState(() {
        OptionLoSamLoaiTuoi = apiOptinlt;
      });
    }

    final apiOptincmr = await api.OptionLoSamLoaiCamera();
    if (!mounted) return;
    if (apiOptincmr != null) {
      setState(() {
        OptionLoaiCamera = apiOptincmr;
      });
    }

      losam = await api.getLoSamById(widget.zoneid ?? 0);
      if (!mounted) return;

      setState(() {
        loSamData.maLo = losam?.maLo ?? "";
        loSamData.tenLo = losam?.tenLo ?? "";
        loSamData.soHang = losam?.soHang ?? 0;
        loSamData.soCot = losam?.soCot ?? 0;
        loSamData.ghiChu = losam?.ghiChu ?? "";
        loSamData.loai = losam?.loai ?? "";
        chiTiets = losam?.loSamChiTiets ?? [];
        cameras = losam?.loSamCameras ?? [];
        sensorid = losam?.sensorIds ?? [];
        maLoController = TextEditingController(text: loSamData.maLo);
        tenLoController = TextEditingController(text: loSamData.tenLo);
        loaiLoController = TextEditingController(text: loSamData.loai);
        ghichuLoController = TextEditingController(text: losam?.ghiChu);
        if(losam?.sensorModels != null){
          OptionSensor = losam?.sensorModels;
        }
        rtspControllers = cameras.map((c) => TextEditingController(text: c.rtsp)).toList();
        userNameControllers = cameras.map((c) => TextEditingController(text: c.userName)).toList();
        passwordControllers = cameras.map((c) => TextEditingController(text: c.password)).toList();
        ipCameraControllers = cameras.map((c) => TextEditingController(text: c.ipCamera)).toList();
        onvifCameraControllers = cameras.map((c) => TextEditingController(text: c.onvifCamera)).toList();

      });

      final hinhLo = losam?.hinhAnh;

      if (hinhLo?.isNotEmpty ?? false) {
        if (hinhLo!.startsWith('http')) {
          if (!mounted) return;
          setState(() {
            _selectedImageUrl = hinhLo;
            _selectedImage = null;
          });
        } else {
          final file = await base64ToFile(hinhLo, "anh_lo.jpg");
          if (!mounted) return;
          setState(() {
            _selectedImage = file;
            _selectedImageUrl = null;
          });
        }
      }

  }

  Future<File> base64ToFile(String base64String, String fileName) async {
    final bytes = base64Decode(base64String);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageUrl = null;
    });
  }

  void _updateLoSamData(String field, dynamic value) {
    setState(() {
      switch (field) {
        case 'maLo':
          loSamData.maLo = value.toString();
          break;
        case 'tenLo':
          loSamData.tenLo = value.toString();
          break;
        case 'soHang':
          loSamData.soHang =
              value is int ? value : int.tryParse(value.toString()) ?? 1;
          _updateDienTich();
          break;
        case 'soCot':
          loSamData.soCot =
              value is int ? value : int.tryParse(value.toString()) ?? 1;
          _updateDienTich();
          break;
        case 'dienTich':
          loSamData.dienTich =
              value is double ? value : double.tryParse(value.toString()) ?? 0;
          break;
        case 'ghiChu':
          loSamData.ghiChu = value.toString();
          break;
        case 'loai':
          loSamData.loai = value.toString();
          break;
      }

      // Clear error
      if (errors.containsKey(field)) {
        errors.remove(field);
      }
    });
  }

  void _updateDienTich() {
    loSamData.dienTich = (loSamData.soHang * loSamData.soCot).toDouble();
  }

  void _addChiTiet() {
    setState(() {
      chiTiets.add(LoSamChiTietModel(
        id: 0,
        loSamId: widget.zoneid ?? 0,
        loSamLoaiTuoiId: 1,
        soLuong: 0,
        trangThai: 1,
      ));
    });
  }

  void _removeChiTiet(int index) {
    setState(() {
      chiTiets.removeAt(index);
    });
  }

  void _updateChiTiet(int index, String field, dynamic value) {
    final oldItem = chiTiets[index];

    final updatedItem = LoSamChiTietModel(
      id: oldItem.id,
      loSamId: oldItem.loSamId,
      loSamLoaiTuoiId: field == 'loSamLoaiTuoiId'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 1)
          : oldItem.loSamLoaiTuoiId,
      soLuong: field == 'soLuong'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 0)
          : oldItem.soLuong,
      trangThai: 1,
    );

    setState(() {
      chiTiets[index] = updatedItem;
    });
  }

  void _addCamera() {
    setState(() {
      // Thêm camera mới
      cameras.add(LoSamCameraModel(
        id: 0,
        loSamId: widget.zoneid ?? 0,
        loSamLoaiCameraId: 1,
        trangThai: 1,
        rtsp: '',
        userName: '',
        password: '',
          ipCamera: '',
          onvifCamera: ''
      ));

      // Thêm controller tương ứng
      rtspControllers.add(TextEditingController());
      userNameControllers.add(TextEditingController());
      passwordControllers.add(TextEditingController());
      ipCameraControllers.add(TextEditingController());
      onvifCameraControllers.add(TextEditingController());
    });
  }

  void _removeCamera(int index) {
    setState(() {
      cameras.removeAt(index);
      rtspControllers.removeAt(index);
    });
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
      ),
    );
  }
  List<SensorModel> _getSelectedSensorModels() {
    return OptionSensor
        ?.where((sensor) => sensorid.contains(sensor.sensorId))
        .toList() ?? [];
  }

  // Phương thức hiển thị Dialog chọn Sensor
  Future<void> _showSensorSelectionDialog() async {
    // Lấy danh sách sensor có sẵn
    final List<SensorModel>? availableOptions = OptionSensor;

    // Tạo một bản sao (Set) để lưu trữ các lựa chọn tạm thời trong Dialog
    // Sử dụng Set để thao tác Thêm/Xóa nhanh hơn
    Set<int> tempSelectedIds = sensorid.toSet();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Thiết Bị'),
              // ➡️ THAY ĐỔI LỚN Ở ĐÂY: Sử dụng Container và ListView.builder
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8, // Chiều rộng tương đối
                height: MediaQuery.of(context).size.height * 0.5, // Chiều cao tối đa

                child: ListView.builder(
                  // ➡️ Cải thiện hiệu suất: Chỉ xây dựng các widget cần thiết
                  itemCount: availableOptions?.length,
                  itemBuilder: (context, index) {
                    final sensor = availableOptions?[index];
                    final bool isChecked = tempSelectedIds.contains(sensor?.sensorId);

                    return CheckboxListTile(
                      // Thiết kế gọn gàng hơn
                      contentPadding: EdgeInsets.zero, // Loại bỏ padding thừa
                      title: Text(sensor!.sensorCode, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      subtitle: Text('Đơn vị: ${sensor.unit}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      value: isChecked,
                      onChanged: (bool? newValue) {
                        setStateDialog(() {
                          if (newValue == true) {
                            tempSelectedIds.add(sensor.sensorId);
                          } else {
                            tempSelectedIds.remove(sensor.sensorId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              // Actions (Giữ nguyên)
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Xác nhận'),
                  onPressed: () {
                    setState(() {
                      // Cập nhật state chính của Widget khi xác nhận
                      sensorid = tempSelectedIds.toList(); // Đã đổi tên biến lưu trữ là selectedSensorIds
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  // Phương thức xóa một sensor đã chọn
  void _removeSensor(int index) {
    setState(() {
      final sensorToRemove = _getSelectedSensorModels()[index];
      sensorid.remove(sensorToRemove.sensorId);
    });
  }

  // Widget hiển thị từng sensor đã chọn (itemBuilder)
  // Phần này nằm trong _SensorOptionSelectionState
  Widget _buildSensorItem(int index) {
    final sensor = _getSelectedSensorModels()[index];

    // Kiểm tra xem đây có phải là mục cuối cùng không
    final bool isLastItem = index == _getSelectedSensorModels().length - 1;

    return Padding(
      // 1. Thêm Padding trên và dưới cho nội dung
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã Sensor: ${sensor.sensorCode}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4), // Khoảng cách nhỏ
                    Text(
                      'Đơn vị: ${sensor.unit}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              InkWell(
                onTap: () => _removeSensor(index),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    // ➡️ ĐÃ THAY ĐỔI: Sử dụng Icons.delete_outline hoặc Icons.delete
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 22, // Tăng kích thước lên một chút để dễ nhìn hơn
                  ),
                ),
              ),
            ],
          ),

          // 2. Thêm Divider giữa các mục (Trừ mục cuối cùng)
          if (!isLastItem)
            const Padding(
              padding: EdgeInsets.only(top: 10.0), // Padding trên Divider
              child: Divider(height: 1, thickness: 0.5),
            ),
        ],
      ),
    );
  }
  void _updateCamera(int index, String field, dynamic value) {
    final oldItem = cameras[index];

    final updatedItem = LoSamCameraModel(
      id: oldItem.id,
      loSamId: oldItem.loSamId,
      loSamLoaiCameraId: field == 'loSamLoaiCameraId'
          ? (value is int ? value : int.tryParse(value.toString()) ?? 1)
          : oldItem.loSamLoaiCameraId,
      rtsp: field == 'rtsp' ? value?.toString() ?? '' : oldItem.rtsp,
      trangThai: oldItem.trangThai,
      userName: field == 'userName' ? value?.toString() ?? '' : oldItem.userName,
      password: field == 'password' ? value?.toString() ?? '' : oldItem.password,
      ipCamera: field == 'ipCamera' ? value?.toString() ?? '' : oldItem.ipCamera,
      onvifCamera: field == 'onvifCamera' ? value?.toString() ?? '' : oldItem.onvifCamera,
    );

    if (field == 'loSamLoaiCameraId') {
      setState(() {
        cameras[index] = updatedItem;
      });
    } else {
      cameras[index] = updatedItem; // cập nhật dữ liệu nhưng không rebuild
    }
  }



  bool _validateForm() {
    errors.clear();

    if (loSamData.maLo.trim().isEmpty) {
      errors['maLo'] = 'Mã lô là bắt buộc';
    }

    if (loSamData.tenLo.trim().isEmpty) {
      errors['tenLo'] = 'Tên lô là bắt buộc';
    }

    if (loSamData.loai.isEmpty) {
      errors['loai'] = 'Loại lô là bắt buộc';
    }

    if (loSamData.soHang < 1) {
      errors['soHang'] = 'Số hàng phải lớn hơn 0';
    }

    if (loSamData.soCot < 1) {
      errors['soCot'] = 'Số cột phải lớn hơn 0';
    }
    // if(_selectedImage == null){
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(
    //       content: Text('Vui lòng tải hình ảnh của lô sâm'),
    //       backgroundColor: Colors.red,
    //     ),
    //   );
    // }

    // Validate chi tiets
    for (int i = 0; i < chiTiets.length; i++) {
      if (chiTiets[i].soLuong < 0) {
        errors['chiTiet_${i}_soLuong'] = 'Số lượng không được âm';
      }
    }

    // Validate cameras
    // for (int i = 0; i < cameras.length; i++) {
    //   if (cameras[i].rtsp.isNotEmpty &&
    //       !cameras[i].rtsp.startsWith('rtsp://')) {
    //     errors['camera_${i}_rtsp'] = 'RTSP phải bắt đầu với rtsp://';
    //   }
    //   if (cameras[i].url.isNotEmpty && !cameras[i].url.startsWith('http')) {
    //     errors['camera_${i}_url'] =
    //         'URL phải bắt đầu với http:// hoặc https://';
    //   }
    // }

    setState(() {});
    return errors.isEmpty;
  }

  void _handleSubmit() {
    if (!_validateForm()) {
      return;
    }

    final submitData = {
      'LoSam': {
        'MaLo': maLoController?.text,
        'TenLo': tenLoController?.text,
        'SoHang': loSamData.soHang,
        'SoCot': loSamData.soCot,
        'DienTich': loSamData.dienTich,
        'GhiChu': ghichuLoController?.text,
        'Loai': loaiLoController?.text,
        'TrangThai': loSamData.trangThai,
        'VuonTrong_ID': loSamData.vuonTrongId,
        'Ngay': DateTime.now().toIso8601String(),
      },
      'LoSamChiTiets': chiTiets
          .map((ct) => {
                'LoSamLoaiTuoiId': ct.loSamLoaiTuoiId,
                'SoLuong': ct.soLuong,
                'TrangThai': ct.trangThai,
              })
          .toList(),
      'LoSamCameras': List.generate(
          cameras.length,
          (index) => {
                'LoSamLoaiCameraId': cameras[index].loSamLoaiCameraId,
                'RTSP': rtspControllers[index]?.text,
                'userName': userNameControllers[index]?.text,
                'password': passwordControllers[index]?.text,
                'ipCamera': ipCameraControllers[index]?.text,
                'onvifCamera': onvifCameraControllers[index]?.text,
                'TrangThai': cameras[index].trangThai ?? 1,
              }),
      'SensorIds': sensorid,
    };

    widget.onSubmit(submitData, losam?.loSamId ?? 0, image: _selectedImage);
  }

  Future<void> _showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Chụp ảnh'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Xóa ảnh', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageUrl = null;
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageUrl = null;
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chụp ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.zoneid == null
          ? AppBar(
              title: const Text('Thêm lô'),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : AppBar(
              title: const Text('Chỉnh sửa lô'),
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
      body: _isLoaded
          ? Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionCard(
                      title: 'Thông tin cơ bản',
                      icon: Icons.info_outline,
                      children: [
                        _buildTextField(
                          label: 'Mã lô *',
                          controller: maLoController,
                          onChanged: (value) => _updateLoSamData('maLo', value),
                          errorKey: 'maLo',
                          hintText: 'VD: T001',
                        ),
                        _buildTextField(
                          label: 'Tên lô *',
                          controller: tenLoController,
                          onChanged: (value) =>
                              _updateLoSamData('tenLo', value),
                          errorKey: 'tenLo',
                          hintText: 'VD: Lô Sâm A',
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNumberField(
                                label: 'Số hàng *',
                                value: loSamData.soHang,
                                onChanged: (value) =>
                                    _updateLoSamData('soHang', value),
                                errorKey: 'soHang',
                                min: 1,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildNumberField(
                                label: 'Số cột *',
                                value: loSamData.soCot,
                                onChanged: (value) =>
                                    _updateLoSamData('soCot', value),
                                errorKey: 'soCot',
                                min: 1,
                              ),
                            ),
                          ],
                        ),
                        _buildTextField(
                          label: 'Loại lô *',
                          controller: loaiLoController,
                          onChanged: (value) => _updateLoSamData('loai', value),
                          errorKey: 'loai',
                          hintText: 'VD: Mái vòm,..',
                        ),
                        _buildTextField(
                          label: 'Ghi chú',
                          controller: ghichuLoController,
                          onChanged: (value) =>
                              _updateLoSamData('ghiChu', value),
                          maxLines: 3,
                          hintText: 'Ghi chú về lô sâm...',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hình ảnh lô',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image Preview
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey.shade50,
                              ),
                              child: (_selectedImage != null ||
                                      _selectedImageUrl != null)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Stack(
                                        children: [
                                          // Nếu có URL thì hiển thị từ server
                                          if (_selectedImageUrl != null)
                                            Image.network(
                                              _selectedImageUrl!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (context, child, progress) {
                                                if (progress == null)
                                                  return child;
                                                return const Center(
                                                    child:
                                                        CircularProgressIndicator());
                                              },
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildErrorImage(),
                                            )
                                          // Nếu có file local thì hiển thị File
                                          else if (_selectedImage != null)
                                            Image.file(
                                              _selectedImage!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  _buildErrorImage(),
                                            ),

                                          // Nút xóa ảnh
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: _removeImage,
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding:
                                                    const EdgeInsets.all(4),
                                                child: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 20),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.image,
                                            size: 48,
                                            color: Colors.grey.shade400),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Chưa có hình ảnh',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _showImagePickerDialog,
                                icon: const Icon(Icons.camera_alt),
                                label: Text(
                                  (_selectedImage != null ||
                                          _selectedImageUrl != null)
                                      ? 'Thay đổi ảnh'
                                      : 'Chọn ảnh',
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Hỗ trợ định dạng: JPG, PNG, GIF (tối đa 5MB)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicSection(
                      title: 'Chi tiết lô',
                      icon: Icons.grass,
                      items: chiTiets,
                      onAdd: _addChiTiet,
                      onRemove: _removeChiTiet,
                      itemBuilder: (index) => _buildChiTietItem(index),
                    ),
                    const SizedBox(height: 16),
                    // Camera Section
                    _buildDynamicSection(
                      title: 'Camera giám sát',
                      icon: Icons.camera_alt,
                      items: cameras,
                      onAdd: _addCamera,
                      onRemove: _removeCamera,
                      itemBuilder: (index) => _buildCameraItem(index),
                    ),

                    const SizedBox(height: 32),
                    _buildDynamicSectionSensor<SensorModel>(
                    title: 'Cấu hình Thiết bị',
                    icon: Icons.sensors,
                    items: _getSelectedSensorModels(), // List<SensorModel> đã chọn
                    onAdd: _showSensorSelectionDialog,  // Mở Dialog khi click Thêm
                    onRemove: _removeSensor,            // Hàm xóa sensor
                    itemBuilder: _buildSensorItem,      // Widget hiển thị từng sensor
                  ),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        widget.zoneid == null ?
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 16),
                                SizedBox(width: 8),
                                Text('Lưu'),
                              ],
                            ),
                          ),
                        ):
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Lưu'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ) :const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSectionSensor<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required Widget Function(int) itemBuilder,
  }) {
    // ... (Giữ nguyên code _buildDynamicSection của bạn)
    // Tôi sẽ chỉ đưa phần return chính để giảm độ dài
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 22, color: Colors.green.shade700),
                    const SizedBox(width  : 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 4),

            // Danh sách
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: List.generate(items.length, (index) {
                  return itemBuilder(index);
                }),
              ),
          ],
        ),
      ),
    );
    // ...
  }
  Widget _buildDynamicSection<T>({
    required String title,
    required IconData icon,
    required List<T> items,
    required VoidCallback onAdd,
    required Function(int) onRemove,
    required Widget Function(int) itemBuilder,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 22, color: Colors.green.shade700),
                    const SizedBox(width  : 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            // Danh sách
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Chưa có dữ liệu',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: List.generate(items.length, (index) {
                  return itemBuilder(index);
                }),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChiTietItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chi tiết Cây Trồng #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                onPressed: () => _removeChiTiet(index),
                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                tooltip: 'Xóa chi tiết',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildDropdownField(
                  label: 'Loại tuổi sâm',
                  value: chiTiets[index].loSamLoaiTuoiId,
                  items: OptionLoSamLoaiTuoi,
                  onChanged: (value) =>
                      _updateChiTiet(index, 'loSamLoaiTuoiId', value),
                  prefixIcon: Icons.eco_outlined,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildNumberField(
                  label: 'Số lượng',
                  value: chiTiets[index].soLuong,
                  onChanged: (value) =>
                      _updateChiTiet(index, 'soLuong', value),
                  errorKey: 'chiTiet_${index}_soLuong',
                  min: 0,
                  prefixIcon: Icons.tag,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraItem(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Camera Giám Sát #${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              IconButton(
                onPressed: () => _removeCamera(index),
                icon: Icon(Icons.close, color: Colors.grey.shade600, size: 20),
                tooltip: 'Xóa camera',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                                                                                                                                                                                                                     ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDropdownField(
            label: 'Loại camera',
            value: cameras[index].loSamLoaiCameraId,
            items: OptionLoaiCamera,
            onChanged: (value) =>
                _updateCamera(index, 'loSamLoaiCameraId', value.toString()),
            prefixIcon: Icons.videocam_outlined,
          ),
          _buildTextField(
            label: 'User Name',
            controller: userNameControllers[index],
            onChanged: (value) => _updateCamera(index, 'userName', value),
            errorKey: 'camera_${index}_userName',
            hintText: 'User Name',
            prefixIcon: Icons.verified_user,
          ),
        _buildPasswordField(
        context: context, // PHẢI TRUYỀN context
        label: 'Pass',
        controller: passwordControllers[index],
        onChanged: (value) => _updateCamera(index, 'password', value),
        errorKey: 'camera_${index}_password',
        hintText: 'Password',
        prefixIcon: Icons.lock_outline,
        errors: errors, // Map lỗi
      ),
          _buildTextField(
            label: 'IP Camera',
            controller: ipCameraControllers[index],
            onChanged: (value) => _updateCamera(index, 'ipCamera', value),
            errorKey: 'camera_${index}_userName',
            hintText: 'User Name',
            prefixIcon: Icons.verified_user,
          ),
          _buildTextField(
            label: 'RTSP Stream',
            controller: rtspControllers[index],
            onChanged: (value) => _updateCamera(index, 'rtsp', value),
            errorKey: 'camera_${index}_rtsp',
            hintText: 'rtsp://user:pass@ip:port/stream',
            prefixIcon: Icons.link,
          ),
          _buildTextField(
            label: 'Ovif Camera',
            controller: onvifCameraControllers[index],
            onChanged: (value) => _updateCamera(index, 'onvifCamera', value),
            errorKey: 'camera_${index}_userName',
            hintText: 'User Name',
            prefixIcon: Icons.verified_user,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController? controller,
    required Function(String) onChanged,
    String? errorKey,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
    IconData? prefixIcon, // ✅ THÊM THAM SỐ MỚI
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        readOnly: readOnly,
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null, // ✅ SỬ DỤNG ICON
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          errorText: errorKey != null ? errors[errorKey] : null,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
  Widget _buildPasswordField({
    required BuildContext context, // Cần truyền context để dùng StatefulBuilder
    required String label,
    required TextEditingController? controller,
    required Function(String) onChanged,
    required Map<String, String?> errors, // Cần Map lỗi từ ngoài vào
    String? errorKey,
    String? hintText,
    IconData? prefixIcon,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    // Sử dụng StatefulBuilder để quản lý trạng thái _isObscure cục bộ
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setStateBuilder) {
        final ValueNotifier<bool> isObscureNotifier = ValueNotifier(true);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),

          // ValueListenableBuilder giúp rebuild chỉ Icon khi trạng thái thay đổi
          child: ValueListenableBuilder<bool>(
            valueListenable: isObscureNotifier,
            builder: (context, isObscure, child) {
              return TextFormField(
                controller: controller,
                onChanged: onChanged,
                maxLines: maxLines,
                readOnly: readOnly,

                // ➡️ Ẩn ký tự
                obscureText: isObscure,
                keyboardType: TextInputType.visiblePassword,

                decoration: InputDecoration(
                  prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null,

                  // ➡️ NÚT CHUYỂN ĐỔI (Suffix Icon)
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      // Cập nhật giá trị trong ValueNotifier
                      isObscureNotifier.value = !isObscureNotifier.value;
                    },
                  ),

                  // Các thuộc tính trang trí khác
                  labelText: label,
                  hintText: hintText,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  errorText: errorKey != null ? errors[errorKey] : null,
                  filled: readOnly,
                  fillColor: readOnly ? Colors.grey.shade100 : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNumberField({
    required String label,
    required num value,
    required Function(num) onChanged,
    String? errorKey,
    num? min,
    bool isDouble = false,
    bool readOnly = false,
    String? helperText,
    IconData? prefixIcon, // ✅ THÊM THAM SỐ MỚI
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(value),
        initialValue: value.toString(),
        onChanged: (val) {
          num parsedValue;
          if (isDouble) {
            parsedValue = double.tryParse(val) ?? 0;
          } else {
            parsedValue = int.tryParse(val) ?? 0;
          }
          if (min != null && parsedValue < min) {
            parsedValue = min;
          }
          onChanged(parsedValue);
        },
        keyboardType: TextInputType.numberWithOptions(
          decimal: isDouble,
          signed: false,
        ),
        readOnly: readOnly,
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null, // ✅ SỬ DỤNG ICON
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          errorText: errorKey != null ? errors[errorKey] : null,
          helperText: helperText,
          filled: readOnly,
          fillColor: readOnly ? Colors.grey.shade100 : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required dynamic value,
    required List<OptionModel> items,
    required Function(dynamic) onChanged,
    String? errorKey,
    IconData? prefixIcon, // ✅ THÊM THAM SỐ MỚI
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: value is int ? value : int.tryParse(value?.toString() ?? ''),
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey.shade600) : null, // ✅ SỬ DỤNG ICON
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          errorText: errorKey != null ? errors[errorKey] : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        items: items.map<DropdownMenuItem<int>>((item) {
          final intVal = int.tryParse(item.value.toString()) ?? 0;
          return DropdownMenuItem<int>(
            value: intVal,
            child: Text(item.text),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }
}
