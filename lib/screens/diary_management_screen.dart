import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/mock_data.dart';
import '../models/cay_sam.dart';
import '../models/nhat_ky.dart';
import '../models/user.dart';
import '../widgets/protected_route.dart';
import 'batch_diary_update_screen.dart';
import '../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DiaryManagementScreen extends StatefulWidget {
  @override
  _DiaryManagementScreenState createState() => _DiaryManagementScreenState();
}

class _DiaryManagementScreenState extends State<DiaryManagementScreen> with TickerProviderStateMixin {
  TabController? _tabController;
  String _searchTerm = '';
  String _statusFilter = 'all';
  List<String> _selectedPlantsForUpdate = [];
  bool _showBatchForm = false;
  String? _showIndividualEdit;

  late List<DiaryEntry> _diaryEntries;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeDiaryEntries();
  }

  void _initializeDiaryEntries() {
    _diaryEntries = MockData.mockDiary.map((diary) {
      final plant = MockData.mockPlants.firstWhere(
            (p) => p.nhatKyId == diary.id,
        orElse: () => CaySam.empty(),
      );

      final parsedDate = DateTime.tryParse(diary.ngayGhi ?? "");
      final lastUpdateDate = parsedDate ?? DateTime.now(); // fallback = hôm nay
      final daysSinceUpdate = DateTime.now().difference(lastUpdateDate).inDays;

      return DiaryEntry(
        diary: diary,
        plant: plant.id.isNotEmpty ? plant : null,
        needsReview: daysSinceUpdate > 7,
        lastUpdate: diary.ngayGhi ?? "", // vẫn giữ string gốc
      );
    }).toList();
  }


  List<DiaryEntry> get _filteredEntries {
    return _diaryEntries.where((entry) {
      if (entry.plant == null) return false;

      final matchesSearch = _searchTerm.isEmpty ||
          (entry.plant!.tenCay?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false) ||
          entry.plant!.id.toLowerCase().contains(_searchTerm.toLowerCase());

      bool matchesStatus = true;
      switch (_statusFilter) {
        case 'needs-review':
          matchesStatus = entry.needsReview;
          break;
        case 'healthy':
          matchesStatus = entry.diary.diemSucKhoe >= 4;
          break;
        case 'warning':
          matchesStatus = entry.diary.diemSucKhoe < 4;
          break;
      }

      return matchesSearch && matchesStatus;
    }).toList();
  }
  void _handleBatchUpdate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BatchDiaryUpdateScreen(
          onCancel: () => Navigator.of(context).pop(),
          onSubmit: (data) {
            _handleBatchSubmit(data);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
  /*void _handleBatchUpdate() {
    setState(() {
      _selectedPlantsForUpdate = _filteredEntries.map((e) => e.plant?.id ?? '').where((id) => id.isNotEmpty).toList();
      _showBatchForm = true;
    });
  }
*/
  void _handleBatchSubmit(Map<String, dynamic> data) {
    print('Batch diary update: $data');
    setState(() {
      _showBatchForm = false;
      _selectedPlantsForUpdate.clear();
    });
    // Here would integrate with backend
  }

  void _handleIndividualEdit(String entryId) {
    setState(() {
      _showIndividualEdit = entryId;
    });
  }

  Color _getHealthBadgeColor(int score) {
    if (score >= 4) return Colors.green.shade100;
    if (score >= 3) return Colors.yellow.shade100;
    return Colors.red.shade100;
  }

  Color _getHealthTextColor(int score) {
    if (score >= 4) return Colors.green.shade800;
    if (score >= 3) return Colors.yellow.shade800;
    return Colors.red.shade800;
  }

  String _getHealthLabel(int score) {
    if (score >= 4) return 'Khỏe mạnh';
    if (score >= 3) return 'Trung bình';
    return 'Yếu';
  }

  @override
  Widget build(BuildContext context) {
    // Show batch update form
    if (_showBatchForm) {
      return _buildBatchUpdateForm();
    }

    // Show individual edit form
    if (_showIndividualEdit != null) {
      final entry = _diaryEntries.firstWhere(
            (e) => e.diary.id == _showIndividualEdit,
        orElse: () => _diaryEntries.first,
      );
      return _buildIndividualEditForm(entry);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.book, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản lý Nhật ký',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Theo dõi và cập nhật tình trạng cây sâm định kỳ',
                              style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green.shade600,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.green.shade600,
                tabs: [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Hàng loạt'),
                  Tab(text: 'Riêng lẻ'),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildBatchUpdateTab(),
                  _buildIndividualTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats cards
          _buildStatsCards(),
          SizedBox(height: 16),

          // Search and filter
          _buildSearchAndFilter(),
          SizedBox(height: 16),

          // Diary entries list
          _buildDiaryEntriesList(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final totalTrees = _diaryEntries.length;
    final healthyTrees = _diaryEntries.where((e) => e.diary.diemSucKhoe >= 4).length;
    final warningTrees = _diaryEntries.where((e) => e.diary.diemSucKhoe < 4).length;
    final needsReview = _diaryEntries.where((e) => e.needsReview).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Tổng cây',
            value: '$totalTrees',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            title: 'Khỏe mạnh',
            value: '$healthyTrees',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            title: 'Cần theo dõi',
            value: '$warningTrees',
            icon: Icons.warning,
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            title: 'Cần cập nhật',
            value: '$needsReview',
            icon: Icons.schedule,
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
          ),
        ],
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
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * 0.04, // 1.8% chiều cao màn hình
            ),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm cây...',
              hintStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
              ),
              prefixIcon: Icon(Icons.search,
                size: MediaQuery.of(context).size.width * 0.04,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green.shade600),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _statusFilter,
            decoration: InputDecoration(
              labelText: 'Lọc theo trạng thái',
              labelStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.green.shade600),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text('Tất cả',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                ),
              ),
              DropdownMenuItem(
                value: 'needs-review',
                child: Text('Cần cập nhật',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                ),
              ),
              DropdownMenuItem(
                value: 'healthy',
                child: Text('Khỏe mạnh',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                ),
              ),
              DropdownMenuItem(
                value: 'warning',
                child: Text('Cần theo dõi',
                  style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _statusFilter = value ?? 'all';
              });
            },
          ),
        ],
      )
    );
  }

  Widget _buildDiaryEntriesList() {
    if (_filteredEntries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.book, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không tìm thấy nhật ký phù hợp',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredEntries.map((entry) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.plant?.tenCay ?? '',
                    style: TextStyle(fontWeight: FontWeight.w500,fontSize: MediaQuery.of(context).size.width * 0.035),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    entry.plant?.id ?? '',
                    style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.027, color: Colors.grey.shade600),
                  ),
                ),
                if (entry.needsReview)
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cần cập nhật',
                      style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.027, color: Colors.orange.shade800),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Số lá: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                    Text(
                      '${entry.diary.soLa}',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Sức khỏe: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getHealthBadgeColor(entry.diary.diemSucKhoe),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_getHealthLabel(entry.diary.diemSucKhoe)} (${entry.diary.diemSucKhoe}/5)',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.027,
                          color: _getHealthTextColor(entry.diary.diemSucKhoe),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Cập nhật: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                    Text(
                      entry.diary.ngayGhi != null && entry.diary.ngayGhi!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                          .format(DateTime.parse(entry.diary.ngayGhi!).toLocal())
                          : "",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.03,),
                    Text(
                      'Vị trí: ',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                    Text(
                      entry.plant?.viTri ?? '',
                      style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03,),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
            onTap: () => _handleIndividualEdit(entry.diary.id.toString()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBatchUpdateTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.green.shade600),
                SizedBox(width: 8),
                Text(
                  'Cập nhật hàng loạt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Chọn các cây cần cập nhật nhật ký và điền thông tin chung',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 20),
            ProtectedRoute(
              requiredPermission: Permission.batchUpdateDiary,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _handleBatchUpdate,
                  icon: Icon(Icons.add),
                  label: Text('Bắt đầu cập nhật hàng loạt'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              fallback: Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndividualTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, color: Colors.green.shade600),
                    SizedBox(width: 8),
                    Text(
                      'Chỉnh sửa riêng lẻ',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Chọn một cây để chỉnh sửa thông tin chi tiết',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredEntries.length,
              itemBuilder: (context, index) {
                final entry = _filteredEntries[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(entry.plant?.tenCay ?? ''),
                    subtitle: Text(entry.plant?.id ?? ''),
                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                    onTap: () => _handleIndividualEdit(entry.diary.id.toString()),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchUpdateForm() {
    return BatchUpdateForm(
      plantIds: _selectedPlantsForUpdate,
      onSubmit: _handleBatchSubmit,
      onCancel: () {
        setState(() {
          _showBatchForm = false;
          _selectedPlantsForUpdate.clear();
        });
      },
    );
  }

  Widget _buildIndividualEditForm(DiaryEntry entry) {
    return IndividualEditForm(
      entry: entry,
      onSubmit: (data) {
        print('Individual diary update: $data');
        setState(() {
          _showIndividualEdit = null;
        });
      },
      onCancel: () {
        setState(() {
          _showIndividualEdit = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}

class DiaryEntry {
  final CaySamNhatKy diary;
  final CaySam? plant;
  final bool needsReview;
  final String lastUpdate;

  DiaryEntry({
    required this.diary,
    this.plant,
    required this.needsReview,
    required this.lastUpdate,
  });
}

// Batch Update Form Component
class BatchUpdateForm extends StatefulWidget {
  final List<String> plantIds;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const BatchUpdateForm({
    Key? key,
    required this.plantIds,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  _BatchUpdateFormState createState() => _BatchUpdateFormState();
}

class _BatchUpdateFormState extends State<BatchUpdateForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _formData = {
      'ngayGhi': DateTime.now().toIso8601String().split('T')[0],
      'soLa': '',
      'diemSucKhoe': '5',
      'tinhTrang': {
        'song': true,
        'nguDong': false,
        'chet': false,
      },
      'ghiChu': '',
      'individualOverrides': <String, dynamic>{},
    };
  }

  @override
  Widget build(BuildContext context) {
    final plants = MockData.mockPlants.where((p) => widget.plantIds.contains(p.id)).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Cập nhật nhật ký hàng loạt'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Form content here - simplified for now
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Batch Update Form'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => widget.onSubmit(_formData),
                      child: Text('Cập nhật'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Individual Edit Form Component
class IndividualEditForm extends StatefulWidget {
  final DiaryEntry entry;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const IndividualEditForm({
    Key? key,
    required this.entry,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  _IndividualEditFormState createState() => _IndividualEditFormState();
}

class _IndividualEditFormState extends State<IndividualEditForm> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _formData = {
      'ngayGhi': widget.entry.diary.ngayGhi,
      'soLa': widget.entry.diary.soLa.toString(),
      'diemSucKhoe': widget.entry.diary.diemSucKhoe.toString(),
      'tinhTrang': {
        'song': widget.entry.diary.tinhTrang,
        'nguDong': widget.entry.diary.tinhTrang,
        'chet': widget.entry.diary.tinhTrang,
      },
      'ghiChu': widget.entry.diary.ghiChu ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Chỉnh sửa nhật ký'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Individual Edit Formm'),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => widget.onSubmit(_formData),
                      child: Text('Cập nhật'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}