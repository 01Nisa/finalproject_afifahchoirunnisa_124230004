import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../services/user_service.dart';
import '../../utils/constants.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _category = 'default';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _setDefaultFeedback();
  }

  void _setDefaultFeedback() {
    _subjectController.text = 'Kesan Mata Kuliah Pemrograman Aplikasi Mobile';
    _messageController.text =
        'Mata kuliah ini memberikan banyak pengalaman baru, tetapi cukup menantang.';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Silakan login')));
    }

    return Scaffold(
      backgroundColor: AppColors.vintageBg,
      appBar: AppBar(
        backgroundColor: AppColors.vintageCream,
        elevation: 0,
        title: const Text(
          'Saran & Kesan',
          style: TextStyle(
            color: Colors.black, 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black, 
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'default',
                    label: Text('Kesan Permanen'),
                    icon: Icon(Icons.star_outline, size: 16),
                  ),
                  ButtonSegment(
                    value: 'suggestion',
                    label: Text('Tambahkan'),
                    icon: Icon(Icons.feedback_outlined, size: 16),
                  ),
                ],
                selected: <String>{_category},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _category = newSelection.first;
                    if (_category == 'default') {
                      _setDefaultFeedback();
                    } else {
                      _subjectController.clear();
                      _messageController.clear();
                    }
                  });
                },
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.black,
                  selectedForegroundColor: Colors.white,
                  backgroundColor: Colors.grey[200],
                  selectedBackgroundColor: AppColors.vintageGold,
                ),
              ),

              const SizedBox(height: 20),

              if (_category == 'default')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.vintageGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.vintageGold),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.vintageGold, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Saran default tidak dapat diubah atau dikirim. Gunakan "Masukkan Saran" untuk menulis sendiri.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black, 
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _subjectController,
                readOnly: _category == 'default',
                enabled: _category != 'default',
                maxLength: 100, 
                decoration: InputDecoration(
                  labelText: 'Subjek',
                  labelStyle: const TextStyle(color: Colors.black),
                  hintText: _category == 'default'
                      ? 'Tidak dapat diubah'
                      : 'Masukkan subjek...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: _category == 'default',
                  fillColor: _category == 'default'
                      ? AppColors.vintageCream.withOpacity(0.5)
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  counterText: _category == 'suggestion'
                      ? null
                      : '', 
                ),
                style: const TextStyle(color: Colors.black), 
                validator: _category == 'suggestion'
                    ? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null
                    : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _messageController,
                readOnly: _category == 'default',
                enabled: _category != 'default',
                maxLines: 5,
                maxLength: 500, 
                decoration: InputDecoration(
                  labelText: 'Pesan',
                  labelStyle: const TextStyle(color: Colors.black),
                  hintText: _category == 'default'
                      ? 'Tidak dapat diubah'
                      : 'Tulis pesan Anda...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: _category == 'default',
                  fillColor: _category == 'default'
                      ? AppColors.vintageCream.withOpacity(0.5)
                      : null,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  counterText: _category == 'suggestion' ? null : '',
                ),
                style: const TextStyle(color: Colors.black), 
                validator: _category == 'suggestion'
                    ? (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null
                    : null,
              ),

              const SizedBox(height: 24),

              if (_category == 'suggestion')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;

                            setState(() => _submitting = true);

                            final res = await _userService.submitFeedback(
                              userId: user.id,
                              userName: user.name,
                              category: _category,
                              subject: _subjectController.text.trim(),
                              message: _messageController.text.trim(),
                              rating: 5,
                            );

                            if (!mounted) return;
                            setState(() => _submitting = false);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message'] ?? 'Terkirim',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: res['success'] == true
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );

                            if (res['success'] == true) {
                              _subjectController.clear();
                              _messageController.clear();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vintageGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Kirim',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
