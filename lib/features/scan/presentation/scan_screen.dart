import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skindisease/features/scan/data/predict_service.dart';
import 'package:skindisease/features/scan/presentation/result_screen.dart';
import 'package:skindisease/features/history/data/firebase_history_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final PredictService _predictService = PredictService();
  final FirebaseHistoryService _historyService = FirebaseHistoryService();

  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _selectedImage = File(picked.path));
    await _runPredict();
  }

  Future<void> _runPredict() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Step 1: Prediksi dulu (tidak butuh internet)
      final result = await _predictService.predictSkinDisease(_selectedImage!);

      // ✅ Step 2: Simpan ke Firestore dengan timeout 5 detik
      try {
        await _historyService
            .saveHistory(
          label: result.label,
          confidence: result.confidence,
          imageUrl: _selectedImage!.path,
        )
            .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint(
                '⚠️ Firestore timeout — history tidak tersimpan, lanjut ke hasil');
          },
        );
      } catch (firestoreError) {
        debugPrint('⚠️ Firestore error (diabaikan): $firestoreError');
      }

      // ✅ Step 3: Navigasi ke hasil
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: _selectedImage!,
            label: result.label,
            confidence: result.confidence,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal prediksi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);
    const softBg = Color(0xFFF2F7F3);

    return Scaffold(
      backgroundColor: softBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Custom header
              Row(
                children: [
                  Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child:
                            Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Scan Your Skin',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A2B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: primaryGreen,
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Image preview area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: primaryGreen.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _selectedImage == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    size: 48,
                                    color: primaryGreen.withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Choose a skin photo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E3A2B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Take a photo or pick from gallery\nfor skin disease analysis',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Loading indicator
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation(primaryGreen),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Analyzing image...',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      isPrimary: true,
                      onTap: _isLoading
                          ? null
                          : () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      isPrimary: false,
                      onTap: _isLoading
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);

    return Material(
      color: isPrimary ? primaryGreen : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: isPrimary ? 4 : 0,
      shadowColor: primaryGreen.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isPrimary
                ? null
                : Border.all(color: primaryGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isPrimary ? Colors.white : primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? Colors.white : primaryGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}