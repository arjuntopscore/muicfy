import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Spotify Colors
  static const Color bgColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF282828);
  static const Color accentColor1 = Color(0xFF1DB954); // Spotify Green
  static const Color accentColor2 = Color(0xFF1ED760); // Lighter Green
  
  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentColor1, accentColor2],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      primaryColor: accentColor1,
      
      // Spotify uses Circular, we can use a similar clean sans-serif like Montserrat or just Inter
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
        displaySmall: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: const Color(0xFFB3B3B3), // Spotify secondary text color
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          color: const Color(0xFFB3B3B3),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black, // Spotify bottom nav is pitch black
        selectedItemColor: Colors.white,
        unselectedItemColor: Color(0xFFB3B3B3),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 10),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor1,
        inactiveTrackColor: Colors.grey.shade800,
        thumbColor: Colors.white,
        overlayColor: accentColor1.withOpacity(0.2),
      ),
    );
  }
}
