import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/user_service.dart';
import '../../services/auction_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';

class AuctionUpcomingDetailScreen extends StatefulWidget {
  final String auctionId;
  final String interestId;

  const AuctionUpcomingDetailScreen({
    super.key,
    required this.auctionId,
    required this.interestId,
  });

  @override
  State<AuctionUpcomingDetailScreen> createState() =>
      _AuctionUpcomingDetailScreenState();
}

class _AuctionUpcomingDetailScreenState
    extends State<AuctionUpcomingDetailScreen> {
  final _userService = UserService();
  final _auctionService = AuctionService();
  dynamic _auction;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuction();
  }

  Future<void> _loadAuction() async {
    setState(() => _isLoading = true);
    final auctions = await _auctionService.fetchAuctions();
    try {
      _auction = auctions.firstWhere((a) => a.id == widget.auctionId);
    } catch (_) {
      _auction = _auctionService.getAuctionById(widget.auctionId);
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _auction == null
              ? const Center(child: Text('Lelang tidak ditemukan'))
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildImage(_auction!.primaryImageUrl),
                            const SizedBox(height: AppSpacing.lg),
                            _buildTitleAndArtist(_auction!),
                            const SizedBox(height: AppSpacing.lg),
                            _buildPriceInfo('Harga Dasar', _auction!.minimumBid,
                                user.defaultCurrency),
                            const SizedBox(height: AppSpacing.lg),
                            _buildLocationInfo(_auction!),
                            const SizedBox(height: AppSpacing.lg),
                            _buildDateInfo(
                                _auction!.auctionDate, user.defaultTimezone),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.vintageCream,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: _buildCancelButton(),
                    ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.vintageCream,
      elevation: 0,
      title: const Text(
        'Detail Lelang',
        style: TextStyle(color: AppColors.vintageBrown),
      ),
    );
  }

  Widget _buildImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Image.network(
        url,
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 280,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.image, size: 64, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTitleAndArtist(auction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auction.title,
          style: AppTextStyles.h2.copyWith(color: AppColors.vintageBrown),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          auction.artist,
          style: AppTextStyles.bodyLarge.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInfo(String label, double amount, String currency) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            ConversionHelper.formatConvertedCurrency(amount, currency),
            style: AppTextStyles.h4.copyWith(
              color: AppColors.vintageBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(auction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi', style: AppTextStyles.h4),
        const SizedBox(height: AppSpacing.sm),
        _buildInfoRow(Icons.location_on, auction.location),
        if (auction.latitude != null && auction.longitude != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Buka di Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vintageGold,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateInfo(DateTime date, String timezone) {
    return _buildInfoRow(
      Icons.calendar_today,
      'Jadwal Lelang',
      ConversionHelper.formatDateTime(date, timezone),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, [String? value]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.vintageBrown),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value == null ? label : '$label: $value',
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _cancelAuction,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: const Text('Batal Daftar'),
      ),
    );
  }

  Future<void> _cancelAuction() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Batalkan Pendaftaran'),
            content: const Text(
                'Apakah Anda yakin ingin membatalkan pendaftaran lelang ini?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed && mounted) {
      await _userService.unregisterAuction(widget.interestId);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran lelang dibatalkan')),
      );
    }
  }
}
