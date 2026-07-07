import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver/theme/neon_theme_extension.dart';
import 'package:taxi_driver/utils/Colors.dart';
import 'package:taxi_driver/utils/Extensions/extension.dart';

class AppTheme {
  //
  AppTheme._();

  static final ThemeData lightTheme = ThemeData(
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: neonAccent,
      selectionHandleColor: neonAccent,
      selectionColor: neonAccent.withOpacity(0.35),
    ),
    primarySwatch: createMaterialColor(neonAccent),
    primaryColor: neonAccent,
    scaffoldBackgroundColor: scaffoldColorLight,
    fontFamily: GoogleFonts.play().fontFamily ?? 'Roboto',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neonBackground,
      selectedItemColor: neonAccent,
      unselectedItemColor: neonHighlight.withOpacity(0.55),
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(color: neonOnAccent),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: neonOnAccent, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: neonOnAccent),
      bodyMedium: TextStyle(color: neonOnAccent),
    ),
    dialogBackgroundColor: scaffoldColorLight,
    unselectedWidgetColor: neonOnAccent.withOpacity(0.6),
    dividerColor: dividerColor,
    cardColor: scaffoldColorLight,
    dialogTheme: DialogThemeData(shape: dialogShape()),
    colorScheme: ColorScheme.light(
      primary: neonAccent,
      onPrimary: neonOnAccent,
      secondary: neonHighlight,
      onSecondary: neonOnAccent,
      surface: scaffoldColorLight,
      onSurface: neonOnAccent,
      error: neonError,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      // Opción 4: AppBar un tono más “card” que el fondo + borde acento sutil.
      backgroundColor: neonSurfaceCard,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: neonAccent.withOpacity(0.45), width: 1),
      ),
      iconTheme: IconThemeData(color: neonHighlight),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.play().fontFamily ?? 'Roboto',
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      NeonThemeExtension.light,
    ],
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: neonAccent,
      selectionHandleColor: neonAccent,
      selectionColor: neonAccent.withOpacity(0.35),
    ),
    primarySwatch: createMaterialColor(neonAccent),
    primaryColor: neonAccent,
    scaffoldBackgroundColor: scaffoldColorDark,
    fontFamily: GoogleFonts.nunito().fontFamily ?? 'Roboto',
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: neonBackground,
      selectedItemColor: neonAccent,
      unselectedItemColor: neonHighlight.withOpacity(0.55),
      type: BottomNavigationBarType.fixed,
    ),
    iconTheme: IconThemeData(color: neonHighlight),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: neonHighlight),
    ),
    dialogBackgroundColor: scaffoldSecondaryDark,
    unselectedWidgetColor: neonHighlight.withOpacity(0.5),
    dividerColor: neonAccent.withOpacity(0.22),
    cardColor: scaffoldSecondaryDark,
    dialogTheme: DialogThemeData(shape: dialogShape()),
    colorScheme: ColorScheme.dark(
      primary: neonAccent,
      onPrimary: neonOnAccent,
      secondary: neonHighlight,
      onSecondary: neonOnAccent,
      surface: scaffoldSecondaryDark,
      onSurface: Colors.white,
      error: neonError,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: neonSurfaceCard,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: neonAccent.withOpacity(0.45), width: 1),
      ),
      iconTheme: IconThemeData(color: neonHighlight),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: GoogleFonts.nunito().fontFamily ?? 'Roboto',
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    extensions: const <ThemeExtension<dynamic>>[
      NeonThemeExtension.dark,
    ],
  ).copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: OpenUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
