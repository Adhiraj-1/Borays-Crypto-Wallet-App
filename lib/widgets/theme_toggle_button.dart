import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/theme_provider.dart';
import 'package:web3_wallet/theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return GestureDetector(
      onTap: () {
        themeProvider.toggleTheme();
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isDarkMode ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                Colors.white.withOpacity(0.9),
                Colors.black.withOpacity(0.7),
                value,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.lerp(
                    Colors.black.withOpacity(0.1),
                    AppTheme.neonGreen.withOpacity(0.3),
                    value,
                  )!,
                  blurRadius: 8 + (value * 4),
                  spreadRadius: 1 + value,
                ),
              ],
              border: Border.all(
                color: Color.lerp(
                  Colors.grey.withOpacity(0.3),
                  AppTheme.neonGreen.withOpacity(0.5),
                  value,
                )!,
                width: 1 + value,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sun icon
                Opacity(
                  opacity: 1 - value,
                  child: Transform.rotate(
                    angle: value * 0.5,
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      color: Color.lerp(
                        Colors.orange,
                        Colors.transparent,
                        value,
                      ),
                      size: 24,
                    ),
                  ),
                ),
                // Moon icon
                Opacity(
                  opacity: value,
                  child: Transform.rotate(
                    angle: (1 - value) * 0.5,
                    child: Icon(
                      Icons.nightlight_round,
                      color: Color.lerp(
                        Colors.transparent,
                        AppTheme.neonGreen,
                        value,
                      ),
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
