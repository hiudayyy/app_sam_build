import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:nftsam/api/api.dart';
import 'package:nftsam/api/api_caysam.dart';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:ndef_record/ndef_record.dart';
import 'package:ndef/ndef.dart' as ndef;
import 'package:nftsam/models/message_enum.dart';
import '../models/vuontrong/caysam_model.dart';

enum NfcStatus { scanning, success, error }

class NfcWriterModal extends StatefulWidget {
  final CaySamModel plant;
  const NfcWriterModal({super.key, required this.plant});

  @override
  State<NfcWriterModal> createState() => _NfcWriterModalState();
}

class _NfcWriterModalState extends State<NfcWriterModal> {
  NfcStatus _status = NfcStatus.scanning; // Bắt đầu ở trạng thái quét
  String _feedbackMessage = 'Đang chờ thẻ NFC...\nVui lòng đưa thẻ lại gần điện thoại.';

  @override
  void initState() {
    super.initState();
    _startNfcWriting();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<void> _startNfcWriting() async {
    // 1. Kiểm tra hỗ trợ NFC
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    if (availability != NfcAvailability.enabled) {
      _updateStatus(NfcStatus.error, 'NFC không được bật hoặc không được hỗ trợ.','');
      return;
    }

    try {
      NfcManager.instance.startSession(
        // iOS: Thông báo này quan trọng để người dùng biết phải GIỮ YÊN thẻ
        alertMessageIos: "Đang xác thực thẻ...\nVui lòng GIỮ NGUYÊN điện thoại.",
        onDiscovered: (NfcTag tag) async {
          try {
            // --- BƯỚC 1: Kiểm tra khả năng ghi NDEF ---
            var ndef = Ndef.from(tag);
            if (ndef == null || !ndef.isWritable) {
              throw Exception('Thẻ đã được khi hoặc bị khóa!');
            }

            // --- BƯỚC 2: Lấy ID phần cứng (UID) của thẻ ---
            // Hàm _getTagId được viết ở dưới cùng
            String uid = _getTagId(tag.data);
            //
            // print("UID Thẻ: $uid");
            // final checkuid = await API().CheckNFCCaySam(serialNumber: uid);
            // if(checkuid?.messCode != MessCode.IsOK ){
            //   throw Exception('${checkuid?.message}');
            // }
            // if (uid.isEmpty) {
            //   throw Exception('Không đọc được ID thẻ.');
            // }

            // --- BƯỚC 3: GỌI API KIỂM TRA (GIỮ KẾT NỐI SESSION) ---
            // Tại đây bạn gọi API của bạn để check xem thẻ có hợp lệ không
            // Session vẫn đang mở, người dùng vẫn phải giữ thẻ

            // Ví dụ:
            // bool isGenuine = await API().checkCardGenuine(uid);
            // if (!isGenuine) throw Exception("Thẻ này không có trong hệ thống!");

            // (Giả lập delay API 1 giây)

            // --- BƯỚC 4: CHUẨN BỊ DỮ LIỆU ĐỂ GHI ---
            final String myLink = 'https://nft.samnghigia.com/caysam/${widget.plant.caySamId}';

            // Tạo bản ghi URI (Nên để đầu tiên cho iOS Background Scan)
            final urirecord = _createNdefUriRecord(myLink);

            // Tạo thêm bản ghi Text/Android Package nếu cần (như code cũ của bạn)
            // ...

            final message = NdefMessage(records: [urirecord]);

            // --- BƯỚC 5: GHI DỮ LIỆU (WRITE) ---
            // Lúc này mới thực sự ghi vào thẻ
            await ndef.write(message: message);

            // ⚠️ Cẩn thận: Chỉ bật dòng này khi chắc chắn muốn khóa thẻ vĩnh viễn
            // await ndef.writeLock();

            // --- BƯỚC 6: KẾT THÚC THÀNH CÔNG ---
            // Gọi hàm này để báo iOS hiện dấu Tick xanh và đóng session
            _updateStatus(NfcStatus.success, 'Xác thực & Ghi thành công!',uid);

          } catch (e) {
            // Nếu lỗi ở bất kỳ bước nào (API lỗi, rút thẻ sớm...), báo lỗi ngay
            // _updateStatus(NfcStatus.error, 'Lỗi: ${e.toString()}','');
            _updateStatus(NfcStatus.error, 'Có lỗi xảy ra vui lòng thử lại...','');
          }
        },
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      );
    } catch (e) {
      _updateStatus(NfcStatus.error, 'Lỗi khi bắt đầu phiên NFC: $e','');
    }
  }
  // Future<void> _startNfcWriting() async {
  //   // 1. Kiểm tra hỗ trợ NFC
  //   var availability = await FlutterNfcKit.nfcAvailability;
  //   if (availability != NFCAvailability.available) {
  //     _updateStatus(NfcStatus.error, 'NFC không khả dụng (đang tắt hoặc thiết bị không hỗ trợ).');
  //     return;
  //   }
  //
  //   try {
  //     // --- BƯỚC 2: BẮT ĐẦU QUÉT (POLLING) ---
  //     // Khác với nfc_manager, hàm này là Future, nó sẽ "treo" ở đây chờ người dùng chạm thẻ
  //     NFCTag tag = await FlutterNfcKit.poll(
  //       timeout: const Duration(seconds: 20), // Tự ngắt sau 20s
  //       iosAlertMessage: "Đang xác thực thẻ...\nVui lòng GIỮ NGUYÊN điện thoại.",
  //       // Chỉ đọc các loại thẻ phổ biến (tương đương pollOptions cũ)
  //       readIso14443A: true,
  //       readIso14443B: true,
  //       readIso15693: true,
  //       readIso18092: false,
  //     );
  //
  //     try {
  //       // --- BƯỚC 2 (Phụ): Lấy ID thẻ ---
  //       // flutter_nfc_kit trả về ID rất tiện, không cần parse phức tạp như nfc_manager
  //       String uid = tag.id.toUpperCase();
  //       print("UID Thẻ (Kit): $uid");
  //
  //       if (uid.isEmpty) {
  //         throw Exception('Không đọc được ID thẻ.');
  //       }
  //
  //       // --- BƯỚC 3: GỌI API KIỂM TRA ---
  //       // Logic giống hệt hàm cũ
  //       await Future.delayed(const Duration(seconds: 1)); // Giả lập check server
  //
  //       // Ví dụ check:
  //       // if (!checkGenuine(uid)) throw Exception("Thẻ giả mạo!");
  //
  //       // --- BƯỚC 4: CHUẨN BỊ DỮ LIỆU ---
  //       final String myLink = 'https://nft.samnghigia.com/caysam/${widget.plant.caySamId}';
  //
  //       // Tạo bản ghi URI bằng thư viện 'ndef' đi kèm
  //       final uriRecord = ndef.UriRecord.fromString(myLink);
  //
  //       // (Tùy chọn) Tạo AAR cho Android giống nfc_manager
  //       // final androidRecord = ndef.MimeRecord(
  //       //   recordType: "android.com:pkg",
  //       //   payload: utf8.encode("com.your.package")
  //       // );
  //
  //       // --- BƯỚC 5: GHI DỮ LIỆU ---
  //       // Kiểm tra xem thẻ có hỗ trợ NDEF không trước khi ghi
  //       if (tag.ndefAvailable == true) {
  //         // Ghi đè list các record vào thẻ
  //         await FlutterNfcKit.writeNDEFRecords([uriRecord]);
  // await FlutterNfcKit.makeNDEFReadOnly();
  //       } else {
  //         // Nếu thẻ chưa format NDEF, thư viện này đôi khi cần xử lý riêng
  //         // hoặc thông báo thẻ không hỗ trợ.
  //         throw Exception("Thẻ không hỗ trợ định dạng NDEF để ghi dữ liệu.");
  //       }
  //
  //       // --- BƯỚC 6: KẾT THÚC THÀNH CÔNG ---
  //       // Quan trọng trên iOS: Đóng popup và hiện dấu Tick
  //       await FlutterNfcKit.finish(iosAlertMessage: "Xác thực & Ghi thành công!");
  //       _updateStatus(NfcStatus.success, 'Đã ghi dữ liệu cây sâm thành công!');
  //
  //     } catch (e) {
  //       // Báo lỗi cho iOS UI biết
  //       await FlutterNfcKit.finish(iosErrorMessage: "Lỗi: ${e.toString()}");
  //       throw e; // Ném tiếp ra ngoài để catch tổng bắt
  //     }
  //
  //   } catch (e) {
  //     // Catch tổng: Xử lý timeout hoặc lỗi khởi động
  //     _updateStatus(NfcStatus.error, 'Lỗi xử lý thẻ: $e');
  //   }
  // }

  String _getTagId(dynamic rawData) {
    List<int>? identifier;

    try {
      // --- ƯU TIÊN 1: Xử lý nếu rawData là Object (TagPigeon) ---
      // Trường hợp này xảy ra nếu bạn truyền nhầm biến 'tag' thay vì 'tag.data'
      // hoặc do cấu trúc nội bộ của thư viện.
      try {
        // Cố gắng truy cập thuộc tính .id trực tiếp (như trong ảnh debug bạn gửi)
        identifier = rawData.id;
      } catch (e) {
        // Nếu không có thuộc tính .id, bỏ qua để chạy xuống dưới
      }

      // --- ƯU TIÊN 2: Xử lý nếu rawData là Map (Chuẩn nfc_manager) ---
      if (identifier == null && rawData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(rawData);

        // Danh sách các key chứa ID theo thứ tự ưu tiên
        const techKeys = ['nfcA', 'mifare', 'isodep', 'nfcB', 'nfcF', 'nfcV'];

        for (var key in techKeys) {
          if (data.containsKey(key)) {
            final techData = data[key];
            // Kiểm tra kỹ xem bên trong có phải Map và có chứa identifier không
            if (techData is Map && techData.containsKey('identifier')) {
              identifier = List<int>.from(techData['identifier']);
              break; // Tìm thấy thì dừng
            }
          }
        }

        // Fallback: Tìm key 'identifier' ngay tại root (nếu có)
        if (identifier == null && data.containsKey('identifier')) {
          identifier = List<int>.from(data['identifier']);
        }
      }
    } catch (e) {
      print("Lỗi khi parse ID thẻ: $e");
      return "";
    }

    // --- KẾT QUẢ: Chuyển đổi sang Hex String ---
    if (identifier != null && identifier.isNotEmpty) {
      return identifier
          .map((e) => e.toRadixString(16).padLeft(2, '0'))
          .join('')
          .toUpperCase();
    }

    return ""; // Không tìm thấy ID
  }

  // Hàm helper để cập nhật trạng thái và dừng phiên NFC
  Future<void> _updateStatus(NfcStatus status, String message,String uid) async {
    String? iosAlertMessage;
    String? iosErrorMessage;

    // if (status == NfcStatus.success) {
    //   iosAlertMessage = "Ghi thẻ thành công!";
    // } else if (status == NfcStatus.error) {
    //   iosErrorMessage = message;
    // }

    if (mounted) {
      setState(() {
        _status = status;
        _feedbackMessage = message;
      });
      if(status == NfcStatus.success){
        final data = await API().updateNFCCaySam( id: widget.plant.caySamId,serialNumber: uid);
        if(data?.messCode == MessCode.IsOK){
          iosAlertMessage = "Ghi thẻ thành công!";
          _feedbackMessage = message;
        }else{
          iosErrorMessage = data?.message;
          _feedbackMessage = data?.message ?? 'lỗi server!';
        }
      }
      if (status == NfcStatus.success || status == NfcStatus.error) {
        Future.delayed(const Duration(seconds: 5, milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();

          }
          NfcManager.instance.stopSession(alertMessageIos: iosAlertMessage,
              errorMessageIos: iosErrorMessage).catchError((_) {});
        });
      }

    }

  }


