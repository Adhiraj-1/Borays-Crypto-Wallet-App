import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'set_passwords_page.dart';
import 'login_page.dart';

class ImportWalletPage extends StatefulWidget {
  final bool isDevice1;

  const ImportWalletPage({Key? key, required this.isDevice1}) : super(key: key);

  @override
  State<ImportWalletPage> createState() => _ImportWalletPageState();
}

class _ImportWalletPageState extends State<ImportWalletPage> {
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }

  Future<void> _importWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final mnemonic = _mnemonicController.text.trim();
      if (mnemonic.isEmpty) {
        setState(() {
          _errorMessage = 'Please enter your recovery phrase';
          _isLoading = false;
        });
        return;
      }

      // Count words
      final wordCount = mnemonic.split(' ').length;
      if (wordCount != 12) {
        setState(() {
          _errorMessage = 'Please enter exactly 12 words';
          _isLoading = false;
        });
        return;
      }

      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    
      // Set the device type
      walletProvider.setDeviceType(widget.isDevice1);
    
      // Use the new verification function
      final deviceType = widget.isDevice1 ? 1 : 2;
      final verificationResult = await walletProvider.verifyDeviceMnemonicPart(
        mnemonicPart: mnemonic,
        deviceType: deviceType,
      );
    
      if (verificationResult != null) {
        // Navigate to the login page, pass walletId and other needed params
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(
              walletId: verificationResult['walletId'],
              deviceType: deviceType,
              mnemonicPart: mnemonic,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Wallet not found. Please check your recovery words.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error importing wallet: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.isDevice1 ? 'Device 1' : 'Device 2';
    final deviceColor = widget.isDevice1 ? Colors.blue : Colors.purple;
    final wordRange = widget.isDevice1 ? '1-12' : '13-24';
    
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      appBar: AppBar(
        title: Text('Import $deviceText'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
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
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 
                               AppBar().preferredSize.height - 
                               MediaQuery.of(context).padding.top,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12.0 : 16.0,
                      vertical: isSmallScreen ? 8.0 : 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: deviceColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: deviceColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                widget.isDevice1 ? Icons.phone_android : Icons.tablet_android,
                                size: isSmallScreen ? 32 : 40,
                                color: deviceColor,
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                '$deviceText Recovery Phrase',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: deviceColor,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                'Enter the $deviceText recovery phrase (Words $wordRange)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        
                        Text(
                          widget.isDevice1 
                              ? 'Enter the first 12 words (words 1-12) of your 24-word recovery phrase:'
                              : 'Enter the last 12 words (words 13-24) of your 24-word recovery phrase:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: deviceColor.withOpacity(0.5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$deviceText Recovery Phrase (Words $wordRange)',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: deviceColor,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              TextField(
                                controller: _mnemonicController,
                                maxLines: 3,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'word1 word2 word3 ... word12',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  filled: true,
                                  fillColor: Colors.black,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: deviceColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: isSmallScreen ? 8.0 : 12.0),
                            child: Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline, 
                                    color: Colors.red, 
                                    size: isSmallScreen ? 16 : 18
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: TextStyle(
                                        color: Colors.red, 
                                        fontSize: isSmallScreen ? 12 : 14
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
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
                                size: isSmallScreen ? 16 : 18,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Expanded(
                                child: Text(
                                  'Never share your recovery phrase with anyone. Make sure you are in a secure location when entering it.',
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: isSmallScreen ? 11 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        
                        ElevatedButton(
                          onPressed: _importWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deviceColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Verify Recovery Phrase',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Important Information',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                'After setting up $deviceText, your wallet setup will be complete if ${widget.isDevice1 ? 'Device 2' : 'Device 1'} has already been set up.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 11 : 12,
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
