import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'device_specific_verify_page.dart';

class GenerateMnemonicPage extends StatefulWidget {
  const GenerateMnemonicPage({
    Key? key,
  }) : super(key: key);

  @override
  _GenerateMnemonicPageState createState() => _GenerateMnemonicPageState();
}

class _GenerateMnemonicPageState extends State<GenerateMnemonicPage> {
  String _fullMnemonic = '';
  bool _isLoading = true;
  bool _isMnemonicVisible = true;
  bool _hasConfirmedSaved = false;
  Map<String, String> _splitMnemonic = {};
  
  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid calling setState during build
    Future.microtask(() => _generateMnemonic());
  }
  
  Future<void> _generateMnemonic() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasConfirmedSaved = false;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Generate a 24-word mnemonic (256 bits)
      final mnemonic = walletProvider.generateMnemonic(strength: 256); // 256 bits = 24 words
      
      // Split the mnemonic into two parts
      final splitParts = walletProvider.splitMnemonic(mnemonic);
      
      if (!mounted) return;
      
      setState(() {
        _fullMnemonic = mnemonic;
        _splitMnemonic = splitParts;
        _isLoading = false;
      });
      
      // Store the full mnemonic in the provider for later use
      await walletProvider.initializeWalletCreation(_fullMnemonic);
      
      print('Generated full mnemonic: $_fullMnemonic');
      print('Device 1 words: ${_splitMnemonic['device1']}');
      print('Device 2 words: ${_splitMnemonic['device2']}');
    } catch (e) {
      print('Error generating mnemonic: $e');
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate recovery phrase: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _fullMnemonic));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Full recovery phrase copied to clipboard'),
        backgroundColor: Colors.black,
      ),
    );
  }
  
  void _startDeviceSetup() {
    // Start with Device 1 verification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceSpecificVerifyPage(
          mnemonic: _splitMnemonic['device1']!,
          deviceMnemonic: _splitMnemonic['device1']!,
          isDevice1: true,
          wordIndexRange: WordIndexRange(0, 11), // 0-11 for first 12 words
          fullMnemonic: _fullMnemonic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert mnemonic to a list of words for better display
    final List<String> allWords = _fullMnemonic.isNotEmpty ? _fullMnemonic.split(' ') : [];
    final List<String> firstHalf = allWords.isNotEmpty ? allWords.take(12).toList() : [];
    final List<String> secondHalf = allWords.length > 12 ? allWords.skip(12).take(12).toList() : [];
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('BORAYS Crypto Wallet Recovery Phrase'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Complete 24-Word Recovery Phrase Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Complete 24-Word Recovery Phrase',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            const Text(
                              'This is your complete 24-word recovery phrase. It will be split between two devices for enhanced security.',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Full mnemonic display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: _isMnemonicVisible && allWords.isNotEmpty
                                ? _buildFullWordGrid(allWords)
                                : const Center(
                                    child: Text(
                                      '••••••••••••••••••••••••••••••••••••••••••••••••',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Toggle visibility and copy buttons for full phrase
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _isMnemonicVisible = !_isMnemonicVisible;
                                    });
                                  },
                                  icon: Icon(
                                    _isMnemonicVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.green,
                                  ),
                                  label: Text(
                                    _isMnemonicVisible ? 'Hide' : 'Show',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.green, width: 0.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                TextButton.icon(
                                  onPressed: _copyToClipboard,
                                  icon: const Icon(Icons.copy, color: Colors.green),
                                  label: const Text(
                                    'Copy All',
                                    style: TextStyle(color: Colors.green),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: const BorderSide(color: Colors.green, width: 0.5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Device 1 Words Section (1-12)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Device 1 Words (1-12)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            const Text(
                              'These are the first 12 words that will be stored on Device 1.',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Device 1 words display
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.5)),
                              ),
                              child: _isMnemonicVisible && firstHalf.isNotEmpty
                                ? _buildWordGrid(firstHalf, 0)
                                : const Center(
                                    child: Text(
                                      '••••••••••••••••••••••••',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Device 2 Words Section (13-24)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Device 2 Words (13-24)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          const Text(
                            'These are the last 12 words that will be stored on Device 2.',
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Device 2 words display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.withOpacity(0.5)),
                            ),
                            child: _isMnemonicVisible && secondHalf.isNotEmpty
                                ? _buildWordGrid(secondHalf, 12)
                                : const Center(
                                    child: Text(
                                      '••••••••••••••••••••••••',
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Warning Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Important Security Warning',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '• Never share your recovery phrase with anyone\n'
                            '• Store it in a secure, offline location\n'
                            '• We will never ask for your recovery phrase\n'
                            '• If you lose your recovery phrase, you lose access to your wallet',
                            style: TextStyle(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: _hasConfirmedSaved,
                            onChanged: (value) {
                              setState(() {
                                _hasConfirmedSaved = value ?? false;
                              });
                            },
                            title: const Text(
                              'I have written down my recovery phrase',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            checkColor: Colors.black,
                            activeColor: Colors.green,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Continue button
                    ElevatedButton(
                      onPressed: _hasConfirmedSaved ? _startDeviceSetup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.green.withOpacity(0.3),
                      ),
                      child: const Text(
                        'Start Wallet Setup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Regenerate button
                    TextButton.icon(
                      onPressed: _generateMnemonic,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        'Generate New Recovery Phrase',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
  
  Widget _buildFullWordGrid(List<String> words) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${index + 1}.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  words[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildWordGrid(List<String> words, int startIndex) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: words.length,
      itemBuilder: (context, index) {
        final wordIndex = startIndex + index;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${wordIndex + 1}.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  words[index],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
