
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../services/auction_service.dart';
import '../../services/bid_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';

class AuctionHistoryScreen extends StatefulWidget {
  final String userId;

  const AuctionHistoryScreen({super.key, required this.userId});

  @override
  State<AuctionHistoryScreen> createState() => _AuctionHistoryScreenState();
}

class _AuctionHistoryScreenState extends State<AuctionHistoryScreen> {
  final _userService = UserService();
  final _auctionService = AuctionService();
  final _bidService = BidService();

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Silakan login'));
    }

    final registeredAuctions =
        _userService.getRegisteredAuctions(widget.userId);

    final completedAuctions = registeredAuctions.where((interest) {
      final auction = _auctionService.getAuctionById(interest.auctionId);
      if (auction == null) return false;
      final endTime = auction.auctionDate.add(AppAnimations.auctionDuration);
      return DateTime.now().isAfter(endTime);
    }).toList();

    if (completedAuctions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.vintageCream.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.border.withOpacity(0.4), width: 1.5),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 72,
                    color: AppColors.textTertiary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Belum ada riwayat lelang',
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.vintageBrown.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Riwayat lelang yang telah selesai akan muncul di sini',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary.withOpacity(0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currency = user.defaultCurrency;
    final timezone = user.defaultTimezone;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        color: AppColors.vintageGold,
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: completedAuctions.length,
          itemBuilder: (context, index) {
            final interest = completedAuctions[index];
            final auction = _auctionService.getAuctionById(interest.auctionId);
            if (auction == null) return const SizedBox.shrink();

            return _buildHistoryCard(
                context, interest, auction, currency, timezone);
          },
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    dynamic interest,
    dynamic auction,
    String currency,
    String timezone,
  ) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _bidService.getUserLastBid(lelangId: auction.id, userId: widget.userId),
        _bidService.getHighestBid(auction.id),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            color: AppColors.vintageCream.withOpacity(0.6),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.vintageGold)),
            ),
          );
        }

        final results = snapshot.data!;
        final userBid = results[0];
        final highestBidResult = results[1] as Map<String, dynamic>;
        final highestBidData = highestBidResult['data'];

        final isWinner = userBid != null &&
            highestBidData != null &&
            (userBid as dynamic).id == (highestBidData as dynamic).id;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          elevation: 2,
          color: AppColors.vintageCream.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side:
                BorderSide(color: AppColors.border.withOpacity(0.6), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.md)),
                    child: Opacity(
                      opacity: 0.85,
                      child: Image.network(
                        auction.primaryImageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 160,
                          color: AppColors.surfaceVariant.withOpacity(0.7),
                          child: const Icon(Icons.image,
                              size: 48, color: AppColors.textTertiary),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? AppColors.success.withOpacity(0.9)
                            : AppColors.error.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isWinner ? Icons.check_circle : Icons.cancel,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            isWinner ? 'BERHASIL' : 'GAGAL',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
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
                          color: AppColors.vintageBrown.withOpacity(0.9),
                          fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auction.artist,
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary.withOpacity(0.85),
                          fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),

                    if (userBid != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isWinner
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.vintageGold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                              color: isWinner
                                  ? AppColors.success.withOpacity(0.4)
                                  : AppColors.vintageGold.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.gavel,
                                size: 20,
                                color: isWinner
                                    ? AppColors.success
                                    : AppColors.vintageGold),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tawaran Anda',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary)),
                                  Text(
                                    ConversionHelper.formatConvertedCurrency(
                                        (userBid as dynamic).hargaTawaran,
                                        currency),
                                    style: AppTextStyles.h4.copyWith(
                                        color: isWinner
                                            ? AppColors.success
                                            : AppColors.vintageGold,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

  
                    _buildInfoRow(
                        Icons.local_offer,
                        'Harga Dasar',
                        ConversionHelper.formatConvertedCurrency(
                            auction.minimumBid, currency)),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        Icons.access_time,
                        'Waktu Lelang',
                        ConversionHelper.formatDateTime(
                            auction.auctionDate, timezone)),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showHistoryDetail(
                            context,
                            auction,
                            userBid,
                            highestBidData,
                            currency,
                            timezone,
                            isWinner),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('Lihat Detail'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: AppColors.vintageGold,
                          side: const BorderSide(color: AppColors.vintageGold),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary.withOpacity(0.8)),
        const SizedBox(width: 8),
        Text('$label: ',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.vintageBrown.withOpacity(0.85),
                fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showHistoryDetail(
    BuildContext context,
    dynamic auction,
    dynamic userBid,
    dynamic highestBidData,
    String currency,
    String timezone,
    bool isWinner,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.vintageBg,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.border.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text('Detail Riwayat',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.vintageBrown)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Opacity(
                        opacity: 0.7,
                        child: Image.network(
                          auction.primaryImageUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: AppColors.surfaceVariant,
                            child: const Icon(Icons.image,
                                size: 48, color: AppColors.textTertiary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(auction.title,
                        style: AppTextStyles.h2.copyWith(
                            color: AppColors.vintageBrown.withOpacity(0.9))),
                    const SizedBox(height: 4),
                    Text(auction.artist,
                        style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic)),

                    const SizedBox(height: 24),

                    if (userBid != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isWinner
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.error.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                              color: isWinner
                                  ? AppColors.success.withOpacity(0.3)
                                  : AppColors.error.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                    isWinner
                                        ? Icons.emoji_events
                                        : Icons.sentiment_dissatisfied,
                                    size: 28,
                                    color: isWinner
                                        ? AppColors.success
                                        : AppColors.error),
                                const SizedBox(width: 12),
                                Text(
                                  isWinner ? 'Anda Menang!' : 'Tidak Berhasil',
                                  style: AppTextStyles.h4.copyWith(
                                      color: isWinner
                                          ? AppColors.success
                                          : AppColors.error,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.vintageCream.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  const Icon(Icons.gavel,
                                      color: AppColors.vintageGold),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tawaran Anda: ${ConversionHelper.formatConvertedCurrency((userBid as dynamic).hargaTawaran, currency)}',
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            if (highestBidData != null && !isWinner) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Pemenang menawar: ${ConversionHelper.formatConvertedCurrency((highestBidData as dynamic).hargaTawaran, currency)}',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.vintageCream.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                            color: AppColors.border.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                              'Harga Dasar',
                              ConversionHelper.formatConvertedCurrency(
                                  auction.minimumBid, currency)),
                          const Divider(height: 20),
                          _buildDetailRow(
                              'Waktu Lelang',
                              ConversionHelper.formatDateTime(
                                  auction.auctionDate, timezone)),
                          const Divider(height: 20),
                          _buildDetailRow('Lokasi', auction.location ?? '-'),
                        ],
                      ),
                    ),

                    if (auction.latitude != null && auction.longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text('Buka di Maps'),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.vintageBrown),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary))),
        Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.vintageBrown.withOpacity(0.9)))),
      ],
    );
  }
}
