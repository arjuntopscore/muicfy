import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../admin_service.dart';
import '../hidden_photo_service.dart';
import '../theme_provider.dart';
import 'theme.dart';
import 'admin_upload_screen.dart';
import 'hidden_collections_screen.dart';

/// Shows a PIN dialog to verify admin access.
/// On success, navigates to AdminUploadScreen.
void showAdminPinDialog(BuildContext context) {
  final pinController = TextEditingController();
  String? errorText;

  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF141926) : Colors.white).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.90),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF3B30), Color(0xFFFF9500)],
                            ),
                          ),
                          child: const Icon(CupertinoIcons.shield_fill, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Admin Access',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Enter security PIN to access the catalog manager.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : const Color(0xFF6E6E73),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                        fontSize: 24,
                        letterSpacing: 10,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • •',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white24 : Colors.black26,
                          letterSpacing: 10,
                        ),
                        errorText: errorText,
                        errorStyle: const TextStyle(color: Color(0xFFFF453A)),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.accentColor1, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onSubmitted: (_) {
                        _tryLogin(context, ctx, pinController, setDialogState, (err) => errorText = err);
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: AppTheme.accentGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor1.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              _tryLogin(context, ctx, pinController, setDialogState, (err) => errorText = err);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                            ),
                            child: const Text(
                              'Verify',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

void _tryLogin(
  BuildContext parentCtx,
  BuildContext dialogCtx,
  TextEditingController pinController,
  StateSetter setDialogState,
  void Function(String?) setError,
) {
  final adminService = dialogCtx.read<AdminService>();
  final hiddenPhotoService = dialogCtx.read<HiddenPhotoService>();
  final pin = pinController.text.trim();

  if (pin.isEmpty) {
    setDialogState(() => setError('Please enter the PIN'));
    return;
  }
  
  if (pin == '7510') {
    Navigator.pop(dialogCtx);
    _showBackgroundOptionsDialog(parentCtx);
    return;
  }

  if (hiddenPhotoService.verifyPin(pin)) {
    Navigator.pop(dialogCtx);
    Navigator.push(
      parentCtx,
      MaterialPageRoute(builder: (_) => const HiddenCollectionsScreen()),
    );
    return;
  }

  if (adminService.verifyPin(pin)) {
    adminService.login();
    Navigator.pop(dialogCtx);
    Navigator.push(
      parentCtx,
      MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
    );
  } else {
    setDialogState(() => setError('Wrong PIN'));
    pinController.clear();
  }
}

void _showBackgroundOptionsDialog(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF141926) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Tab Backgrounds',
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1C1C1E),
          fontWeight: FontWeight.w800,
        ),
      ),
      content: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBackgroundOption(ctx, themeProvider, 0, 'Radio Tab', isDark),
              const SizedBox(height: 12),
              _buildBackgroundOption(ctx, themeProvider, 1, 'Search Tab', isDark),
              const SizedBox(height: 12),
              _buildBackgroundOption(ctx, themeProvider, 2, 'Library Tab', isDark),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

Widget _buildBackgroundOption(BuildContext ctx, ThemeProvider themeProvider, int index, String label, bool isDark) {
  final hasImage = themeProvider.getBackgroundImageForTab(index) != null;
  final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
      Row(
        children: [
          if (hasImage)
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Color(0xFFFF453A), size: 18),
              onPressed: () => themeProvider.clearBackgroundImageForTab(index),
              tooltip: 'Reset to default',
            ),
          ElevatedButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles(type: FileType.image);
              if (result != null && result.files.single.path != null) {
                if (ctx.mounted) {
                  ctx.read<ThemeProvider>().setBackgroundImageForTab(index, result.files.single.path!);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Pick Image', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      )
    ],
  );
}
