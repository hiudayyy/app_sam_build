import 'package:flutter/material.dart';

class AppInfoDialog extends StatefulWidget {
  const AppInfoDialog({Key? key}) : super(key: key);

  @override
  State<AppInfoDialog> createState() => _AppInfoDialogState();
}

class _AppInfoDialogState extends State<AppInfoDialog> {
  String _version = "1.0.0";
  String _buildNumber = "1";

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }
  Future<void> _initPackageInfo() async {
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // setState(() {
    //   _version = packageInfo.version;
    //   _buildNumber = packageInfo.buildNumber;
    // });

    // Giả lập loading
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _version = "1.0.0(5)";
      _buildNumber = "11012026";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông tin ứng dụng',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                ],
              ),
              const Divider(height: 30, thickness: 1),

              // --- LOGO & APP NAME ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                // Thay Icon bằng Image.asset('assets/logo.png') của bạn
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/samnghigia.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Sâm Nghị Gia",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "Version $_version (Build $_buildNumber)",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- INFO LIST ---
              _buildInfoRow(Icons.business, "Nhà phát triển", "HTX Công nghệ Thông tin huế"),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.email_outlined, "Hỗ trợ", "contact@huetechcoop.com"),
              const SizedBox(height: 16),
              _buildInfoRow(Icons.language, "Website", "https://huetechcoop.com"),

              const SizedBox(height: 30),

              // --- BUTTON CHECK UPDATE ---
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton.icon(
              //     onPressed: () {
              //       // Logic kiểm tra cập nhật
              //       ScaffoldMessenger.of(context).showSnackBar(
              //         const SnackBar(content: Text('Bạn đang sử dụng phiên bản mới nhất!')),
              //       );
              //     },
              //     icon: const Icon(Icons.system_update_alt_rounded, size: 18),
              //     label: const Text("Kiểm tra cập nhật"),
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Theme.of(context).primaryColor,
              //       foregroundColor: Colors.white,
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10),
              //       ),
              //       elevation: 2,
              //     ),
              //   ),
              // ),
              //
              // const SizedBox(height: 16),

              Text(
                "© 2026 HTX Công nghệ Thông tin Huế.",
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Mũi tên nhỏ nếu muốn biểu thị là nút bấm (ví dụ link web)
        if (title == "Website" || title == "Chính sách")
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade300)
      ],
    );
  }
}