import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../models/auction_model.dart';
import '../../services/auction_service.dart';
import '../../services/notification_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';
import 'auction_list_screen.dart';
import 'auction_detail_screen.dart';
import '../auction/auction_active_screen.dart';
import '../profile/profile_screen.dart';
import '../notification/notification_list_screen.dart';
import '../../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final _auctionService = AuctionService();
  final _notificationService = NotificationService();
  final _userService = UserService();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _auctions = [];
  bool _isLoadingAuctions = true;
  bool _hasLoadedOnce = false;

  final List<String> _categories = [
    'Semua',
    'Renaisans',
    'Impresionis',
    'Modern',
    'Kontemporer',
    'Klasik'
  ];

  dynamic _featuredAuction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure notifications are initialized before loading auctions so
    // finished-auction notifications can be persisted and emitted reliably.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeNotifications();
      await _loadAuctionsData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app resumes, always check for finished auctions so users
      // receive result notifications even if the data was already loaded.
      if (!_hasLoadedOnce) {
        _loadAuctionsData();
      } else {
        // kick off checks without awaiting so we don't block the UI thread
        Future(() async {
          try {
            await _checkActiveAuctions();
            await _showInAppNotificationsIfNeeded();
          } catch (_) {
            // swallow - we'll try again later
          }
        });
      }
    }
  }

  Future<void> _loadAuctionsData() async {
    if (_hasLoadedOnce) return;

    setState(() => _isLoadingAuctions = true);

    try {
      final auctions = await _auctionService.fetchAuctions();
      if (mounted) {
        setState(() {
          _auctions = auctions;
          _isLoadingAuctions = false;
          _hasLoadedOnce = true;
        });
        await _checkActiveAuctions();
        await _showInAppNotificationsIfNeeded();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAuctions = false);
      }
    }
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  Future<void> _showInAppNotificationsIfNeeded() async {
    if (_auctions.isEmpty) return;

    final now = DateTime.now();
    final activeAuctions = _auctions.where((a) {
      final end = a.auctionDate.add(AppAnimations.auctionDuration);
      return now.isAfter(a.auctionDate) && now.isBefore(end);
    }).toList();

    if (activeAuctions.isNotEmpty && mounted) {
      final firstActive = activeAuctions.first;
      // Prefer persisting & recording the popup so the notification service
      // can avoid showing a duplicate snackbar for the same auction.
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        await NotificationService().addNotification(
          userId: user.id,
          title: 'Lelang Aktif!',
          message: '${firstActive.title} sedang berlangsung!',
          type: 'auction_active',
          auctionId: firstActive.id,
          context: context,
          showPopup: true,
        );
      } else {
        // No user available — show popup without persisting
        await NotificationService.showInAppNotification(
          context,
          title: 'Lelang Aktif!',
          message: '${firstActive.title} sedang berlangsung!',
          actionText: 'Lihat Sekarang',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AuctionDetailScreen(auction: firstActive)),
            );
          },
        );
      }
    }
  }

  Future<void> _checkActiveAuctions() async {
    if (_auctions.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user == null) return;
    
    final registeredAuctions = _userService.getRegisteredAuctions(user.id);
  if (!mounted) return;
  final now = DateTime.now();

    // Check for finished auctions first so users get immediate results
    // (system notification + persisted record) when the app loads/resumes.
    await _notificationService.checkFinishedAuctionsForUser(
      userId: user.id,
      registeredAuctions: registeredAuctions,
      allAuctions: _auctions.cast<AuctionModel>(),
      context: context,
    );

    await _notificationService.checkUpcomingAuctions(
      userId: user.id,
      registeredAuctions: registeredAuctions,
      allAuctions: _auctions.cast<AuctionModel>(),
      context: context,
    );
 
    for (var auction in _auctions) {
      final end = auction.auctionDate.add(AppAnimations.auctionDuration);
      if (now.isAfter(auction.auctionDate) && now.isBefore(end)) {
        if (mounted) {
          await _notificationService.notifyAuctionActive(
            userId: user.id,
            auctionId: auction.id,
            auctionTitle: auction.title,
            message: 'Lelang sedang berlangsung!',
            context: context,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: _buildAppBar(),
      body: _selectedIndex == 0 ? _buildHomeContent() : _buildOtherScreen(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.vintageCream,
      elevation: 2,
      title: _isSearchVisible ? _buildSearchField() : _buildTitleRow(),
      automaticallyImplyLeading: false,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: AppColors.vintageBrown),
      decoration: InputDecoration(
        hintText: 'Cari lelang...',
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        border: InputBorder.none,
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, color: AppColors.vintageBrown),
          onPressed: () {
            setState(() {
              _searchQuery = '';
              _searchController.clear();
              _isSearchVisible = false;
            });
          },
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        const Text(
          'Arva',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.vintageBrown,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.vintageBrown),
          onPressed: () => setState(() => _isSearchVisible = true),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: AppColors.vintageBrown),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationListScreen()),
                );
                setState(() {});
              },
            ),
            Consumer<AuthProvider>(
              builder: (context, auth, child) {
                final user = auth.currentUser;
                if (user == null) return const SizedBox.shrink();
                
                final unreadCount = _notificationService.getUnreadCount(user.id);
                if (unreadCount == 0) return const SizedBox.shrink();
                
                return Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 6,
                    backgroundColor: AppColors.vintageRed,
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: AppColors.vintageCream,
      selectedItemColor: AppColors.vintageGold,
      unselectedItemColor: AppColors.vintageBrown.withOpacity(0.6),
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.gavel), label: 'Lelang'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }

  Widget _buildHomeContent() {
    if (_isLoadingAuctions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.vintageGold),
            const SizedBox(height: 16),
            Text(
              'Memuat lelang...',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_auctions.isEmpty) {
      return _buildEmptyState();
    }

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
        final currency = user?.defaultCurrency ?? AppConstants.defaultCurrency;
        final timezone = user?.defaultTimezone ?? AppConstants.defaultTimezone;

        final filteredAuctions = _auctionService.filterAuctions(
          searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          category: _selectedCategory == 'Semua' ? null : _selectedCategory,
        );

        final now = DateTime.now();
        final upcoming = filteredAuctions.where((a) => now.isBefore(a.auctionDate)).toList()
          ..sort((a, b) => a.auctionDate.compareTo(b.auctionDate));
        _featuredAuction = upcoming.isNotEmpty ? upcoming.first : null;

        final activeAuctions = filteredAuctions.where((a) {
          final end = a.auctionDate.add(AppAnimations.auctionDuration);
          return now.isAfter(a.auctionDate) && now.isBefore(end);
        }).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_featuredAuction != null) ...[
                _buildAdBanner(_featuredAuction!, currency),
                const SizedBox(height: 24),
              ],

              if (activeAuctions.isNotEmpty) ...[
                const Text('Lelang Berlangsung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.vintageBrown, fontFamily: 'Poppins')),
                const SizedBox(height: 12),
                SizedBox(
                  height: 240,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: activeAuctions.length,
                    itemBuilder: (context, index) {
                      final auction = activeAuctions[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 48) / 2,
                          child: _buildActiveCard(auction, currency),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _buildCatalogSection(filteredAuctions, currency, timezone),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdBanner(dynamic a, String c) {
    return InkWell(
      onTap: () => _goDetail(a),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                a.primaryImageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: AppColors.vintageGold));
                },
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dapatkan kesempatan spesial', style: TextStyle(fontSize: 16, color: Colors.white)),
                    const Text('Berkah Lewat Lelang', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _goDetail(a),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFFF6B6B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Ikuti Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildActiveCard(dynamic a, String c) {
    final end = a.auctionDate.add(AppAnimations.auctionDuration);
    final remaining = end.difference(DateTime.now());
    final endingSoon = remaining.inMinutes < 2;

    return Card(
      elevation: 3,
      color: AppColors.vintageCream,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _goDetail(a),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    a.primaryImageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, p) => p == null
                        ? child
                        : Container(height: 110, color: Colors.grey[200], child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                    errorBuilder: (_, __, ___) => Container(height: 110, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 36)),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(8)),
                    child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _CountdownTimer(endTime: end, endingSoon: endingSoon),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.vintageBrown),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Mulai: ${a.auctionDate.hour.toString().padLeft(2, '0')}:${a.auctionDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ConversionHelper.formatConvertedCurrency(a.minimumBid, c),
                    style: const TextStyle(color: AppColors.vintageGold, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogSection(List<dynamic> auctions, String c, String t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Katalog Lelang", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.vintageBrown, fontFamily: 'Poppins')),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuctionListScreen())),
              child: const Text("Lihat Semua", style: TextStyle(color: AppColors.vintageGold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCategoryChips(),
        const SizedBox(height: 16),
        auctions.isEmpty
            ? _buildEmptyState(search: true)
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: auctions.length > 25 ? 25 : auctions.length,
                itemBuilder: (_, i) => _buildCatalogItem(auctions[i], c, t),
              ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final selected = (_selectedCategory ?? 'Semua') == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  if (cat == 'Semua') {
                    _selectedCategory = null;
                  } else if (_selectedCategory == cat) {
                    _selectedCategory = null;
                  } else {
                    _selectedCategory = cat;
                  }
                });
              },
              selectedColor: AppColors.vintageGold.withOpacity(0.3),
              labelStyle: TextStyle(
                color: selected ? AppColors.vintageBrown : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatalogItem(dynamic a, String c, String t) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10),
      color: AppColors.vintageCream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.border.withOpacity(0.5), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _goDetail(a),
        child: SizedBox(
          height: 100,
      child: Row(
        children: [
        ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.md),
                  bottomLeft: Radius.circular(AppRadius.md),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: a.primaryImageUrl.isNotEmpty
                      ? Image.network(
                          a.primaryImageUrl,


                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.vintageGold),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 36, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.vintageBrown),
                      ),
                      Text(
                        a.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              ConversionHelper.formatDateTime(a.auctionDate, t),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.local_offer, size: 13, color: AppColors.vintageGold),
                          const SizedBox(width: 3),
                          Text(
                            ConversionHelper.formatConvertedCurrency(a.minimumBid, c, decimalPlaces: 0),
                            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.vintageGold, fontSize: 11),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.vintageGold.withOpacity(0.9), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              _localizeCategory(a.category),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizeCategory(String? category) {
    if (category == null) return '';
    final x = category.trim().toLowerCase();
    switch (x) {
      case 'renaissance':
      case 'renaissances':
      case 'renaisans':
        return 'Renaisans';
      case 'impressionist':
      case 'impressionists':
      case 'impressionism':
      case 'impresionis':
        return 'Impresionis';
      case 'contemporary':
      case 'kontemporer':
        return 'Kontemporer';
      case 'classical':
      case 'klasik':
        return 'Klasik';
      case 'modern':
        return 'Modern';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  void _goDetail(dynamic a) => Navigator.push(context, MaterialPageRoute(builder: (_) => AuctionDetailScreen(auction: a)));

  Widget _buildEmptyState({bool search = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(search ? Icons.search_off : Icons.event_busy, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(search ? 'Tidak ada lelang ditemukan' : 'Tidak ada lelang tersedia', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherScreen() {
    final screens = [_buildHomeContent(), const AuctionActiveScreen(), const ProfileScreen()];
    return screens[_selectedIndex];
  }
}

class _CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final bool endingSoon;

  const _CountdownTimer({
    required this.endTime,
    required this.endingSoon,
  });

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    setState(() {
      _remaining = widget.endTime.difference(DateTime.now());
    });
  }

  String _formatCountdown(Duration d) {
    if (d.isNegative) return 'Selesai';
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.endingSoon ? AppColors.error : Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _formatCountdown(_remaining),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}