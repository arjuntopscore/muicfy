import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../admin_service.dart';
import '../hidden_photo_service.dart';
import '../theme_provider.dart';
import 'admin_upload_screen.dart';
import 'hidden_collections_screen.dart';

/// Shows a PIN dialog to verify admin access.
/// On success, navigates to AdminUploadScreen.
void showAdminPinDialog(BuildContext context) {
  final pinController = TextEditingController();
  String? errorText;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF282828),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Color(0xFFFF6B6B), size: 24),
              SizedBox(width: 8),
              Text('Admin Access', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter admin PIN to access the catalog manager.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              SizedBox(height: 16),
              TextField(
                controller: pinController,
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • •',
                  hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                  errorText: errorText,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  filled: true,
                  fillColor: const Color(0xFF404040),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (_) {
                  _tryLogin(context, ctx, pinController, setDialogState, (err) => errorText = err);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                _tryLogin(context, ctx, pinController, setDialogState, (err) => errorText = err);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              child: Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
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
    Navigator.pop(dialogCtx); // Close PIN dialog
    _showBackgroundOptionsDialog(parentCtx);
    return;
  }

  // Check for hidden gallery secret PIN first
  if (hiddenPhotoService.verifyPin(pin)) {
    Navigator.pop(dialogCtx); // Close dialog
    Navigator.push(
      parentCtx,
      MaterialPageRoute(builder: (_) => const HiddenCollectionsScreen()),
    );
    return;
  }

  if (adminService.verifyPin(pin)) {
    adminService.login();
    Navigator.pop(dialogCtx); // Close dialog
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
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF282828),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Background Settings', style: TextStyle(color: Colors.white)),
      content: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBackgroundOption(ctx, themeProvider, 0, 'Home Tab'),
              const SizedBox(height: 12),
              _buildBackgroundOption(ctx, themeProvider, 1, 'Search Tab'),
              const SizedBox(height: 12),
              _buildBackgroundOption(ctx, themeProvider, 2, 'Library Tab'),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close', style: TextStyle(color: Colors.white54)),
        ),
      ],
    ),
  );
}

Widget _buildBackgroundOption(BuildContext ctx, ThemeProvider themeProvider, int index, String label) {
  final hasImage = themeProvider.getBackgroundImageForTab(index) != null;

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      Row(
        children: [
          if (hasImage)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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
              backgroundColor: const Color(0xFFFF6B6B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Pick Image', style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      )
    ],
  );
}

