import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  String _currency = AppConstants.defaultCurrency;
  String _timezone = AppConstants.defaultTimezone;
  bool _notificationsEnabled = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      _currency = user.defaultCurrency;
      _timezone = user.defaultTimezone;
      _notificationsEnabled = user.notificationsEnabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mata Uang Default'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              items: CurrencyConstants.availableCurrencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 16),
            const Text('Zona Waktu Default'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _timezone,
              items: TimezoneConstants.availableTimezones
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _timezone = v ?? _timezone),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nyalakan Notifikasi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _notificationsEnabled
                          ? 'Notifikasi diaktifkan'
                          : 'Notifikasi dinonaktifkan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                  activeThumbColor: AppColors.vintageGold,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const SizedBox.shrink(),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final res = await _userService.updatePreferences(
                          userId: user.id,
                          defaultCurrency: _currency,
                          defaultTimezone: _timezone,
                          notificationsEnabled: _notificationsEnabled,
                        );

                        if (!mounted) return;
                        setState(() => _saving = false);

                        if (res['success'] == true) {
                          Provider.of<AuthProvider>(context, listen: false)
                              .updateUser(res['user']);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Preferensi diperbarui')),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? 'Gagal')),
                          );
                        }
                      },
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