  // --- Các hàm tạo NDEF Record (giữ nguyên) ---
  NdefRecord _createNdefTextRecord(String text, {String languageCode = 'en'}) {
    final langBytes = utf8.encode(languageCode);
    final textBytes = utf8.encode(text);
    final status = langBytes.length;
    final payload = Uint8List.fromList([status, ...langBytes, ...textBytes]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList([0x54]), // Type = 'T' (Text)
      identifier: Uint8List(0),
      payload: payload,
    );
  }
  NdefRecord _createNdefExternalRecord(String domain, String type, Uint8List payload) {
    final typeBytes = utf8.encode('$domain:$type');
    return NdefRecord(
      typeNameFormat: TypeNameFormat.external,
      type: Uint8List.fromList(typeBytes),
      identifier: Uint8List(0),
      payload: payload,
    );
  }
  NdefRecord _createNdefUriRecord(String uri) {
    Uri parsedUri = Uri.parse(uri);
    String scheme = parsedUri.scheme.toLowerCase();
    String host = parsedUri.host;
    String path = parsedUri.path;
    int prefixByte;
    String remainingPayload;
    if (scheme == 'https') {
      prefixByte = 0x04;
      remainingPayload = '$host$path';
    } else if (scheme == 'http') {
      prefixByte = 0x03;
      remainingPayload = '$host$path';
    } else {
      prefixByte = 0x00;
      remainingPayload = uri;
    }
    final uriBytes = utf8.encode(remainingPayload);
    final payloadBytes = Uint8List.fromList([prefixByte, ...uriBytes]);
    return NdefRecord(
      typeNameFormat: TypeNameFormat.wellKnown,
      type: Uint8List.fromList(utf8.encode('U')), // 'U'
      identifier: Uint8List(0),
      payload: payloadBytes,
    );
  }

