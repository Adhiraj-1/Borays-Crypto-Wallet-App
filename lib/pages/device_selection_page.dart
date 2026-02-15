import 'package:flutter/material.dart';
import 'package:web3_wallet/pages/import_wallet.dart';
import 'package:web3_wallet/theme/app_theme.dart';

class DeviceSelectionPage extends StatelessWidget {
  final bool isImporting;
  
  const DeviceSelectionPage({
    Key? key,
    this.isImporting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isImporting ? 'Select Device to Import' : 'Select Device'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              AppTheme.darkBackgroundSecondary,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           AppBar().preferredSize.height - 
                           MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.devices,
                            size: isSmallScreen ? 40 : 48,
                            color: AppTheme.neonGreen,
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Text(
                            isImporting 
                                ? 'Which device are you importing?' 
                                : 'Select Your Device',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            isImporting
                                ? 'You\'ll need to provide the correct 12-word recovery phrase for this device.'
                                : 'Your wallet requires two devices for maximum security.',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Device 1 Card
                    GestureDetector(
                      onTap: () {
                        if (isImporting) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImportWalletPage(isDevice1: true),
                            ),
                          );
                        } else {
                          // Handle non-import case if needed
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: isSmallScreen ? 40 : 48,
                              color: Colors.blue,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Device 1',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Words 1-12',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Primary device that stores the first half of your recovery phrase',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Device 2 Card
                    GestureDetector(
                      onTap: () {
                        if (isImporting) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ImportWalletPage(isDevice1: false),
                            ),
                          );
                        } else {
                          // Handle non-import case if needed
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purple.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.tablet_android,
                              size: isSmallScreen ? 40 : 48,
                              color: Colors.purple,
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Device 2',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Words 13-24',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              'Secondary device that stores the second half of your recovery phrase',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Security Info
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: isSmallScreen ? 18 : 24,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Text(
                              'You\'ll need both devices to fully access and manage your wallet.',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Add bottom padding to prevent overflow
                    SizedBox(height: isSmallScreen ? 20 : 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
