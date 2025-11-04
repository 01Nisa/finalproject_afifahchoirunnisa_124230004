import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../main.dart';
import '../../services/user_service.dart';
import '../../services/auction_service.dart';
import '../../services/bid_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';

class AuctionBidScreen extends StatefulWidget {
  final String auctionId;
  final String interestId;

  const AuctionBidScreen({
    super.key,
    required this.auctionId,
    required this.interestId,
  });

  @override
  State<AuctionBidScreen> createState() => _AuctionBidScreenState();
}

class _AuctionBidScreenState extends State<AuctionBidScreen> {
  final _userService = UserService();
  final _auctionService = AuctionService();
  final _bidService = BidService();
  final _bidController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _countdownTimer;
  bool _isLoading = false;
  dynamic _auction;
  double _currentBid = 0.0;
  bool _isLoadingAuction = true;

  @override
  void initState() {
    super.initState();
    _loadAuction();
    _startCountdownTimer();

    _bidController.addListener(() => setState(() {}));
  }

  Future<void> _loadAuction() async {
    setState(() => _isLoadingAuction = true);
    final auctions = await _auctionService.fetchAuctions();
    try {
      _auction = auctions.firstWhere((a) => a.id == widget.auctionId);
    } catch (_) {
      _auction = _auctionService.getAuctionById(widget.auctionId);
    }
    if (_auction != null) {
      await _loadCurrentBid();
    }
    setState(() => _isLoadingAuction = false);
  }

