import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:bs58/bs58.dart';
import 'package:pinenacl/x25519.dart';
import 'package:pinenacl/tweetnacl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/app_config.dart';

// Đảm bảo import đúng đường dẫn AuthProvider của bạn
import '../providers/auth_provider.dart';

class PhantomService {
  static final PhantomService _instance = PhantomService._internal();
  factory PhantomService() => _instance;
  PhantomService._internal();

  // StreamController để UI lắng nghe thay đổi ví
  final _controller = StreamController<String?>.broadcast();
  Stream<String?> get walletStream => _controller.stream;

  PrivateKey? _dappPrivateKey;
  PublicKey? _dappPublicKey;
  String? _currentWalletAddress;

  final String _appScheme =
      "samapp"; // Đảm bảo trùng với AndroidManifest/Info.plist
  final String _appHost = "onConnect";
  final _appLinks = AppLinks();
  bool _isListening = false;

  // --- 1. KHỞI TẠO & CHECK SESSION ---
  Future<void> initialize(AuthProvider authProvider) async {
    await _initKeys();
    _startDeepLinkListener();
    await _checkSavedConnection(authProvider);
  }

  Future<void> _checkSavedConnection(AuthProvider authProvider) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('saved_wallet_address');

    // Logic kiểm tra phiên làm việc (Ví dụ: Timeout sau 1 giờ)
    final int? lastLogin = prefs.getInt('last_login_timestamp');
    final int currentTime = DateTime.now().millisecondsSinceEpoch;
    // Ví dụ: 1 giờ = 60 * 60 * 1000 ms
    final bool isSessionExpired =
        lastLogin != null && (currentTime - lastLogin > 3600000);

