import 'package:flutter/material.dart';
import '../../services/auction_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';
import '../../models/auction_model.dart';
import 'auction_detail_screen.dart';

class AuctionListScreen extends StatefulWidget {
  const AuctionListScreen({super.key});
  @override
  State<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends State<AuctionListScreen> {
  final _auctionService = AuctionService();
  final _authService = AuthService();
  final _userService = UserService();
  List<AuctionModel> _auctions = [];
  List<AuctionModel> _filteredAuctions = [];
  String _currency = AppConstants.defaultCurrency;
  String _timezone = AppConstants.defaultTimezone;
  bool _loading = true;
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Renaisans',
    'Impresionis',
    'Modern',
    'Kontemporer',
    'Klasik'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterAuctions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterAuctions() {
    setState(() {
      _searchQuery = _searchController.text;
      _filteredAuctions = _auctionService.filterAuctions(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory ?? 'Semua',
      );
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final current = await _authService.getCurrentUser();
    if (current != null) {
      final fresh = await _userService.getUserById(current.id);
      _currency = fresh?.defaultCurrency ?? current.defaultCurrency;
      _timezone = fresh?.defaultTimezone ?? current.defaultTimezone;
    }

    try {
      final auctions = await _auctionService.fetchAuctions();
      setState(() {
        _auctions = auctions;
        _filteredAuctions = auctions;
        _loading = false;
      });
      _filterAuctions();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat lelang: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: AppBar(
        backgroundColor: AppColors.vintageCream,
        elevation: 0,
        title: const Text(
          'Katalog Lelang',
          style: TextStyle(
            color: AppColors.vintageBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.vintageGold),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat katalog lelang...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : _auctions.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
               
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: AppColors.vintageCream,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari lelang...',
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.vintageBrown),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear,
                                      color: AppColors.vintageBrown),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.vintageGold, width: 2),
                          ),
                        ),
                      ),
                    ),

                  
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                      color: AppColors.vintageCream,
                      child: SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category ||
                                (_selectedCategory == null &&
                                    category == 'Semua');
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected && category != 'Semua'
                                            ? category
                                            : null;
                                  });
                                  _filterAuctions();
                                },
                                selectedColor:
                                    AppColors.vintageGold.withOpacity(0.3),
                                checkmarkColor: AppColors.vintageBrown,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? AppColors.vintageBrown
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                 
                    Expanded(
                      child: _filteredAuctions.isEmpty
                          ? _buildNoResults()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8),
                                itemCount: _filteredAuctions.length,
                                itemBuilder: (ctx, i) {
                                  final auction = _filteredAuctions[i];
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    color: AppColors.vintageCream,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      side: BorderSide(
                                          color:
                                              AppColors.border.withOpacity(0.5),
                                          width: 1),
                                    ),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.md),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AuctionDetailScreen(
                                                auction: auction),
                                          ),
                                        );
                                      },
                                      child: SizedBox(
                                        height: 100,
                                        child: Row(
                                          children: [
                                            
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topLeft: Radius.circular(
                                                    AppRadius.md),
                                                bottomLeft: Radius.circular(
                                                    AppRadius.md),
                                              ),
                                              child: Container(
                                                width: 100,
                                                height: 100,
                                                color: AppColors.surfaceVariant,
                                                child: auction.primaryImageUrl
                                                        .isNotEmpty
                                                    ? Image.network(
                                                        auction.primaryImageUrl,
                                                        width: 100,
                                                        height: 100,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (context,
                                                            child,
                                                            loadingProgress) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child;
                                                          }
                                                          return const Center(
                                                            child: SizedBox(
                                                              width: 20,
                                                              height: 20,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: AppColors
                                                                    .vintageGold,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder:
                                                            (_, __, ___) =>
                                                                const Icon(
                                                          Icons.broken_image,
                                                          size: 36,
                                                          color: Colors.grey,
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.image,
                                                        size: 36,
                                                        color: Colors.grey,
                                                      ),
                                              ),
                                            ),

                                            Expanded(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                  
                                                    Text(
                                                      auction.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .vintageBrown,
                                                      ),
                                                    ),

                                                    
                                                    Text(
                                                      auction.artist,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextStyles
                                                          .bodySmall
                                                          .copyWith(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),

                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.access_time,
                                                            size: 13,
                                                            color: AppColors
                                                                .textSecondary),
                                                        const SizedBox(
                                                            width: 3),
                                                        Expanded(
                                                          child: Text(
                                                            ConversionHelper
                                                                .formatDateTime(
                                                                    auction
                                                                        .auctionDate,
                                                                    _timezone),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: AppTextStyles
                                                                .bodySmall
                                                                .copyWith(
                                                              color: AppColors
                                                                  .textSecondary,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),

                                                    Row(
                                                      children: [
                                                        const Icon(
                                                            Icons.local_offer,
                                                            size: 13,
                                                            color: AppColors
                                                                .vintageGold),
                                                        const SizedBox(
                                                            width: 3),
                                                        Text(
                                                          ConversionHelper
                                                              .formatConvertedCurrency(
                                                            auction.minimumBid,
                                                            _currency,
                                                            decimalPlaces: 0,
                                                          ),
                                                          style: AppTextStyles
                                                              .bodySmall
                                                              .copyWith(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: AppColors
                                                                .vintageGold,
                                                            fontSize: 11,
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
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.vintageCream,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.vintageGold.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.gavel_outlined,
                size: 64, color: AppColors.vintageGold),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada lelang saat ini',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.vintageBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.vintageCream,
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.vintageGold.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.search_off,
                  size: 64, color: AppColors.vintageGold),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada lelang ditemukan',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.vintageBrown,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Coba ubah kata kunci atau filter kategori',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
