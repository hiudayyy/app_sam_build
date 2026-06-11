import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/baiviet/baiviet_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final BaiVietModel article;
  final List<BaiVietModel> relatedArticles;

  const ArticleDetailScreen({
    Key? key,
    required this.article,
    this.relatedArticles = const [],
  }) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen>
    with TickerProviderStateMixin {
  // Controllers animation
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _badgeController;

  // Animations ảnh bìa
  late Animation<double> _heroFade;
  late Animation<double> _heroScale;

  // Animation badge + tiêu đề trên ảnh
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  // Animations nội dung
  late Animation<double> _descFade;
  late Animation<Offset> _descSlide;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;
  late Animation<double> _relatedFade;
  late Animation<Offset> _relatedSlide;

  String _cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    String parsed = htmlString.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    parsed = parsed.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    parsed = parsed.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true), '');
    parsed = parsed.replaceAll('&nbsp;', ' ');
    parsed = parsed.replaceAll('&quot;', '"');
    parsed = parsed.replaceAll('&amp;', '&');
    parsed = parsed.replaceAll('&lt;', '<');
    parsed = parsed.replaceAll('&gt;', '>');
    parsed = parsed.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
    return parsed.trim();
  }

  @override
  void initState() {
    super.initState();

    // ── Hero (ảnh bìa): 600ms ──────────────────────────────────
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _heroScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    // ── Badge + tiêu đề trên ảnh: 500ms, delay 300ms ──────────
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _badgeFade = CurvedAnimation(parent: _badgeController, curve: Curves.easeOut);
    _badgeSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeOutCubic),
    );
    _titleFade = CurvedAnimation(parent: _badgeController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _badgeController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)),
    );

    // ── Nội dung: staggered 3 phần ────────────────────────────
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _descFade = CurvedAnimation(parent: _contentController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _descSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    _contentFade = CurvedAnimation(parent: _contentController,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOut));
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController,
          curve: const Interval(0.25, 0.8, curve: Curves.easeOutCubic)),
    );
    _relatedFade = CurvedAnimation(parent: _contentController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOut));
    _relatedSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController,
          curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic)),
    );

    // Bắt đầu tuần tự
    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _badgeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _badgeController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.article.tieuDe ?? 'Không có tiêu đề';
    final String shortDesc = widget.article.moTaNgan ?? '';
    final String imageUrl = widget.article.hinhAnh ?? '';
    final String rawContent = widget.article.noiDung ?? '';
    final String content = rawContent.isNotEmpty
        ? _cleanHtml(rawContent)
        : 'Đang cập nhật nội dung...';
    final List<BaiVietModel> filteredRelated = widget.relatedArticles
        .where((a) => a.tieuDe != widget.article.tieuDe)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── ẢNH BÌA — fade in, ảnh scale riêng ──────────────
            SizedBox(
              height: 290,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh — scale riêng, không kéo layout
                  ClipRect(
                    child: FadeTransition(
                      opacity: _heroFade,
                      child: AnimatedBuilder(
                        animation: _heroScale,
                        builder: (context, child) => Transform.scale(
                          scale: _heroScale.value,
                          child: child,
                        ),
                        child: imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: double.infinity,
                          height: 290,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: const Color(0xFF2E7D32)),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFF1B5E20),
                            child: const Center(child: Icon(Icons.eco_rounded, color: Colors.white24, size: 64)),
                          ),
                        )
                            : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(child: Icon(Icons.eco_rounded, color: Colors.white24, size: 80)),
                        ),
                      ),
                    ),
                  ),

                  // Gradient overlay — luôn đúng vị trí
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Color(0xDD1B5E20)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1.0],
                      ),
                    ),
                  ),

                  // Badge + tiêu đề — slide up từ dưới
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _badgeFade,
                          child: SlideTransition(
                            position: _badgeSlide,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.eco_rounded, size: 12, color: Color(0xFF1B5E20)),
                                  SizedBox(width: 5),
                                  Text('Sâm Ngọc Linh',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF1B5E20))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                height: 1.3,
                                shadows: [Shadow(color: Colors.black45, blurRadius: 8)],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── NỘI DUNG — sheet kéo lên với staggered animation ──
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F9F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Mô tả ngắn — fade + slide (phần 1)
                    if (shortDesc.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _descFade,
                        child: SlideTransition(
                          position: _descSlide,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 4,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    shortDesc,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black54,
                                      height: 1.6,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Nội dung chi tiết — fade + slide (phần 2)
                    FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(9)),
                                child: const Icon(Icons.article_rounded,
                                    color: Color(0xFF2E7D32), size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text('Nội dung bài viết',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A))),
                            ]),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
                              ),
                              child: Text(
                                content,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF2C2C2C),
                                  height: 1.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Bài viết gợi ý — fade + slide (phần 3)
                    if (filteredRelated.isNotEmpty) ...[
                      FadeTransition(
                        opacity: _relatedFade,
                        child: SlideTransition(
                          position: _relatedSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(9)),
                                  child: const Icon(Icons.auto_awesome_rounded,
                                      color: Color(0xFF2E7D32), size: 16),
                                ),
                                const SizedBox(width: 8),
                                const Text('Có thể bạn quan tâm',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1A1A1A))),
                              ]),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 210,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredRelated.length,
                                  itemBuilder: (context, index) =>
                                      _buildRelatedArticleCard(context, filteredRelated[index]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ] else
                      const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedArticleCard(BuildContext context, BaiVietModel relatedArticle) {
    final String relatedTitle = relatedArticle.tieuDe ?? 'Không có tiêu đề';
    final String relatedImage = relatedArticle.hinhAnh ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(
              article: relatedArticle,
              relatedArticles: widget.relatedArticles,
            ),
          ),
        );
      },
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: relatedImage,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(height: 110, color: const Color(0xFFE8F5E9)),
                    errorWidget: (context, url, error) => Container(
                      height: 110,
                      color: const Color(0xFFE8F5E9),
                      child: Center(child: Icon(Icons.eco_rounded, color: Colors.green.shade300, size: 32)),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0x441B5E20)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relatedTitle,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), height: 1.35),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    const Row(children: [
                      Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2E7D32)),
                      SizedBox(width: 4),
                      Text('Đọc ngay', style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32), fontWeight: FontWeight.w700)),
                    ]),
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