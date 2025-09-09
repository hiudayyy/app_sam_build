import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cay_sam.dart';
import '../data/mock_data.dart';

class BatchDiaryUpdateScreen extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(Map<String, dynamic>) onSubmit;

  const BatchDiaryUpdateScreen({
    Key? key,
    required this.onCancel,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<BatchDiaryUpdateScreen> createState() => _BatchDiaryUpdateScreenState();
}

class _BatchDiaryUpdateScreenState extends State<BatchDiaryUpdateScreen> {
  String _selectionMode = 'individual'; // 'individual', 'region', 'status'
  String _selectedRegion = '';
  List<String> _selectedPlantIds = [];

  final _formKey = GlobalKey<FormState>();
  DateTime _ngayGhi = DateTime.now();
  final _soLaController = TextEditingController();
  int _diemSucKhoe = 5;
  final _ghiChuController = TextEditingController();

  Map<String, bool> _tinhTrang = {
    'song': true,
    'ngu_dong': false,
    'chet': false,
  };

  @override
  void dispose() {
    _soLaController.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ngayGhi,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _ngayGhi) {
      setState(() {
        _ngayGhi = picked;
      });
    }
  }

  void _selectByRegion(String region) {
    setState(() {
      _selectedRegion = region;
      _selectedPlantIds = MockData.mockPlants
          .where((plant) => plant.viTri?.contains('Khu $region') == true)
          .map((plant) => plant.id)
          .toList();
    });
  }

  void _selectByStatus(String status) {
    List<String> plantIds = [];

    if (status == 'needs_update') {
      // Plants that need update (older than 7 days)
      final now = DateTime.now();
      plantIds = MockData.mockPlants
          .where((plant) {
        // Since we don't have lastUpdate field, use ngayTrong as fallback
        final daysSince = now.difference(plant.ngayTrong ?? now).inDays;
        return daysSince > 7;
      })
          .map((plant) => plant.id)
          .toList();
    } else if (status == 'weak') {
      // Plants with poor health status
      plantIds = MockData.mockPlants
          .where((plant) => plant.trangThai == TrangThaiCay.yeu || plant.trangThai == TrangThaiCay.benh)
          .map((plant) => plant.id)
          .toList();
    }

    setState(() {
      _selectedPlantIds = plantIds;
    });
  }

  void _togglePlantSelection(String plantId) {
    setState(() {
      if (_selectedPlantIds.contains(plantId)) {
        _selectedPlantIds.remove(plantId);
      } else {
        _selectedPlantIds.add(plantId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedPlantIds = MockData.mockPlants
          .map((plant) => plant.id)
          .toList();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPlantIds.clear();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn ít nhất một cây'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updateData = {
      'plantIds': _selectedPlantIds,
      'ngayGhi': _ngayGhi.toIso8601String(),
      'soLa': _soLaController.text.isNotEmpty ? int.tryParse(_soLaController.text) : null,
      'diemSucKhoe': _diemSucKhoe,
      'tinhTrang': _tinhTrang,
      'ghiChu': _ghiChuController.text.trim(),
      'nguoiCapNhat': 'current_user', // Should get from auth
    };

    await widget.onSubmit(updateData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: widget.onCancel,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cập nhật hàng loạt',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              'Cập nhật nhật ký cho nhiều cây',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Selection Mode Toggle
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectionMode = 'individual'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectionMode == 'individual'
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade200,
                      foregroundColor: _selectionMode == 'individual'
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: Text('Chọn riêng lẻ'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _selectionMode = 'region'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectionMode == 'region'
                          ? Theme.of(context).primaryColor
                          : Colors.grey.shade200,
                      foregroundColor: _selectionMode == 'region'
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: Text('Theo vùng'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Selection Section
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chọn cây cần cập nhật',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),

                        if (_selectionMode == 'individual') ...[
                          // Individual Plant Selection
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _selectAll,
                                child: Text('Chọn tất cả'),
                              ),
                              SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: _clearSelection,
                                child: Text('Bỏ chọn'),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              itemCount: MockData.mockPlants.length,
                              itemBuilder: (context, index) {
                                final plant = MockData.mockPlants[index];
                                final isSelected = _selectedPlantIds.contains(plant.id);

                                return CheckboxListTile(
                                  title: Text(plant.tenCay ?? 'Unknown'),
                                  subtitle: Text('${plant.id} - ${plant.viTri}'),
                                  value: isSelected,
                                  onChanged: (bool? value) {
                                    _togglePlantSelection(plant.id);
                                  },
                                );
                              },
                            ),
                          ),
                        ] else if (_selectionMode == 'region') ...[
                          // Region Selection
                          Text('Chọn khu vực:'),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['A', 'B', 'C', 'D'].map((region) {
                              return FilterChip(
                                label: Text('Khu vực $region'),
                                selected: _selectedRegion == region,
                                onSelected: (bool selected) {
                                  if (selected) {
                                    _selectByRegion(region);
                                  } else {
                                    setState(() {
                                      _selectedRegion = '';
                                      _selectedPlantIds.clear();
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ] ,

                        if (_selectedPlantIds.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'Đã chọn ${_selectedPlantIds.length} cây',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Update Form Section
                if (_selectedPlantIds.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Thông tin cập nhật',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Ngày ghi
                            InkWell(
                              onTap: _selectDate,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Ngày ghi nhận',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(_formatDate(_ngayGhi)),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Số lá
                            TextFormField(
                              controller: _soLaController,
                              decoration: InputDecoration(
                                labelText: 'Số lá (trung bình)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16),

                            // Điểm sức khỏe
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Điểm sức khỏe: $_diemSucKhoe/5'),
                                Slider(
                                  value: _diemSucKhoe.toDouble(),
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  onChanged: (value) {
                                    setState(() {
                                      _diemSucKhoe = value.toInt();
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Tình trạng
                            Text('Tình trạng:'),
                            Column(
                              children: _tinhTrang.keys.map((key) {
                                String label = key == 'song' ? 'Sống' :
                                key == 'ngu_dong' ? 'Ngủ đông' : 'Chết';
                                return CheckboxListTile(
                                  title: Text(label),
                                  value: _tinhTrang[key],
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _tinhTrang[key] = value ?? false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 16),

                            // Ghi chú
                            TextFormField(
                              controller: _ghiChuController,
                              decoration: InputDecoration(
                                labelText: 'Ghi chú chung',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onCancel,
                          child: Text('Hủy'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          child: Text('Cập nhật ${_selectedPlantIds.length} cây'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}