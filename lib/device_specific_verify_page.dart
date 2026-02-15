import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:web3_wallet/pages/set_device_passwords_page.dart';

class WordIndexRange {
  final int start;
  final int end;
  
  WordIndexRange(this.start, this.end);
}

class DeviceSpecificVerifyPage extends StatefulWidget {
  final String mnemonic;
  final String deviceMnemonic;
  final bool isDevice1;
  final WordIndexRange wordIndexRange;
  
  const DeviceSpecificVerifyPage({
    Key? key,
    required this.mnemonic,
    required this.deviceMnemonic,
    required this.isDevice1,
    required this.wordIndexRange,
  }) : super(key: key);

  @override
  _DeviceSpecificVerifyPageState createState() => _DeviceSpecificVerifyPageState();
}

class _DeviceSpecificVerifyPageState extends State<DeviceSpecificVerifyPage> {
  List<String> _mnemonicWords = [];
  List<String> _selectedWords = [];
  List<String> _shuffledWords = [];
  bool _isVerified = false;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _initializeWords();
  }
  
  void _initializeWords() {
    // Split the device-specific mnemonic into words
    _mnemonicWords = widget.deviceMnemonic.split(' ');
    
    // Create a shuffled copy of the words for selection
    _shuffledWords = List.from(_mnemonicWords);
    _shuffledWords.shuffle();
    
    // Initialize selected words list with empty strings
    _selectedWords = List.filled(_mnemonicWords.length, '');
  }
  
  void _selectWord(String word) {
    if (_isVerified) return;
    
    setState(() {
      // Find the first empty slot in selected words
      final emptyIndex = _selectedWords.indexOf('');
      if (emptyIndex != -1) {
        _selectedWords[emptyIndex] = word;
        
        // Remove the word from shuffled words
        _shuffledWords.remove(word);
        
        // Check if all words are selected
        if (!_selectedWords.contains('')) {
          _verifyWords();
        }
      }
    });
  }
  
  void _removeWord(int index) {
    if (_isVerified) return;
    
    setState(() {
      // Get the word to remove
      final word = _selectedWords[index];
      if (word.isNotEmpty) {
        // Add the word back to shuffled words
        _shuffledWords.add(word);
        // Sort shuffled words alphabetically for consistency
        _shuffledWords.sort();
        // Clear the selected word
        _selectedWords[index] = '';
      }
      
      // Reset verification status
      _isVerified = false;
      _hasError = false;
    });
  }
  
  void _verifyWords() {
    // Check if selected words match the original mnemonic words
    final isCorrect = _areWordsCorrect();
    
    setState(() {
      _isVerified = true;
      _hasError = !isCorrect;
    });
    
    if (isCorrect) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recovery phrase verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to password setup after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SetDevicePasswordsPage(
                mnemonic: widget.mnemonic,
                isDevice1: widget.isDevice1,
                fullMnemonic: widget.mnemonic,
                deviceMnemonic: widget.deviceMnemonic,
              ),
            ),
          );
        }
      });
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect recovery phrase. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  bool _areWordsCorrect() {
    // Compare selected words with original mnemonic words
    for (int i = 0; i < _mnemonicWords.length; i++) {
      if (_selectedWords[i] != _mnemonicWords[i]) {
        return false;
      }
    }
    return true;
  }
  
  void _resetSelection() {
    setState(() {
      // Reset all selections
      _shuffledWords = List.from(_mnemonicWords);
      _shuffledWords.shuffle();
      _selectedWords = List.filled(_mnemonicWords.length, '');
      _isVerified = false;
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.isDevice1 ? 'Device 1' : 'Device 2';
    final deviceColor = widget.isDevice1 ? Colors.blue : Colors.purple;
    final wordRange = widget.isDevice1 ? '1-12' : '13-24';
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Verify Recovery Phrase - $deviceText'),
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
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12.0 : 16.0,
                  vertical: isSmallScreen ? 8.0 : 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: deviceColor.withOpacity(0.5)),
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
                            'Verify $deviceText Recovery Phrase',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: deviceColor,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            'Select your words in the correct order (Words $wordRange)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Selected words grid
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isVerified
                              ? (_hasError ? Colors.red : Colors.green)
                              : deviceColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Your Recovery Phrase',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isVerified
                                      ? (_hasError ? Colors.red : Colors.green)
                                      : deviceColor,
                                ),
                              ),
                              if (_isVerified)
                                Icon(
                                  _hasError ? Icons.error : Icons.check_circle,
                                  color: _hasError ? Colors.red : Colors.green,
                                  size: isSmallScreen ? 18 : 24,
                                ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 8 : 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Calculate the number of columns based on screen width
                              int crossAxisCount = constraints.maxWidth > 400 ? 3 : 2;
                              
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: 2.5,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _selectedWords.length,
                                itemBuilder: (context, index) {
                                  final wordIndex = widget.wordIndexRange.start + index;
                                  return GestureDetector(
                                    onTap: () => _removeWord(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _selectedWords[index].isEmpty
                                            ? Colors.black45
                                            : (_isVerified && _hasError
                                                ? Colors.red.withOpacity(0.2)
                                                : deviceColor.withOpacity(0.2)),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _selectedWords[index].isEmpty
                                              ? Colors.white.withOpacity(0.3)
                                              : (_isVerified && _hasError
                                                  ? Colors.red
                                                  : deviceColor),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${wordIndex + 1}.',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: isSmallScreen ? 10 : 12,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _selectedWords[index].isEmpty ? '...' : _selectedWords[index],
                                              style: TextStyle(
                                                color: _selectedWords[index].isEmpty
                                                    ? Colors.white.withOpacity(0.5)
                                                    : Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 10 : 12,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Word selection grid
                    if (!_isVerified || _hasError)
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: deviceColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Words',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 8 : 12),
                            Wrap(
                              spacing: isSmallScreen ? 6 : 8,
                              runSpacing: isSmallScreen ? 6 : 8,
                              children: _shuffledWords.map((word) {
                                return GestureDetector(
                                  onTap: () => _selectWord(word),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 8 : 10, 
                                      vertical: isSmallScreen ? 4 : 6
                                    ),
                                    decoration: BoxDecoration(
                                      color: deviceColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: deviceColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 11 : 13,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Action buttons
                    if (_isVerified && _hasError)
                      ElevatedButton.icon(
                        onPressed: _resetSelection,
                        icon: Icon(Icons.refresh, size: isSmallScreen ? 16 : 20),
                        label: Text(
                          'Try Again',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    
                    if (!_isVerified && !_selectedWords.contains(''))
                      ElevatedButton.icon(
                        onPressed: _verifyWords,
                        icon: Icon(Icons.check_circle, size: isSmallScreen ? 16 : 20),
                        label: Text(
                          'Verify',
                          style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deviceColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    if (!_isVerified)
                      TextButton.icon(
                        onPressed: _resetSelection,
                        icon: Icon(Icons.refresh, color: Colors.white, size: isSmallScreen ? 14 : 16),
                        label: Text(
                          'Reset Selection',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white30),
                          ),
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
