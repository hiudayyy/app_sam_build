import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Cần thiết để dùng Clipboard

class WalletInfoDialog extends StatefulWidget {
  final String walletAddress;
  final VoidCallback onDisconnect;

  const WalletInfoDialog({
    Key? key,
    required this.walletAddress,
    required this.onDisconnect,
  }) : super(key: key);

  @override
  State<WalletInfoDialog> createState() => _WalletInfoDialogState();
}

class _WalletInfoDialogState extends State<WalletInfoDialog> {
  bool _isCopied = false;

  // Hàm rút gọn địa chỉ để hiển thị cho đẹp (vd: 8xzt...j12k)
  String get _displayAddress {
    if (widget.walletAddress.length < 12) return widget.walletAddress;
    return "${widget.walletAddress.substring(0, 6)}...${widget.walletAddress.substring(widget.walletAddress.length - 6)}";
  }

  // Xử lý logic Copy
  void _copyToClipboard() {
    // Copy toàn bộ địa chỉ gốc vào bộ nhớ đệm
    Clipboard.setData(ClipboardData(text: widget.walletAddress));

    // Đổi icon thành dấu tích
    setState(() {
      _isCopied = true;
    });

    // Hiện thông báo nhỏ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép địa chỉ ví!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Sau 2 giây thì đổi lại icon copy cũ
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo Phantom
    final Color primaryColor = Colors.purple.shade700;

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
              // --- 1. HEADER ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông tin ví',
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

              // --- 2. LOGO PHANTOM ---
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Center(
                  // Nếu có ảnh asset thì thay bằng Image.asset(...)
                  child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 40,
                      color: primaryColor
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "Phantom Wallet",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 8),

              // --- 3. TRẠNG THÁI KẾT NỐI ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Đang kết nối",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 4. Ô HIỂN THỊ ĐỊA CHỈ (BẤM ĐỂ COPY) ---
              InkWell(
                onTap: _copyToClipboard,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.qr_code_2, size: 24, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Địa chỉ công khai (Public Key)",
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _displayAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Courier', // Font kiểu code cho dễ nhìn
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Nút copy đổi trạng thái
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          _isCopied ? Icons.check_circle : Icons.copy_rounded,
                          size: 20,
                          color: _isCopied ? Colors.green : Colors.grey.shade400,
                        ),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- 5. CÁC THÔNG TIN PHỤ ---
              _buildInfoRow(Icons.security, "Bảo mật", "Chuẩn mã hóa X25519"),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.link, "Mạng lưới", "Solana Mainnet"),

              const SizedBox(height: 30),

              // --- 6. NÚT NGẮT KẾT NỐI ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Đóng dialog trước
                    Navigator.of(context).pop();
                    // Gọi hàm disconnect từ bên ngoài truyền vào
                    widget.onDisconnect();
                  },
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text("Ngắt kết nối"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50, // Nền đỏ nhạt
                    foregroundColor: Colors.red.shade700, // Chữ đỏ đậm
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.red.shade100)
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "Sâm Nghị Gia Blockchain Integration",
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget con dùng lại để hiển thị các dòng thông tin nhỏ
  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}