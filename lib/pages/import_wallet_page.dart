import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
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
  bool _showWords = false;

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
      final words = mnemonic.split(' ').where((word) => word.isNotEmpty).toList();
      if (words.length != 12) {
        setState(() {
          _errorMessage = 'Please enter exactly 12 words for ${widget.isDevice1 ? 'Device 1' : 'Device 2'}';
          _isLoading = false;
        });
        return;
      }

      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final deviceType = widget.isDevice1 ? 1 : 2;
      
      print('🔍 ImportWallet: Checking mnemonic for Device $deviceType...');
      print('🔍 Input words: "$mnemonic"');
      
      // Check if this mnemonic part exists in Firebase for the selected device
      final verificationResult = await walletProvider.verifyDeviceMnemonicPart(
        mnemonicPart: mnemonic,
        deviceType: deviceType,
      );

      if (verificationResult != null) {
        // Navigate to the login page, pass walletId and anything else needed
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
      print('💥 ImportWallet: Error: $e');
      setState(() {
        _errorMessage = 'Error verifying recovery phrase: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<String> _getWordsFromMnemonic() {
    final mnemonic = _mnemonicController.text.trim();
    if (mnemonic.isEmpty) return [];
    return mnemonic.split(' ').where((word) => word.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.isDevice1 ? 'Device 1' : 'Device 2';
    final deviceColor = widget.isDevice1 ? Colors.blue : Colors.purple;
    final wordRange = widget.isDevice1 ? 'Words 1-12' : 'Words 13-24';
    final wordNumbers = widget.isDevice1 ? '(First 12 words)' : '(Last 12 words)';
    
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: deviceColor),
                  const SizedBox(height: 16),
                  Text(
                    'Verifying your recovery words...',
                    style: TextStyle(color: deviceColor, fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12.0 : 16.0,
                    vertical: isSmallScreen ? 8.0 : 12.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Device Selection Header
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: deviceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: deviceColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              widget.isDevice1 ? Icons.phone_android : Icons.tablet_android,
                              size: isSmallScreen ? 40 : 48,
                              color: deviceColor,
                            ),
                            SizedBox(height: isSmallScreen ? 12 : 16),
                            Text(
                              'Import $deviceText',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              '$wordRange $wordNumbers',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                color: deviceColor.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              'Enter the recovery phrase for this device',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Instructions
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Important Instructions',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Text(
                              widget.isDevice1 
                                  ? '• Enter the FIRST 12 words (words 1-12) of your original 24-word recovery phrase\n'
                                    '• These are the words that were assigned to Device 1 during wallet creation\n'
                                    '• Make sure you have selected Device 1 above'
                                  : '• Enter the LAST 12 words (words 13-24) of your original 24-word recovery phrase\n'
                                    '• These are the words that were assigned to Device 2 during wallet creation\n'
                                    '• Make sure you have selected Device 2 above',
                              style: TextStyle(
                                color: Colors.blue.withOpacity(0.9),
                                fontSize: isSmallScreen ? 11 : 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Mnemonic Input Section
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$deviceText Recovery Words',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                    color: deviceColor,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _showWords = !_showWords;
                                    });
                                  },
                                  icon: Icon(
                                    _showWords ? Icons.visibility_off : Icons.visibility,
                                    color: deviceColor,
                                    size: 16,
                                  ),
                                  label: Text(
                                    _showWords ? 'Hide' : 'Show',
                                    style: TextStyle(color: deviceColor, fontSize: 12),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            TextField(
                              controller: _mnemonicController,
                              maxLines: 4,
                              obscureText: !_showWords,
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: _showWords 
                                    ? 'word1 word2 word3 word4 word5 word6 word7 word8 word9 word10 word11 word12'
                                    : 'Enter your 12 recovery words separated by spaces',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                  fontSize: 12,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.5),
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
                                  borderSide: BorderSide(color: deviceColor, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _errorMessage = '';
                                });
                              },
                            ),
                            
                            // Word count display
                            if (_mnemonicController.text.isNotEmpty) ...[
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Words entered: ${_getWordsFromMnemonic().length}/12',
                                    style: TextStyle(
                                      color: _getWordsFromMnemonic().length == 12 
                                          ? Colors.green 
                                          : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_getWordsFromMnemonic().length == 12)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Display entered words if visible
                      if (_showWords && _mnemonicController.text.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Words Preview:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 13 : 14,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _getWordsFromMnemonic().asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final word = entry.value;
                                  final wordNumber = widget.isDevice1 ? index + 1 : index + 13;
                                  
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: deviceColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: deviceColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      '$wordNumber. $word',
                                      style: TextStyle(
                                        color: deviceColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Error Message
                      if (_errorMessage.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline, 
                                color: Colors.red, 
                                size: isSmallScreen ? 18 : 20
                              ),
                              SizedBox(width: isSmallScreen ? 8 : 12),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red, 
                                    fontSize: isSmallScreen ? 12 : 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      SizedBox(height: isSmallScreen ? 20 : 24),
                      
                      // Verify Button
                      ElevatedButton(
                        onPressed: _getWordsFromMnemonic().length == 12 ? _importWallet : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getWordsFromMnemonic().length == 12 
                              ? deviceColor 
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: _getWordsFromMnemonic().length == 12 ? 4 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Text(
                              'Verify Recovery Words',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 20),
                      
                      // Security Warning
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.security,
                              color: Colors.amber,
                              size: isSmallScreen ? 18 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Security Reminder',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 12 : 13,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 4 : 6),
                                  Text(
                                    '• Never share your recovery words with anyone\n'
                                    '• Make sure you are in a secure location\n'
                                    '• Double-check you selected the correct device',
                                    style: TextStyle(
                                      color: Colors.amber.withOpacity(0.9),
                                      fontSize: isSmallScreen ? 10 : 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 20 : 30),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
