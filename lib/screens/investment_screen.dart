import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════════
// INVESTMENT SCREEN — Màn hình Đầu tư Sâm Ngọc Linh Nghị Gia
// ═══════════════════════════════════════════════════════════════════

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({Key? key}) : super(key: key);

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _green900 = Color(0xFF1B5E20);
  static const Color _green700 = Color(0xFF2E7D32);
  static const Color _green400 = Color(0xFF66BB6A);
  static const Color _mint    = Color(0xFFE8F5E9);
  static const Color _mintBorder = Color(0xFFD0EBD0);
  static const Color _gold    = Color(0xFFFFD54F);
  static const Color _bg      = Color(0xFFF5F9F5);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── HEADER ──────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),
          // ── STATS ROW ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildStatsRow(),
            ),
          ),
          // ── TAB BAR ─────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: _green700,
                unselectedLabelColor: Colors.black45,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                indicatorColor: _green700,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Gói đầu tư'),
                  Tab(text: 'Danh mục'),
                  Tab(text: 'Lịch sử'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPackagesTab(),
            _buildPortfolioTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // ── HEADER GRADIENT ────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 52, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_green900, _green700, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.trending_up_rounded, size: 13, color: _gold),
                SizedBox(width: 5),
                Text('Đầu tư sinh lời',
                    style: TextStyle(color: Colors.white, fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('Đầu tư Sâm\nNgọc Linh',
              style: TextStyle(color: Colors.white, fontSize: 26,
                  fontWeight: FontWeight.w900, height: 1.2, letterSpacing: 0.3)),
          const SizedBox(height: 8),
          Text('Sở hữu cây sâm quý — nhận lợi nhuận thực',
              style: TextStyle(color: Colors.white.withOpacity(0.75),
                  fontSize: 13, height: 1.4)),
          const SizedBox(height: 20),
          // CTA Button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15),
                    blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.rocket_launch_rounded, size: 16, color: _green900),
                SizedBox(width: 8),
                Text('Bắt đầu đầu tư',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                        color: _green900)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ──────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _mintBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        _buildStat('8.672+', 'Nhà đầu tư'),
        _buildStatDiv(),
        _buildStat('125+ tỷ', 'Tổng giá trị'),
        _buildStatDiv(),
        _buildStat('18%', 'Lợi nhuận/năm'),
        _buildStatDiv(),
        _buildStat('100%', 'Minh bạch'),
      ]),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
          color: _green900)),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9.5, color: Colors.black45, height: 1.3)),
    ]));
  }

  Widget _buildStatDiv() =>
      Container(width: 1, height: 28, color: _mintBorder);

  // ── TAB 1: GÓI ĐẦU TƯ ─────────────────────────────────────────────
  Widget _buildPackagesTab() {
    final packages = [
      _PackageData(
        name: 'Gói Bạc',
        price: '10.000.000 đ',
        duration: '3 năm',
        profit: '12%/năm',
        trees: '5 cây',
        color: const Color(0xFF78909C),
        bgColor: const Color(0xFFF5F7F8),
        icon: Icons.workspace_premium_rounded,
        tags: ['Phù hợp người mới', 'Rủi ro thấp'],
      ),
      _PackageData(
        name: 'Gói Vàng',
        price: '50.000.000 đ',
        duration: '5 năm',
        profit: '18%/năm',
        trees: '25 cây',
        color: const Color(0xFFF9A825),
        bgColor: const Color(0xFFFFFDE7),
        icon: Icons.local_florist_rounded,
        tags: ['Phổ biến nhất', 'Lợi nhuận cao'],
        featured: true,
      ),
      _PackageData(
        name: 'Gói Bạch Kim',
        price: '200.000.000 đ',
        duration: '7 năm',
        profit: '25%/năm',
        trees: '100 cây',
        color: const Color(0xFF6A1B9A),
        bgColor: const Color(0xFFF9F0FF),
        icon: Icons.diamond_rounded,
        tags: ['Nhà đầu tư VIP', 'Lợi nhuận tối đa'],
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: packages.map((p) => _buildPackageCard(p)).toList(),
    );
  }

  Widget _buildPackageCard(_PackageData p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: p.featured ? p.color.withOpacity(0.4) : _mintBorder,
          width: p.featured ? 1.5 : 1,
        ),
        boxShadow: [BoxShadow(
          color: p.featured
              ? p.color.withOpacity(0.12)
              : Colors.black.withOpacity(0.04),
          blurRadius: p.featured ? 14 : 8,
          offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: p.bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(17),
                topRight: Radius.circular(17),
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(p.icon, color: p.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(p.name, style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w800, color: p.color)),
                    if (p.featured) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('HOT',
                            style: TextStyle(fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: p.tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 10,
                        color: p.color, fontWeight: FontWeight.w600)),
                  )).toList()),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(p.profit, style: TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w900, color: p.color)),
                const Text('lợi nhuận', style: TextStyle(
                    fontSize: 10, color: Colors.black45)),
              ]),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(children: [
              _buildPackageInfo(Icons.attach_money_rounded,
                  'Vốn tối thiểu', p.price),
              const SizedBox(width: 12),
              _buildPackageInfo(Icons.access_time_rounded,
                  'Thời hạn', p.duration),
              const SizedBox(width: 12),
              _buildPackageInfo(Icons.energy_savings_leaf_rounded,
                  'Số cây', p.trees),
              const Spacer(),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: p.featured ? p.color : _mint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Đầu tư',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: p.featured ? Colors.white : _green700)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageInfo(IconData icon, String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      const SizedBox(height: 2),
      Row(children: [
        Icon(icon, size: 12, color: _green700),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 12,
            fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
      ]),
    ]);
  }

  // ── TAB 2: DANH MỤC ────────────────────────────────────────────────
  Widget _buildPortfolioTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Tổng tài sản
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_green900, Color(0xFF388E3C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: _green900.withOpacity(0.3),
                blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tổng tài sản', style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 13)),
            const SizedBox(height: 6),
            const Text('85.000.000 đ',
                style: TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF69F0AE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.arrow_upward_rounded, size: 12,
                      color: Color(0xFF69F0AE)),
                  SizedBox(width: 4),
                  Text('+12.5% so với năm ngoái',
                      style: TextStyle(color: Color(0xFF69F0AE),
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // Danh sách cây đang đầu tư
        Row(children: [
          Container(width: 3, height: 14,
              decoration: BoxDecoration(color: _green700,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('Cây sâm đang sở hữu',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const Spacer(),
          Text('25 cây', style: TextStyle(fontSize: 12,
              color: _green700, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        ...[
          _InvestItem('Vườn sâm Nghị Gia A', 'Lô A01 • 10 cây',
              '3 năm 2 tháng', '+18.2%', true),
          _InvestItem('Vườn sâm Nghị Gia B', 'Lô B03 • 15 cây',
              '1 năm 5 tháng', '+7.4%', true),
        ].map((item) => _buildInvestItem(item)),
      ],
    );
  }

  Widget _buildInvestItem(_InvestItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mintBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: _mint, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.park_rounded, color: _green700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(item.sub, style: const TextStyle(
                fontSize: 11, color: Colors.black45)),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 11,
                  color: Colors.black38),
              const SizedBox(width: 4),
              Text(item.duration, style: const TextStyle(
                  fontSize: 10.5, color: Colors.black45)),
            ]),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(item.profit, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: _green700)),
          ),
          const SizedBox(height: 6),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: Colors.black26),
        ]),
      ]),
    );
  }

  // ── TAB 3: LỊCH SỬ ─────────────────────────────────────────────────
  Widget _buildHistoryTab() {
    final items = [
      _HistoryItem('Mua 10 cây sâm', 'Vườn Nghị Gia A • Lô A01',
          '15/03/2024', '-50.000.000 đ', false),
      _HistoryItem('Nhận lợi nhuận Q1', 'Vườn Nghị Gia A',
          '01/04/2024', '+2.250.000 đ', true),
      _HistoryItem('Mua 15 cây sâm', 'Vườn Nghị Gia B • Lô B03',
          '20/05/2024', '-75.000.000 đ', false),
      _HistoryItem('Nhận lợi nhuận Q2', 'Vườn Nghị Gia A',
          '01/07/2024', '+2.250.000 đ', true),
      _HistoryItem('Nhận lợi nhuận Q3', 'Vườn Nghị Gia A',
          '01/10/2024', '+2.250.000 đ', true),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _buildHistoryItem(items[index]),
    );
  }

  Widget _buildHistoryItem(_HistoryItem item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _mintBorder, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: item.isProfit
                ? _mint
                : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            item.isProfit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: item.isProfit ? _green700 : const Color(0xFFF57C00),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(item.sub, style: const TextStyle(
                fontSize: 11, color: Colors.black45)),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(item.amount, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w800,
            color: item.isProfit ? _green700 : const Color(0xFFF57C00),
          )),
          const SizedBox(height: 2),
          Text(item.date, style: const TextStyle(
              fontSize: 10, color: Colors.black38)),
        ]),
      ]),
    );
  }
}

// ── DATA MODELS ────────────────────────────────────────────────────────
class _PackageData {
  final String name, price, duration, profit, trees;
  final Color color, bgColor;
  final IconData icon;
  final List<String> tags;
  final bool featured;
  const _PackageData({
    required this.name, required this.price, required this.duration,
    required this.profit, required this.trees, required this.color,
    required this.bgColor, required this.icon, required this.tags,
    this.featured = false,
  });
}

class _InvestItem {
  final String name, sub, duration, profit;
  final bool active;
  const _InvestItem(this.name, this.sub, this.duration, this.profit, this.active);
}

class _HistoryItem {
  final String title, sub, date, amount;
  final bool isProfit;
  const _HistoryItem(this.title, this.sub, this.date, this.amount, this.isProfit);
}

// ── TAB BAR DELEGATE ───────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF5F9F5),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => 46;
  @override
  double get minExtent => 46;
  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}