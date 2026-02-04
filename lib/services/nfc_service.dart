// lib/services/nfc_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:nftsam/api/api_caysam.dart';
import 'package:nftsam/models/vuontrong/caysam_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ndef/ndef.dart' as ndef;
// ✅ CHỈ IMPORT CÁC LỚP TỒN TẠI
import 'package:ndef_record/ndef_record.dart'
    show NdefMessage, NdefRecord, TypeNameFormat;
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart'; // Cho Ndef.from(tag)
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

// Imports khác của ứng dụng
import 'package:nftsam/api/api.dart'; // Đảm bảo import API của bạn
import 'package:nftsam/screens/plant_detail_screen.dart';


class NfcService {
  static bool _isProcessingTag = false;
  static bool _isNfcSessionRunning = false;


  static void _showError(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  static void _showLoadingDialog(BuildContext context, {required String message}) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(message),
              ]),
            ),
          );
        },
      );
    }
  }


  // static String _parseTextPayload(Uint8List recordPayload) {
  //   try {
  //     List<int> payload = recordPayload.toList();
  //     int statusByte = payload.removeAt(0);
  //     int langCodeLength = (statusByte & 0x3F);
  //     List<int> textPayload = payload.sublist(langCodeLength);
  //     return utf8.decode(textPayload);
  //   } catch (e) {
  //     print('Lỗi parse NDEF Text payload: $e');
  //     throw Exception('Không thể giải mã NDEF Text record');
  //   }
  // }

  // static String _parseUriPayload(Uint8List payload) {
  //   if (payload.isEmpty) return "";
  //   final prefixCode = payload[0];
  //   final restOfPayload = payload.sublist(1);
  //   final payloadString = utf8.decode(restOfPayload);
  //   switch (prefixCode) {
  //     case 0x00: return payloadString;
  //     case 0x01: return "http://www." + payloadString;
  //     case 0x02: return "https://www." + payloadString;
  //     case 0x03: return "http://" + payloadString;
  //     case 0x04: return "https://" + payloadString;
  //     case 0x05: return "tel:" + payloadString;
  //     case 0x06: return "mailto:" + payloadString;
  //     default: return payloadString;
  //   }
  // }


  // (Giữ nguyên: _handleCaySamId)
  // Thêm tham số hardwareId
  static Future<void> _handleCaySamId(String caySamId, BuildContext context) async {
    if (_isProcessingTag) return;
    _isProcessingTag = true;

    try {


      // 1. Tắt Dialog Quét (Android)
      if (Platform.isAndroid) {
        if (Navigator.canPop(context)) Navigator.of(context).pop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (context.mounted) {
        _showLoadingDialog(context, message: 'Đang xác thực thẻ...');
      }

      // --- [VÍ DỤ CHECK ID THẺ TRÊN SERVER] ---
      // final result = await API().verifyTag(caySamId, hardwareId);
      // if (!result.isValid) throw "Thẻ giả mạo!";

      final CaySamModel? plant = await API().getCaySamById(caySamId);

      if (context.mounted) {
        Navigator.of(context).pop(); // Tắt Loading

        if (plant != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              // Truyền tiếp hardwareId vào màn hình chi tiết nếu cần hiển thị
              builder: (context) => PlantDetailScreen(plant: plant, onBack: () => Navigator.pop(context)),
            ),
          );
        } else {
          _showError(context, 'Không tìm thấy thông tin cây sâm');
        }
      }
    } catch (e) {
      print('Lỗi tải dữ liệu: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Tắt Loading
        _showError(context, 'Lỗi: ${e.toString()}');
      }
    } finally {
      _isProcessingTag = false;
    }
  }
  static Future<bool> checkNfcSupport() async {
    return await NfcManager.instance.isAvailable();
  }
  static Future<void> processDeepLinkUri(Uri uri, BuildContext context) async {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) {
      if (context.mounted) {
        _showError(context, "Thiết bị của bạn không hỗ trợ NFC!");
      }
      return; // Dừng ngay lập tức
    }
    // 1. Kiểm tra tính hợp lệ của Link (Deep Link)
    if (uri.host == 'nft.samnghigia.com' &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'caysam') {

      final String caySamId = uri.pathSegments[1];
      BuildContext? dialogContext;
      await NfcManager.instance.stopSession().catchError((_) {});

      // 3. Hiển thị Dialog chờ (Chỉ dành cho Android vì iOS có UI riêng)
      if (Platform.isAndroid) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            dialogContext = ctx;
            return WillPopScope(
              onWillPop: () async => false, // Chặn nút Back
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.nfc_outlined, size: 60, color: Colors.blue),
                    SizedBox(height: 20),
                    Text("Đang tải dữ liệu...",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      "Vui lòng chạm lại thẻ để xác thực...",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    LinearProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        );
      }

      try {
        // 4. Delay nhỏ để phần cứng iOS reset sau khi stop session cũ
        if (Platform.isIOS) {
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Android đôi khi cần delay lâu hơn nếu vừa mở từ background
          await Future.delayed(const Duration(seconds: 1));
        }

        // 5. Bắt đầu quét thẻ bằng FlutterNfcKit
        // Lưu ý: timeout 10s là hợp lý
        var tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 10),
          iosAlertMessage: "Vui lòng chạm lại thẻ để xác thực...",
          readIso14443A: true,
          readIso15693: true,
        );

        String realHardwareId = tag.id;

        // Debug
        // print("UID DeepLink: $realHardwareId");

        // 6. Xử lý logic API
        if (realHardwareId.isNotEmpty) {
          final checkuid = await API().CheckNFCCaySam(serialNumber: realHardwareId);

          if (checkuid?.message == "Thẻ NFC đã tồn tại!") {
            // >> THÀNH CÔNG:

            // Báo cho iOS UI biết là xong (Hiện tích xanh)
            await FlutterNfcKit.finish(iosAlertMessage: "Xác thực thành công!");

            // Đóng Dialog Android
            if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
              Navigator.pop(dialogContext!);
            }

            // Chuyển hướng xử lý ID cây sâm
            await _handleCaySamId(caySamId, context);

          } else {
            // >> THẤT BẠI (Sai thẻ hoặc lỗi Server):

            // Báo lỗi trên iOS UI
            await FlutterNfcKit.finish(iosErrorMessage: "Thẻ không khớp!");

            // Đóng Dialog Android
            if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
              Navigator.pop(dialogContext!);
            }

            if (context.mounted) {
              _showError(context, "Xác thực thẻ thất bại: ${checkuid?.message ?? 'Lỗi không xác định'}");
            }
          }
        } else {
          // Trường hợp không lấy được ID
          await FlutterNfcKit.finish(iosErrorMessage: "Không đọc được ID thẻ");
          if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
            Navigator.pop(dialogContext!);
          }
        }

      } catch (e) {
        print("Lỗi quét NFC DeepLink: $e");

        // Đảm bảo đóng session nếu có lỗi (Exception, Timeout...)
        try {
          await FlutterNfcKit.finish(iosErrorMessage: "Lỗi/Hủy quét");
        } catch (_) {}

        // Đóng Dialog Android
        if (Platform.isAndroid && dialogContext != null && Navigator.canPop(dialogContext!)) {
          Navigator.pop(dialogContext!);
        }
      }
    }
  }

  static Future<void> _handleTagDiscovered(NfcTag tag, BuildContext context) async {
    try {

      final String hardwareId = _extractTagId(tag);
      if (hardwareId == "UNKNOWN_ID" || hardwareId.isEmpty) {
        if (context.mounted) _showError(context, "ID:$hardwareId Không đọc được ID vật lý của thẻ!");
        return;
      }
      final Ndef? ndef = Ndef.from(tag);
      if (ndef == null) {
        print("⚠️ Thẻ không hỗ trợ định dạng NDEF");
        return;
      }

      NdefMessage? message = ndef.cachedMessage;
      if (message == null) {
        try {
          message = await ndef.read();
        } catch (e) {
          // Lỗi đọc thẻ trực tiếp
        }
      }
      if (message == null || message.records.isEmpty) {
        if (context.mounted) _showError(context, 'Thẻ trắng hoặc không đọc được dữ liệu.');
        return;
      }
      String? foundCaySamId;
      for (var record in message.records) {
        if (record.typeNameFormat == TypeNameFormat.wellKnown &&
            record.type.length == 1 &&
            record.type.first == 0x55) {
          try {
            final uriString = _parseUriPayload(record.payload);
            final Uri uri = Uri.parse(uriString);
            if (uri.host.contains('samnghigia.com') &&
                uri.pathSegments.length >= 2 &&
                uri.pathSegments[0] == 'caysam') {
              foundCaySamId = uri.pathSegments[1];
              break;
            }
          } catch (e) {
            print("⚠️ Lỗi parse record này: $e");
          }
        }
      }
      if (foundCaySamId != null) {
        await _verifyAndNavigate(foundCaySamId, hardwareId, context);
      } else {
        if (context.mounted) _showError(context, "Thẻ này không chứa thông tin Sâm hợp lệ.");
      }
    } catch (e) {
      print('❌ Lỗi xử lý thẻ: $e');
      if (context.mounted) {
        _showError(context, 'Lỗi đọc thẻ: ${e.toString()}');
      }
    }
  }

  static Future<void> _verifyAndNavigate(String caySamId, String hardwareId, BuildContext context) async {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final checkResult = await API().CheckNFCCaySam(serialNumber: hardwareId);
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (!context.mounted) return;
      if (checkResult?.message == "Thẻ NFC đã tồn tại!") {
        await _handleCaySamId(caySamId, context);
      } else {
        _showError(context, "Thẻ chưa được kích hoạt hoặc không hợp lệ!");
      }
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (context.mounted) _showError(context, "Lỗi kết nối Server: $e");
    }
  }

  // Nhớ import ở đầu file: import 'dart:convert';

  static String _extractTagId(NfcTag tag) {
    List<int> idBytes = [];

    try {
      final dynamic rawData = tag.data;

      // 1. Nếu là MAP (Android)
      if (rawData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);
        if (Platform.isAndroid) {
          if (data.containsKey('nfcA')) {
            idBytes = List<int>.from(data['nfcA']['identifier'] ?? []);
          } else if (data.containsKey('mifareClassic')) {
            idBytes = List<int>.from(data['mifareClassic']['identifier'] ?? []);
          }
        } else if (Platform.isIOS) {
          // iOS cũ trả về Map
          if (data.containsKey('mifare')) {
            final m = data['mifare'];
            if(m is Map) idBytes = List<int>.from(m['identifier'] ?? []);
          }
        }
      }
      // 2. Nếu là OBJECT (TagPigeon - iOS Mới)
      else {
        if (idBytes.isEmpty) {
          try {
            final dynamic obj = rawData.miFare; // <--- QUAN TRỌNG
            if (obj != null) {
              final dynamic id = obj.identifier;
              if (id != null) {
                idBytes = List<int>.from(id);
              }
            } else {
              print("      -> .miFare trả về null");
            }
          } catch (e) {
            print("      ❌ Lỗi gọi .miFare: $e");
          }
        }

        // --- Các dòng dưới giữ nguyên nhưng bọc try-catch kỹ hơn ---

        // Thử ISO15693
        if (idBytes.isEmpty) {
          try {
            final dynamic obj = rawData.iso15693;
            if (obj != null) {
              idBytes = List<int>.from(obj.identifier);
            }
          } catch (_) {}
        }

        // Thử FeliCa
        if (idBytes.isEmpty) {
          try {
            final dynamic obj = rawData.feliCa; // Chữ C viết hoa
            if (obj != null) {
              idBytes = List<int>.from(obj.currentIDm);
            }
          } catch (_) {}
        }

        // Thử ISO7816
        if (idBytes.isEmpty) {
          try {
            final dynamic obj = rawData.iso7816;
            if (obj != null) {
              idBytes = List<int>.from(obj.identifier);
            }
          } catch (_) {}
        }
      }

    } catch (e) {
      print("🔴 Lỗi tổng quát: $e");
      return "";
    }

    if (idBytes.isEmpty) {
      print("   ⚠️ Vẫn không tìm thấy ID. Có thể thẻ này thuộc loại khác (IsoDep/NfcA?)");
      return "";
    }
    String finalUid = idBytes.map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase()).join();
    return finalUid;
  }
  static String _parseUriPayloadFromBytes(List<int> payload) {
    if (payload.isEmpty) return "";
    // Byte đầu tiên là mã tiền tố (Prefix Code)
    int prefixCode = payload[0];
    String prefix = _getNdefUriPrefix(prefixCode);
    // Các byte còn lại là nội dung
    String body = utf8.decode(payload.sublist(1));
    return prefix + body;
  }

  static String _parseTextPayloadFromBytes(List<int> payload) {
    if (payload.isEmpty) return "";
    // Byte đầu tiên chứa thông tin mã hóa và độ dài mã ngôn ngữ
    int statusByte = payload[0];
    bool isUtf16 = (statusByte & 0x80) != 0;
    int languageCodeLength = statusByte & 0x3F;

    // Bỏ qua byte trạng thái và mã ngôn ngữ để lấy nội dung thực
    if (payload.length > 1 + languageCodeLength) {
      var contentBytes = payload.sublist(1 + languageCodeLength);
      return isUtf16 ? utf8.decode(contentBytes) : utf8.decode(contentBytes);
      // Lưu ý: Dart hỗ trợ utf8 tốt, utf16 ít dùng trong NDEF web nhưng nếu cần có thể convert
    }
    return "";
  }

