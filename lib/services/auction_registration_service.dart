class AuctionRegistrationService {
  static final AuctionRegistrationService _instance =
      AuctionRegistrationService._internal();
  factory AuctionRegistrationService() => _instance;
  AuctionRegistrationService._internal();

  Future<Map<String, dynamic>> registerToAuction({
    required String userId,
    required String auctionId,
  }) async {
    return {
      'success': false,
      'message':
          'Supabase integration removed. Use local registration via UserService.',
    };
  }

  Future<void> unregisterFromAuction({
    required String userId,
    required String auctionId,
  }) async {}

  Future<void> syncRegistrationsToLocal({
    required String userId,
    required Function(dynamic) onLocalSave,
  }) async {}
}
