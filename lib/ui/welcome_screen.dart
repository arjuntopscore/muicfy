import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    setState(() => _userName = name);

    // Save the username
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);

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
      backgroundColor: AppTheme.bgColor,
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
            Color(0xFF1A3A2A),
            AppTheme.bgColor,
            Color(0xFF0A0A0A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                  const SizedBox(height: 60),

              // Logo / Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.accentColor1,
                      AppTheme.accentColor2,
                      AppTheme.accentColor1.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentColor1.withValues(alpha: 0.35),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note_rounded, color: Colors.black, size: 40),
              ),

              const SizedBox(height: 40),

              // Title
              Text(
                'Welcome to',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.accentColor1, AppTheme.accentColor2, Color(0xFF4ADE80)],
                ).createShader(bounds),
                child: Text(
                  'musicfy',
                  style: GoogleFonts.montserrat(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Subtitle
              Text(
                "What should we call you?",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your name to personalise your experience",
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFFB3B3B3),
                ),
              ),

              const SizedBox(height: 28),

              // Name input field
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppTheme.surfaceColor,
                  border: Border.all(
                    color: AppTheme.accentColor1.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Your name',
                    hintStyle: GoogleFonts.montserrat(
                      color: Colors.white30,
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 16, right: 8),
                      child: Icon(Icons.person_outline_rounded, color: AppTheme.accentColor1, size: 24),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => _goToNextPage(),
                ),
              ),

              const SizedBox(height: 32),

              // Arrow button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _goToNextPage,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentColor1, AppTheme.accentColor2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor1.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 30),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Page indicator
              _buildPageIndicator(),
              const SizedBox(height: 32),
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
            Color(0xFF1DB954),
            Color(0xFF14843C),
            Color(0xFF0D1B12),
            AppTheme.bgColor,
          ],
          stops: [0.0, 0.25, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
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
              const Spacer(flex: 2),

              // Greeting
              Text(
                'Hey,',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_userName! 👋',
                style: GoogleFonts.montserrat(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Introduction
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentColor1.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.waving_hand_rounded, color: AppTheme.accentColor1, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'From Arjun',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "I'm Arjun, and I built musicfy just for music lovers like you. "
                      "This is your personal music space — stream songs, save your favorites with a single tap, "
                      "download tracks for offline playback, and track your listening habits with your Music Wrapped dashboard.",
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Feature highlights
              _buildFeatureRow(Icons.search_rounded, 'Search & stream millions of songs'),
              const SizedBox(height: 14),
              _buildFeatureRow(Icons.download_rounded, 'Download songs for offline playback'),
              const SizedBox(height: 14),
              _buildFeatureRow(Icons.bar_chart_rounded, 'Track stats with Music Wrapped dashboard'),
              const SizedBox(height: 14),
              _buildFeatureRow(Icons.favorite_rounded, 'Save favorites & upload local music'),

              const Spacer(flex: 2),

              // Get Started button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                    shadowColor: Colors.black54,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Let's Go, $_userName!",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Page indicator
              _buildPageIndicator(),
              const SizedBox(height: 32),
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.accentColor1.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: AppTheme.accentColor1, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.montserrat(
              fontSize: 14,
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
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? AppTheme.accentColor1 : Colors.white24,
          ),
        );
      }),
    );
  }
}
