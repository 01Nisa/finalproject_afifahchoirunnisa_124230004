import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../services/geocoding_service.dart';
import '../../utils/constants.dart';
import '../../utils/conversion.dart';
import '../../models/auction_model.dart';

class AuctionDetailScreen extends StatefulWidget {
  final AuctionModel auction;
  const AuctionDetailScreen({required this.auction, super.key});

  @override
  State<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends State<AuctionDetailScreen> {
  final _authService = AuthService();
  final _userService = UserService();
  final _geocoding = GeocodingService();

  double? _lat;
  double? _lng;
  bool _isLoadingMap = true;
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _isLoadingMap = true;
      _mapError = null;
    });

    try {
      if (widget.auction.latitude != null && widget.auction.longitude != null) {
        setState(() {
          _lat = widget.auction.latitude;
          _lng = widget.auction.longitude;
          _isLoadingMap = false;
        });
        return;
      }

      final result = await _geocoding.geocode(widget.auction.location);
      if (!mounted) return;

      setState(() {
        _lat = result?['lat'];
        _lng = result?['lng'];
        _isLoadingMap = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMap = false;
        _mapError = 'Gagal memuat peta';
      });
    }
  }

  void _registerAuction() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.vintageGold),
      ),
    );

    final res = await _userService.registerAuction(
        userId: user.id, auction: widget.auction);

    if (!mounted) return;
    Navigator.pop(context); 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Berhasil'),
        backgroundColor:
            res['success'] == true ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );

    if (res['success'] == true) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshInterests(user.id);

      if (mounted) {
        setState(() {}); 
      }
    }
  }

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(widget.auction.location);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    final appleUrl = 'http://maps.apple.com/?q=$query';

    final uri = Uri.parse(Theme.of(context).platform == TargetPlatform.iOS
        ? appleUrl
        : googleUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka aplikasi peta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final currency = user?.defaultCurrency ?? AppConstants.defaultCurrency;
    final timezone = user?.defaultTimezone ?? AppConstants.defaultTimezone;

    final hasValidCoords = _lat != null && _lng != null;
    final hasApiKey = ApiConstants.googleApiKey != 'YOUR_GOOGLE_API_KEY_HERE' &&
        ApiConstants.googleApiKey.isNotEmpty;
    final canShowMap = hasValidCoords && hasApiKey;

    final mapUrl = canShowMap
        ? 'https://maps.googleapis.com/maps/api/staticmap?center=$_lat,$_lng&zoom=15&size=600x300&scale=2&markers=color:red%7C$_lat,$_lng&key=${ApiConstants.googleApiKey}'
        : null;

    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: AppBar(
        backgroundColor: AppColors.vintageCream,
        elevation: 0,
        title: Text(
          widget.auction.title,
          style: const TextStyle(
            color: AppColors.vintageBrown,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: 80), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.auction.primaryImageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: Image.network(
                      widget.auction.primaryImageUrl,
                      height: 280,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 280,
                          color: AppColors.surfaceVariant,
                          child: const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.vintageGold),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 280,
                        color: AppColors.surfaceVariant,
                        child: const Icon(Icons.broken_image,
                            size: 80, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 280,
                    width: double.infinity,
                    color: AppColors.surfaceVariant,
                    child:
                        const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.auction.title,
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.vintageBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Oleh: ${widget.auction.artist}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoCard(
                        icon: Icons.local_offer,
                        title: 'Harga Dasar',
                        value: ConversionHelper.formatConvertedCurrency(
                          widget.auction.minimumBid,
                          currency,
                        ),
                        valueColor: AppColors.vintageGold,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.access_time,
                        title: 'Waktu Lelang',
                        value: ConversionHelper.formatDateTime(
                          widget.auction.auctionDate,
                          timezone,
                        ),
                        valueColor: AppColors.vintageBrown,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.location_on,
                        title: 'Lokasi',
                        value: widget.auction.location,
                        valueColor: AppColors.vintageBrown,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Lokasi di Peta',
                        style: AppTextStyles.h4.copyWith(
                          color: AppColors.vintageBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          color: AppColors.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildMapWidget(mapUrl),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.vintageBg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Consumer2<AuthProvider, UserProvider>(
                builder: (context, authProvider, userProvider, child) {
                  final user = authProvider.currentUser;
                  final isRegistered = user != null &&
                      _userService.isAuctionRegistered(
                          user.id, widget.auction.id);

                  final now = DateTime.now();
                  final hasStarted = now.isAfter(widget.auction.auctionDate);
                  final endTime = widget.auction.auctionDate
                      .add(AppAnimations.auctionDuration);
                  final isFinished = now.isAfter(endTime);

                  if (isRegistered && !hasStarted) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelAuction,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.cancel_outlined, size: 20),
                        label: const Text(
                          'Batal Daftar',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }

                  if (isRegistered && hasStarted && !isFinished) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'Sudah Terdaftar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (isFinished) {
                    return ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.gavel, size: 20),
                      label: const Text(
                        'Lelang Telah Selesai',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: AppColors.textTertiary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }

                  return ElevatedButton.icon(
                    onPressed: _registerAuction,
                    icon: const Icon(Icons.gavel, size: 20),
                    label: const Text(
                      'Daftar Lelang',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vintageGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Future<void> _cancelAuction() async {
    final user = await _authService.getCurrentUser();
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

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

    if (!confirmed) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.vintageGold),
      ),
    );

    try {
      final interests = _userService.getRegisteredAuctions(user.id);
      final interest = interests.firstWhere(
        (i) => i.auctionId == widget.auction.id,
        orElse: () => throw Exception('Pendaftaran tidak ditemukan'),
      );

      await _userService.unregisterAuction(interest.id);

      if (!mounted) return;
      Navigator.pop(context); 

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.refreshInterests(user.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran lelang dibatalkan')),
      );

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membatalkan: ${e.toString()}')),
      );
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: valueColor ?? AppColors.vintageBrown, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.vintageBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapWidget(String? mapUrl) {
    if (_isLoadingMap) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.vintageGold),
      );
    }

    if (_mapError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 8),
            Text(_mapError!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.map, size: 16),
              label: const Text('Buka di Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vintageGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (mapUrl != null) {
      return Stack(
        children: [
          Image.network(
            mapUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.vintageGold));
            },
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surfaceVariant,
              child:
                  const Icon(Icons.map_outlined, size: 48, color: Colors.grey),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: ElevatedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.directions, size: 16),
              label: const Text('Buka Maps', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vintageGold,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 48, color: AppColors.vintageBrown),
          const SizedBox(height: 8),
          Text(
            widget.auction.location,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.vintageBrown),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _openInMaps,
            icon: const Icon(Icons.map, size: 16),
            label: const Text('Buka di Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vintageGold,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
