import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../admin_service.dart';
import 'admin_upload_screen.dart';

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
                  _tryLogin(ctx, pinController, setDialogState, (err) => errorText = err);
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
                _tryLogin(ctx, pinController, setDialogState, (err) => errorText = err);
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
  BuildContext ctx,
  TextEditingController pinController,
  StateSetter setDialogState,
  void Function(String?) setError,
) {
  final adminService = ctx.read<AdminService>();
  final pin = pinController.text.trim();

  if (pin.isEmpty) {
    setDialogState(() => setError('Please enter the PIN'));
    return;
  }

  if (adminService.verifyPin(pin)) {
    adminService.login();
    Navigator.pop(ctx); // Close dialog
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => const AdminUploadScreen()),
    );
  } else {
    setDialogState(() => setError('Wrong PIN'));
    pinController.clear();
  }
}