  Future<void> _loadCurrentBid() async {
    try {
      final highestBid = await _bidService.getHighestBid(widget.auctionId);
      final data = highestBid['data'];
      if (data != null) {
        if (data is Map) {
          _currentBid = (data['harga_tawaran'] as num?)?.toDouble() ??
              (data['hargaTawaran'] as num?)?.toDouble() ??
              _auction?.minimumBid ??
              0.0;
        } else {
          _currentBid =
              (data as dynamic).hargaTawaran ?? _auction?.minimumBid ?? 0.0;
        }
      } else {
        final price = highestBid['harga'] as num?;
        _currentBid = price?.toDouble() ?? _auction?.minimumBid ?? 0.0;
      }
      if (mounted) setState(() {});
    } catch (e) {
      _currentBid = _auction?.minimumBid ?? 0.0;
      if (mounted) setState(() {});
    }
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _bidController.dispose();
    _focusNode.dispose();
    super.dispose();
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
      body: _isLoadingAuction
          ? const Center(child: CircularProgressIndicator())
          : _auction == null
              ? const Center(child: Text('Lelang tidak ditemukan'))
              : Builder(
                  builder: (context) {
                    final auction = _auction!;
                    final now = DateTime.now();
                    final startTime = auction.auctionDate;
                    final endTime =
                        startTime.add(AppAnimations.auctionDuration);
                    final isUpcoming = now.isBefore(startTime);
                    final isOngoing =
                        now.isAfter(startTime) && now.isBefore(endTime);
                    final isFinished = now.isAfter(endTime);

                    final currentBid =
                        _currentBid > 0 ? _currentBid : auction.minimumBid;

                    Duration remainingTime;
                    if (isOngoing) {
                      remainingTime = endTime.difference(now);
                    } else if (isUpcoming) {
                      remainingTime = startTime.difference(now);
                    } else {
                      remainingTime = Duration.zero;
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildImage(auction.primaryImageUrl),
                                const SizedBox(height: AppSpacing.lg),
                                _buildTitleAndArtist(auction),
                                const SizedBox(height: AppSpacing.lg),
                                _buildPriceInfo('Harga Dasar',
                                    auction.minimumBid, user.defaultCurrency),
                                const SizedBox(height: AppSpacing.sm),
                                _buildPriceInfo(
                                  'Tawaran Tertinggi',
                                  currentBid,
                                  user.defaultCurrency,
                                  isHighlight: true,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                if (isOngoing) ...[
                                  _buildBidInputLabel(
                                      currentBid, user.defaultCurrency),
                                  const SizedBox(height: AppSpacing.md),
                                ],
                                _buildLocationInfo(auction),
                                const SizedBox(height: AppSpacing.lg),
                                _buildDateInfo(
                                    auction.auctionDate, user.defaultTimezone),
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
                          child: Column(
                            children: [
                              if (isOngoing) ...[
                                _buildCountdown(remainingTime),
                                const SizedBox(height: AppSpacing.md),
                                _buildBidButton(
                                    user.id, currentBid, user.defaultCurrency),
                              ] else if (isUpcoming) ...[
                                _buildCancelButton(),
                              ] else if (isFinished) ...[
                                _buildFinishedBanner(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    );
                  },
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

  Widget _buildPriceInfo(String label, double amount, String currency,
      {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.vintageGold.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isHighlight
            ? Border.all(color: AppColors.vintageGold, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            ConversionHelper.formatConvertedCurrency(amount, currency),
            style: AppTextStyles.h4.copyWith(
              color:
                  isHighlight ? AppColors.vintageGold : AppColors.vintageBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown(Duration remaining) {
    final timeStr = remaining.isNegative
        ? '00:00'
        : '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.vintageGold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.vintageGold, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: AppColors.vintageGold, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Waktu Tersisa: $timeStr',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.vintageGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBidInputLabel(double currentBid, String currency) {
    final auctionMinBid = _auction?.minimumBid ?? 0.0;
    final minBid = currentBid > auctionMinBid ? currentBid : auctionMinBid;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Input Tawaran',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.vintageBrown,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _bidController,
            focusNode: _focusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Masukkan jumlah tawaran',
              hintText:
                  'Min: ${ConversionHelper.formatConvertedCurrency(minBid, currency)}',
              prefixIcon:
                  const Icon(Icons.local_offer, color: AppColors.vintageGold),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              errorText: _getBidErrorText(minBid, currency),
              errorMaxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  String? _getBidErrorText(double minBid, String currency) {
    final text = _bidController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return 'Masukkan angka yang valid';
    if (value < minBid) {
      return 'Tawaran harus lebih besar dari ${ConversionHelper.formatConvertedCurrency(minBid, currency)}';
    }
    return null;
  }

  Widget _buildBidButton(String userId, double currentBid, String currency) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed:
            _isLoading ? null : () => _placeBid(userId, currentBid, currency),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.vintageGold,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Kirim Tawaran',
                style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildFinishedBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.error),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Lelang telah selesai',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w500),
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
              onPressed: () {
                // TODO: Implement open maps
              },
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

  Future<void> _placeBid(
      String userId, double currentBid, String currency) async {
    if (_auction == null) return;

    final bidText = _bidController.text.trim();
    final bidAmount = double.tryParse(bidText);

    if (bidText.isEmpty || bidAmount == null) {
      _showSnackBar('Masukkan jumlah tawaran yang valid', isError: true);
      return;
    }

    if (bidAmount <= currentBid) {
      _showSnackBar(
          'Tawaran harus lebih besar dari ${ConversionHelper.formatConvertedCurrency(currentBid, currency)}',
          isError: true);
      return;
    }

    // Konfirmasi jika bid > 2x current
    if (bidAmount > currentBid * 2) {
      final confirm = await _showConfirmDialog(
        'Tawaran Besar',
        'Anda akan menawar ${ConversionHelper.formatConvertedCurrency(bidAmount, currency)}. Lanjutkan?',
      );
      if (!confirm) return;
    }

    setState(() => _isLoading = true);

    try {
      final user =
          Provider.of<AuthProvider>(context, listen: false).currentUser;
      final userName = user?.name ?? 'Anonymous';

      final result = await _bidService.placeBid(
        lelangId: widget.auctionId,
        userId: userId,
        userName: userName,
        hargaTawaran: bidAmount,
      );

      await _loadCurrentBid();

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _bidController.clear();
        _focusNode.requestFocus();
        _showSnackBar(result['message'] ?? 'Tawaran berhasil disimpan!',
            isError: false);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal mengirim tawaran',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan: ${e.toString()}', isError: true);
    }
  }

  Future<void> _cancelAuction() async {
    final confirmed = await _showConfirmDialog(
      'Batalkan Pendaftaran',
      'Apakah Anda yakin ingin membatalkan pendaftaran lelang ini?',
    );

    if (confirmed && mounted) {
      await _userService.unregisterAuction(widget.interestId);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran lelang dibatalkan')),
      );
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white),
                child: const Text('Ya'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }
}