// Bảng mã tiền tố URI chuẩn NDEF
  static String _getNdefUriPrefix(int code) {
    const prefixes = [
      '', 'http://www.', 'https://www.', 'http://', 'https://', 'tel:', 'mailto:',
      'ftp://anonymous:anonymous@', 'ftp://ftp.', 'ftps://', 'sftp://', 'smb://',
      'nfs://', 'ftp://', 'dav://', 'news:', 'telnet://', 'imap:', 'rtsp://', 'urn:',
      'pop:', 'sip:', 'sips:', 'tftp:', 'btspp://', 'btl2cap://', 'btgoep://',
      'tcpobex://', 'irdaobex://', 'file://', 'urn:epc:id:', 'urn:epc:tag:',
      'urn:epc:pat:', 'urn:epc:raw:', 'urn:epc:', 'urn:nfc:'
    ];
    if (code >= 0 && code < prefixes.length) {
      return prefixes[code];
    }
    return "";
  }
// ============================================================
// CÁC HÀM HELPER QUAN TRỌNG (PHẢI CÓ ĐỂ CHẠY TRÊN IOS)
// ============================================================

  /// Giải mã URI Record theo chuẩn NFC Forum
  static String _parseUriPayload(Uint8List payload) {
    if (payload.isEmpty) return "";

    // Byte đầu tiên là mã định danh giao thức (Prefix)
    final int prefixCode = payload[0];

    // Phần còn lại là nội dung link
    final String body = utf8.decode(payload.sublist(1));

    String prefix = "";
    switch (prefixCode) {
      case 0x01: prefix = "http://www."; break;
      case 0x02: prefix = "https://www."; break;
      case 0x03: prefix = "http://"; break;
      case 0x04: prefix = "https://"; break; // Đây là cái bạn dùng nhiều nhất
      case 0x00: prefix = ""; break;
      default: prefix = ""; // Các prefix ít dùng khác
    }

    return prefix + body;
  }

  /// Giải mã Text Record theo chuẩn NFC Forum
  static String _parseTextPayload(Uint8List payload) {
    if (payload.isEmpty) return "";

    // Byte đầu tiên là Status Byte
    final int statusByte = payload[0];

    // Bit 7 kiểm tra encoding (0 = UTF-8, 1 = UTF-16) - Thường là UTF-8
    // final bool isUtf16 = (statusByte & 0x80) != 0;

    // Bit 0-5 là độ dài mã ngôn ngữ (ví dụ 'en' là 2)
    final int languageCodeLength = statusByte & 0x3F;

    // Nội dung thực tế bắt đầu sau (1 byte status + độ dài mã ngôn ngữ)
    final int textStartIndex = 1 + languageCodeLength;

    return utf8.decode(payload.sublist(textStartIndex));
  }


  static Future<void> startNfcSession(BuildContext context) async {
    // 1. CHỐNG SPAM CLICK
    if (_isNfcSessionRunning) {
      print("⚠️ Session đang chạy, đang thử reset...");
      await NfcManager.instance.stopSession().catchError((_) {});
      _isNfcSessionRunning = false;
    }

    _isNfcSessionRunning = true; // Khóa
    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        // Tự ném lỗi để nhảy xuống Catch xử lý chung
        throw PlatformException(code: "not_supported", message: "Thiết bị không hỗ trợ NFC");
      }

      // 3. CHIẾN THUẬT "DỌN DẸP TRƯỚC"
      await NfcManager.instance.stopSession().catchError((_) {});
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // 4. BẮT ĐẦU SESSION MỚI
      await NfcManager.instance.startSession(
        alertMessageIos: "Vui lòng đưa thẻ lại gần điện thoại...",
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
        onSessionErrorIos: (error) async {
          print("NFC Error Callback: $error");
          _isNfcSessionRunning = false;
        },
        onDiscovered: (NfcTag tag) async {
          bool isScanSuccess = false;
          try {
            await _handleTagDiscovered(tag, context);
            isScanSuccess = true;
          } catch (e) {
            print("Lỗi xử lý thẻ: $e");
            // Có thể show lỗi nhỏ nếu muốn
          } finally {
            // 5. KẾT THÚC SESSION
            if (Platform.isIOS) {
              await NfcManager.instance.stopSession(
                alertMessageIos: isScanSuccess ? "Thành công!" : "Lỗi đọc thẻ",
                errorMessageIos: isScanSuccess ? null : "Thử lại",
              ).catchError((_){});
            } else {
              await NfcManager.instance.stopSession().catchError((_){});
            }
            _isNfcSessionRunning = false;
          }
        },
      );

    } catch (e) {
      // 6. XỬ LÝ LỖI CHUNG (Bao gồm cả lỗi không hỗ trợ)
      print("❌ Lỗi NFC Session: $e");

      // Đảm bảo mở khóa session
      _isNfcSessionRunning = false;
      await NfcManager.instance.stopSession().catchError((_) {});

      if (context.mounted) {
        // Lọc bớt các lỗi do người dùng bấm hủy
        String errorMsg = e.toString();
        if (!errorMsg.contains("Session invalidated by user") &&
            !errorMsg.contains("System is busy")) { // iOS hay bị System busy nếu bấm nhanh

          // Hiển thị thông báo lỗi rõ ràng
          if (errorMsg.contains("not_supported")) {
            _showError(context, "Thiết bị này không hỗ trợ NFC!");
          } else {
            _showError(context, "Lỗi: Không thể bật NFC.");
          }
        }
      }
    }
  }

  static void stopNfcSession() {
    NfcManager.instance.stopSession().then((_) {
      _isNfcSessionRunning = false;
      print("Đã dừng NFC session.");
    }).catchError((e) {
      if (e is PlatformException && e.code != 'not_supported' && e.code != 'session_stopped') {
        print("Lỗi khi dừng NFC session: $e");
      }
    });
  }
}