  // --- Giao diện của Popup ---
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 24),
          _buildStatusIndicator(),
          const SizedBox(height: 16),
          Text(
            _feedbackMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: _getColor()),
          ),
          const SizedBox(height: 24),

          // ✅ CHECKBOX ĐÃ ĐƯỢC XÓA BỎ

          const SizedBox(height: 16),

          if (_status == NfcStatus.scanning)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Hủy'),
              ),
            )
        ],
      ),
    );
  }

  // --- Các hàm build giao diện (giữ nguyên) ---
  String _getTitle() {
    switch (_status) {
      case NfcStatus.scanning: return 'Sẵn sàng quét';
      case NfcStatus.success: return 'Thành công!';
      case NfcStatus.error: return 'Ghi thẻ thất bại!';
    }
  }
  Color _getColor() {
    switch (_status) {
      case NfcStatus.scanning: return Colors.blue.shade700;
      case NfcStatus.success: return Colors.green.shade700;
      case NfcStatus.error: return Colors.red.shade700;
    }
  }
  Widget _buildStatusIndicator() {
    switch (_status) {
      case NfcStatus.scanning:
        return _buildAnimatedIcon(Icons.nfc, Colors.blue.shade700);
      case NfcStatus.success:
        return _buildAnimatedIcon(Icons.check_circle, Colors.green.shade700);
      case NfcStatus.error:
        return _buildAnimatedIcon(Icons.error, Colors.red.shade700);
    }
  }
  Widget _buildAnimatedIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 64, color: color),
    );
  }
}

