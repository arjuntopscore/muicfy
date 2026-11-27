import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../music_provider.dart';
import 'theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const WelcomeScreen({super.key, required this.onComplete});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  String _userName = '';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() => _userName = name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);

    if (mounted) {
      final provider = context.read<MusicProvider>();
      provider.userName = name;
      provider.preloadHomeData();
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          _buildNamePage(),
          _buildGreetingPage(),
        ],
      ),
    );
  }

  // ─── Page 1: Ask Username ───────────────────────────────────────────

  Widget _buildNamePage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF200A18),
            Color(0xFF0F1420),
            Colors.black,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Glowing App Icon
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: AppTheme.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor1.withValues(alpha: 0.45),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(CupertinoIcons.music_note_2, color: Colors.white, size: 38),
                    ),
                  ),

                  const SizedBox(height: 36),

                  Text(
                    'Welcome to',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFA2D48), Color(0xFFFF375F), Color(0xFF5E5CE6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      'Pattufy',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "What should we call you?",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Enter your name to personalize your radio and playback mix",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name input field with frosted glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.35),
                              fontSize: 17,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 10),
                              child: Icon(CupertinoIcons.person_fill, color: AppTheme.accentColor1, size: 22),
                            ),
                          ),
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _goToNextPage(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _goToNextPage,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.accentGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor1.withValues(alpha: 0.45),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 26),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  _buildPageIndicator(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Page 2: Greeting & Introduction ────────────────────────────────

  Widget _buildGreetingPage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2E0D1B),
            Color(0xFF131726),
            Color(0xFF07090F),
            Colors.black,
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  Text(
                    'Hey,',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_userName! ✨',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Introduction Card with Frosted Glass
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.accentColor1.withValues(alpha: 0.25),
                                  ),
                                  child: const Icon(CupertinoIcons.sparkles, color: AppTheme.accentColor1, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Pattufy Music Experience',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.accentColor1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Welcome to your personal high-fidelity music space. "
                              "Stream endless songs with lossless audio, generate AI vibe playlists with Gemini, "
                              "download offline tracks, and experience Apple Music-grade design.",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                height: 1.55,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Feature Highlights
                  _buildFeatureRow(CupertinoIcons.search, 'Search & stream millions of songs with Hi-Res Lossless'),
                  const SizedBox(height: 14),
                  _buildFeatureRow(CupertinoIcons.sparkles, 'Gemini AI intelligent vibe playlists & semantic search'),
                  const SizedBox(height: 14),
                  _buildFeatureRow(CupertinoIcons.arrow_down_circle_fill, 'Offline storage for listening on the go'),
                  const SizedBox(height: 14),
                  _buildFeatureRow(CupertinoIcons.chart_bar_alt_fill, 'Real-time Wrapped listening statistics'),

                  const Spacer(flex: 2),

                  // Get Started button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: AppTheme.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor1.withValues(alpha: 0.45),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _finishOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Let's Go, $_userName!",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(CupertinoIcons.arrow_right, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildPageIndicator(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.accentColor1.withValues(alpha: 0.16),
            border: Border.all(
              color: AppTheme.accentColor1.withValues(alpha: 0.25),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: AppTheme.accentColor1, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppTheme.accentColor1 : Colors.white.withValues(alpha: 0.2),
          ),
        );
      }),
    );
  }
}
