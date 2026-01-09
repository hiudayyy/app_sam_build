// Nhớ import thư viện này ở đầu file
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class InternalFileViewer extends StatelessWidget {
  final String url;
  final String fileName;

  const InternalFileViewer({Key? key, required this.url, required this.fileName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isPdf = url.toLowerCase().contains('.pdf');

    return Scaffold(
      backgroundColor: Colors.black, // Nền đen để xem cho rõ
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(fileName, style: const TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: true,
      ),
      body: isPdf
          ? const PDF(
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
      ).cachedFromUrl(
        url,
        placeholder: (progress) => Center(child: Text('$progress %', style: const TextStyle(color: Colors.white))),
        errorWidget: (error) => Center(child: Text("Lỗi tải PDF: $error", style: const TextStyle(color: Colors.white))),
      )
          : Center(
        // Dùng InteractiveViewer để có thể Zoom ảnh
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) => const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 50),
                Text("Không thể tải ảnh", style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}