import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../api/api.dart';
import '../api/api_baiviet.dart';
import '../models/baiviet/baiviet_model.dart';
import 'article_detail_screen.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({Key? key}) : super(key: key);

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen>
    with SingleTickerProviderStateMixin {
  List<BaiVietModel> _articles = [];
  bool _isLoading = true;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fetchAllArticles();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllArticles() async {
    try {
      final response = await API().listBaiViet(top: 50);
      if (response != null && response.items != null && mounted) {
        setState(() {
          _articles = response.items!;
          _isLoading = false;
        });
        _listController.forward();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ),
        title: const Column(
          children: [
            Text(
              'Bài viết',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Sâm Ngọc Linh Nghị Gia',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.12)),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _articles.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchAllArticles,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Bài nổi bật đầu tiên — hero card lớn
            if (_articles.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _buildHeroCard(context, _articles.first),
                ),
              ),

            // Label danh sách
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.article_rounded,
                        color: Color(0xFF2E7D32), size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('Tất cả bài viết',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A))),
                  const Spacer(),
                  Text('${_articles.length - 1} bài',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),

            // Danh sách bài còn lại
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final article = _articles[index + 1];
                    // Staggered fade+slide animation
                    final delay = (index * 0.06).clamp(0.0, 0.9);
                    final anim = CurvedAnimation(
                      parent: _listController,
                      curve: Interval(delay,
                          (delay + 0.4).clamp(0.0, 1.0),
                          curve: Curves.easeOutCubic),
                    );
                    return AnimatedBuilder(
                      animation: anim,
                      builder: (context, child) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.18),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildArticleCard(context, article),
                      ),
                    );
                  },
                  childCount:
                  (_articles.length - 1).clamp(0, _articles.length),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── HERO CARD (bài đầu tiên, to) ──────────────────────────────────────
  Widget _buildHeroCard(BuildContext context, BaiVietModel article) {
    final String title = article.tieuDe ?? 'Không có tiêu đề';
    final String shortDesc = article.moTaNgan ?? '';
    final String imageUrl = article.hinhAnh ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(
            article: article,
            relatedArticles: _articles,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Ảnh
              imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    height: 220, color: const Color(0xFF2E7D32)),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: const Color(0xFF1B5E20),
                  child: const Center(
                      child: Icon(Icons.eco_rounded,
                          color: Colors.white24, size: 64)),
                ),
              )
                  : Container(
                height: 220,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0xEE1B5E20)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
              ),
              // Badge nổi bật
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, size: 12, color: Color(0xFF1B5E20)),
                      SizedBox(width: 4),
                      Text('Nổi bật',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20))),
                    ],
                  ),
                ),
              ),
              // Tiêu đề + mô tả
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shortDesc.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        shortDesc,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Đọc ngay',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
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

  // ── CARD DANH SÁCH (bài còn lại) ─────────────────────────────────────
  Widget _buildArticleCard(BuildContext context, BaiVietModel article) {
    final String title = article.tieuDe ?? 'Không có tiêu đề';
    final String shortDesc = article.moTaNgan ?? '';
    final String imageUrl = article.hinhAnh ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ArticleDetailScreen(
            article: article,
            relatedArticles: _articles,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F5E9), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Ảnh thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        height: 100, width: 100, color: const Color(0xFFE8F5E9)),
                    errorWidget: (context, url, error) => Container(
                      height: 100,
                      width: 100,
                      color: const Color(0xFFE8F5E9),
                      child: Center(
                          child: Icon(Icons.eco_rounded,
                              color: Colors.green.shade300, size: 28)),
                    ),
                  ),
                  // Subtle gradient on thumbnail
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, Color(0x331B5E20)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Nội dung
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (shortDesc.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        shortDesc,
                        style: const TextStyle(
                            fontSize: 11.5, color: Colors.black45, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.arrow_forward_rounded,
                          size: 11, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      const Text('Đọc ngay',
                          style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w700)),
                    ]),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 12, color: Color(0xFF2E7D32)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING SHIMMER ────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 7,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFFE8F5E9),
            highlightColor: Colors.white,
            child: Container(
              height: index == 0 ? 220 : 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(index == 0 ? 20 : 16),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── EMPTY STATE ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.article_outlined,
                size: 48, color: Colors.green.shade300),
          ),
          const SizedBox(height: 20),
          const Text('Chưa có bài viết nào',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Hãy quay lại sau',
              style:
              TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}