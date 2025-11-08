import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../services/auction_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';
import 'auction_bid_screen.dart';
import 'auction_history_screen.dart';

class AuctionActiveScreen extends StatefulWidget {
  const AuctionActiveScreen({super.key});

  @override
  State<AuctionActiveScreen> createState() => _AuctionActiveScreenState();
}

class _AuctionActiveScreenState extends State<AuctionActiveScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _userService = UserService();
  final _auctionService = AuctionService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _syncData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshInterestsOnly();
    }
  }

  Future<void> _refreshInterestsOnly() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshInterests(user.id);

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _syncData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;

    if (user != null) {
      await _auctionService.fetchAuctions(forceRefresh: false);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshInterests(user.id);

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.vintageBg,
        body: Center(
          child: Text(
            'Silakan login terlebih dahulu',
            style: AppTextStyles.bodyLarge,
          ),
        ),
      );
    }

    final registeredAuctions = _userService.getRegisteredAuctions(user.id);
    final ongoingAuctions = registeredAuctions
        .where((a) {
          final auction = _auctionService.getAuctionById(a.auctionId);
          if (auction == null) return false;
          final now = DateTime.now();
          final endTime = auction.auctionDate.add(AppAnimations.auctionDuration);
          return now.isAfter(auction.auctionDate) && now.isBefore(endTime);
        })
        .toList();
    final upcomingAuctions = registeredAuctions
        .where((a) {
          final auction = _auctionService.getAuctionById(a.auctionId);
          if (auction == null) return false;
          return DateTime.now().isBefore(auction.auctionDate);
        })
        .toList();

    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: AppBar(
        backgroundColor: AppColors.vintageCream,
        elevation: 0,
        toolbarHeight: 35,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.vintageGold,
          labelColor: AppColors.vintageBrown,
          unselectedLabelColor: AppColors.textTertiary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Lelang Aktif'),
            Tab(text: 'Riwayat Lelang'),
          ],
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveUpcomingTab(
                context,
                user.id,
                ongoingAuctions,
                upcomingAuctions,
                orientation,
              ),
              AuctionHistoryScreen(userId: user.id),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveUpcomingTab(
    BuildContext context,
    String userId,
    List registeredAuctions,
    List upcomingAuctions,
    Orientation orientation,
  ) {
    final isLandscape = orientation == Orientation.landscape;

    if (registeredAuctions.isEmpty && upcomingAuctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.gavel_outlined,
              size: 64,
              color: Color.fromRGBO(155, 138, 124, 1),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada yang didaftarkan',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.vintageBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Daftarkan lelang dari halaman Beranda',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    if (isLandscape) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: registeredAuctions.length + upcomingAuctions.length,
        itemBuilder: (context, index) {
          if (index < registeredAuctions.length) {
            return _buildAuctionCard(
              context,
              userId,
              registeredAuctions[index],
              isActive: true,
            );
          } else {
            return _buildAuctionCard(
              context,
              userId,
              upcomingAuctions[index - registeredAuctions.length],
              isActive: false,
            );
          }
        },
      );
    }

    // Portrait mode - ListView (tanpa header)
    return ListView(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      children: [
        ...registeredAuctions.map((interest) => _buildAuctionCard(
              context,
              userId,
              interest,
              isActive: true,
            )),
        ...upcomingAuctions.map((interest) => _buildAuctionCard(
              context,
              userId,
              interest,
              isActive: false,
            )),
      ],
    );
  }

  Widget _buildAuctionCard(
    BuildContext context,
    String userId,
    interest, {
    required bool isActive,
  }) {
    final auction = _auctionService.getAuctionById(interest.auctionId);
    if (auction == null) return const SizedBox.shrink();

  final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
  final currency = user?.defaultCurrency ?? AppConstants.defaultCurrency;
  final timezone = user?.defaultTimezone ?? AppConstants.defaultTimezone;

    final now = DateTime.now();
    final isOngoing = isActive &&
        now.isAfter(auction.auctionDate) &&
        now.isBefore(auction.auctionDate.add(AppAnimations.auctionDuration));

    return Card(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AuctionBidScreen(
                auctionId: auction.id,
                interestId: interest.id,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                  child: Image.network(
                    auction.primaryImageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.image, size: 64),
                    ),
                  ),
                ),
                if (isOngoing)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text(
                        'BERLANGSUNG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    auction.title,
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.vintageBrown,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    auction.artist,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_offer,
                        size: 16,
                        color: AppColors.vintageGold,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        'Harga Dasar: ',
                        style: AppTextStyles.bodySmall,
                      ),
                      Text(
                        ConversionHelper.formatConvertedCurrency(
                          auction.minimumBid,
                          currency,
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.vintageGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.vintageBrown,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        ConversionHelper.formatDateTime(auction.auctionDate, timezone),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuctionBidScreen(
                              auctionId: auction.id,
                              interestId: interest.id,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.vintageGold,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(isOngoing ? 'Input Tawaran' : 'Lihat Detail'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