    if (savedAddress != null && !isSessionExpired) {
      AppConfig.printEx(
          "♻️ [PhantomService] Phiên cũ hợp lệ, khôi phục ngay: $savedAddress");
      _currentWalletAddress = savedAddress;
      _controller.add(savedAddress);
    } else if (savedAddress != null && isSessionExpired) {
      AppConfig.printEx(
          "⚠️ [PhantomService] Phiên cũ hết hạn, cần Verify lại.");
      // Tùy chọn: Có thể gọi verifyWalletConnection() ở đây nếu muốn check ngay lập tức
    }
  }

  Future<void> _initKeys() async {
    if (_dappPrivateKey != null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? storedKey = prefs.getString('dapp_private_key');

    if (storedKey != null && storedKey.isNotEmpty) {
      try {
        _dappPrivateKey = PrivateKey(base58.decode(storedKey));
        _dappPublicKey = _dappPrivateKey!.publicKey;

        // // IN LOG ĐỂ KIỂM TRA: Key load lên là gì?
        // final keyStr = base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
        // AppConfig.printEx("🔑 [LOAD OLD KEY] Public Key: $keyStr");
      } catch (e) {
        AppConfig.printEx("❌ Lỗi load key cũ, buộc phải tạo mới: $e");
        await _generateAndSaveNewKey(prefs);
      }
    } else {
      AppConfig.printEx("⚠️ Không tìm thấy Key cũ, tạo Key mới...");
      await _generateAndSaveNewKey(prefs);
    }
  }

  Future<void> _generateAndSaveNewKey(SharedPreferences prefs) async {
    _dappPrivateKey = PrivateKey.generate();
    _dappPublicKey = _dappPrivateKey!.publicKey;

    final keyStr =
        base58.encode(Uint8List.fromList(_dappPrivateKey!.asTypedList));
    // Lưu ngay lập tức
    await prefs.setString('dapp_private_key', keyStr);

    final pubKeyStr =
        base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
    //AppConfig.printEx("🆕 [GENERATED NEW KEY] Public Key: $pubKeyStr");
  }

  void _startDeepLinkListener() {
    if (_isListening) return;
    _isListening = true;
    _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) _processUri(uri);
    });
  }

  void _processUri(Uri uri) async {
    // 1. Chỉ xử lý nếu đúng Scheme của App (samapp://)
    if (uri.scheme != _appScheme) return;

    // 2. Xác định loại phản hồi: Connect hay Verify
    final isConnect = uri.host.toLowerCase() == _appHost.toLowerCase();
    final isVerify = uri.host == 'verify_result';

    if (!isConnect && !isVerify) return;

    // 3. XỬ LÝ LỖI TỪ PHANTOM TRẢ VỀ
    if (uri.queryParameters.containsKey('errorCode')) {
      final code = uri.queryParameters['errorCode'];
      final msg = uri.queryParameters['errorMessage'];
      AppConfig.printEx("❌ Phantom báo lỗi: $code - $msg");

      // QUAN TRỌNG: Lỗi -32603 nghĩa là Phantom không giải mã được (Sai Key)
      // Gặp lỗi này phải Logout ngay để user kết nối lại từ đầu
      if (code == '-32603') {
        AppConfig.printEx(
            "⚠️ Lỗi lệch Key bảo mật. Đang tự động đăng xuất để làm sạch dữ liệu...");
        await disconnectWallet();
        // Tùy chọn: Có thể hiện thông báo cho user biết là cần kết nối lại
      }
      return; // Dừng lại, không xử lý tiếp
    }

    try {
      // 4. LƯU KEY MÃ HÓA CỦA PHANTOM (Nếu có)
      // Phantom gửi key này mỗi khi tương tác, cần lưu lại để dùng cho lần sau
      if (uri.queryParameters.containsKey('phantom_encryption_public_key')) {
        final String phantomKeyStr =
            uri.queryParameters['phantom_encryption_public_key']!;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phantom_encryption_key', phantomKeyStr);
        AppConfig.printEx("🔑 Đã cập nhật Phantom Encryption Key mới.");
      }

      // Đảm bảo Private Key của mình đã sẵn sàng
      if (_dappPrivateKey == null) await _initKeys();

      // 5. GIẢI MÃ DỮ LIỆU (DECRYPT)
      final Uint8List phantomPublicKey =
          base58.decode(uri.queryParameters['phantom_encryption_public_key']!);
      final Uint8List nonce = base58.decode(uri.queryParameters['nonce']!);
      final Uint8List encryptedData =
          base58.decode(uri.queryParameters['data']!);

      final Box box = Box(
        myPrivateKey: _dappPrivateKey!,
        theirPublicKey: PublicKey(phantomPublicKey),
      );

      final Uint8List decryptedResult = box.decrypt(
        ByteList(encryptedData),
        nonce: nonce,
      );

      // 6. XỬ LÝ KẾT QUẢ SAU KHI GIẢI MÃ THÀNH CÔNG

      if (isConnect) {
        // --- TRƯỜNG HỢP: KẾT NỐI MỚI ---
        final String jsonString = utf8.decode(decryptedResult);
        final Map<String, dynamic> payload = json.decode(jsonString);

        final String userWalletAddress = payload['public_key'];
        final String session = payload['session'];

        AppConfig.printEx("✅ Kết nối thành công tới ví: $userWalletAddress");

        // Lưu toàn bộ thông tin quan trọng vào bộ nhớ
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_wallet_address', userWalletAddress);
        await prefs.setString('saved_session', session);
        await prefs.setInt(
            'last_login_timestamp', DateTime.now().millisecondsSinceEpoch);

        // Cập nhật UI
        _currentWalletAddress = userWalletAddress;
        _controller.add(userWalletAddress);
      } else if (isVerify) {
        // --- TRƯỜNG HỢP: VERIFY THÀNH CÔNG ---
        AppConfig.printEx(
            "✅ Verify thành công: Ví vẫn hoạt động tốt & Key khớp.");

        // Gia hạn phiên làm việc (Reset thời gian timeout)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(
            'last_login_timestamp', DateTime.now().millisecondsSinceEpoch);

        // Nếu trước đó UI chưa hiện ví, thì giờ hiện lên (đề phòng)
        if (_currentWalletAddress == null) {
          final savedAddr = prefs.getString('saved_wallet_address');
          if (savedAddr != null) {
            _currentWalletAddress = savedAddr;
            _controller.add(savedAddr);
          }
        }
      }
    } catch (e) {
      AppConfig.printEx("❌ Lỗi xử lý phản hồi (Exception): $e");
      // Nếu giải mã lỗi, cũng nên xem xét disconnect để an toàn
    }
  }

  // --- 3. CÁC HÀM GỌI ĐI ---

  Future<void> connectWallet() async {
    await _initKeys();
    final String dappPublicKeyBase58 =
        base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
    final String redirectLink = "$_appScheme://$_appHost";

    final String phantomUrl = 'https://phantom.app/ul/v1/connect'
        '?app_url=https://samngoclinh.com'
        '&dapp_encryption_public_key=$dappPublicKeyBase58'
        '&redirect_link=${Uri.encodeComponent(redirectLink)}'
        '&cluster=mainnet-beta';

    final Uri url = Uri.parse(phantomUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Chưa cài Phantom Wallet");
    }
  }

  Future<void> verifyWalletConnection() async {
    AppConfig.printEx("🔄 Đang kiểm tra trạng thái ví (Verify)...");
    final prefs = await SharedPreferences.getInstance();

    // SỬA: Lấy Key mã hóa chứ không lấy địa chỉ ví
    final String? storedPhantomEncKey =
        prefs.getString('phantom_encryption_key');

    if (_dappPrivateKey == null || storedPhantomEncKey == null) {
      AppConfig.printEx("⚠️ Mất key phiên làm việc, chuyển sang kết nối mới.");
      await connectWallet();
      return;
    }

    final String message =
        "Verify Login: ${DateTime.now().millisecondsSinceEpoch}";

    // Mã hóa bằng storedPhantomEncKey (Key này Phantom mới hiểu)
    final payloadData =
        _createEncryptedPayload(message, base58.decode(storedPhantomEncKey));

    final String dappPublicKeyStr =
        base58.encode(Uint8List.fromList(_dappPublicKey!.asTypedList));
    final String redirectLink = "$_appScheme://verify_result";

    final String phantomUrl = 'https://phantom.app/ul/v1/signMessage'
        '?dapp_encryption_public_key=$dappPublicKeyStr'
        '&nonce=${payloadData['nonce']}'
        '&payload=${payloadData['payload']}'
        '&redirect_link=${Uri.encodeComponent(redirectLink)}';

    final Uri url = Uri.parse(phantomUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw Exception("Chưa cài Phantom Wallet");
    }
  }

  Map<String, String> _createEncryptedPayload(
      String message, Uint8List phantomPublicKeyBytes) {
    // 1. Kiểm tra Private Key
    if (_dappPrivateKey == null) throw Exception("Chưa có Dapp Private Key");

    final Box box = Box(
      myPrivateKey: _dappPrivateKey!,
      theirPublicKey: PublicKey(phantomPublicKeyBytes),
    );

    // 2. Tạo Nonce ngẫu nhiên (24 bytes)
    final Uint8List nonce = TweetNaCl.randombytes(24);

    // 3. CHUẨN BỊ PAYLOAD (Phải đúng thứ tự này)

    // Bước A: Encode nội dung tin nhắn sang Base58
    final String encodedMessage =
        base58.encode(Uint8List.fromList(utf8.encode(message)));

    // Bước B: Bọc vào JSON object
    final String jsonString = json.encode({
      "message": encodedMessage // Key bắt buộc phải là "message"
    });

    // Bước C: Chuyển JSON thành bytes để mã hóa
    final Uint8List payloadBytes = Uint8List.fromList(utf8.encode(jsonString));

    // 4. Mã hóa
    final EncryptedMessage encryptedMessage =
        box.encrypt(payloadBytes, nonce: nonce);
    final Uint8List encrypted = Uint8List.fromList(encryptedMessage);

    return {
      'nonce': base58.encode(nonce),
      'payload': base58.encode(encrypted),
    };
  }

  Future<void> disconnectWallet() async {
    AppConfig.printEx("👋 Đang ngắt kết nối ví...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_wallet_address');
    await prefs.remove('saved_session');
    await prefs.remove('phantom_encryption_key'); // Xóa luôn key mã hóa
    await prefs.remove('last_login_timestamp');
    _currentWalletAddress = null;
    _controller.add(null);
  }

  String? get currentAddress => _currentWalletAddress;
}
