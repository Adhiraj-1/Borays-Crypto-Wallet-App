import 'package:flutter/material.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'set_device_passwords_page.dart';

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
  final String fullMnemonic;
  
  const DeviceSpecificVerifyPage({
    Key? key,
    required this.mnemonic,
    required this.deviceMnemonic,
    required this.isDevice1,
    required this.wordIndexRange,
    required this.fullMnemonic,
  }) : super(key: key);

  @override
  _DeviceSpecificVerifyPageState createState() => _DeviceSpecificVerifyPageState();
}

class _DeviceSpecificVerifyPageState extends State<DeviceSpecificVerifyPage> {
  final TextEditingController _mnemonicController = TextEditingController();
  bool _isLoading = false;
  bool _isError = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
  }
  
  bool _verifyMnemonic() {
    // Get the entered mnemonic and normalize it
    final enteredMnemonic = _mnemonicController.text.trim().toLowerCase();
    final expectedMnemonic = widget.deviceMnemonic.trim().toLowerCase();
    
    // Compare the entered mnemonic with the expected one
    return enteredMnemonic == expectedMnemonic;
  }
  
  void _submitVerification() {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });
    
    final isCorrect = _verifyMnemonic();
    
    setState(() {
      _isLoading = false;
    });
    
    if (isCorrect) {
      // Navigate to password setup
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SetDevicePasswordsPage(
            mnemonic: widget.mnemonic,
            isDevice1: widget.isDevice1,
            fullMnemonic: widget.fullMnemonic,
            deviceMnemonic: widget.deviceMnemonic,
          ),
        ),
      );
    } else {
      // Show error
      setState(() {
        _isError = true;
        _errorMessage = 'Verification failed. Please check your recovery phrase and try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification failed. Please check your recovery phrase and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        title: Text('Verify $deviceText Words'),
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
                                widget.isDevice1 ? Icons.smartphone : Icons.tablet_android,
                                size: isSmallScreen ? 32 : 40,
                                color: deviceColor,
                              ),
                              SizedBox(height: isSmallScreen ? 8 : 12),
                              Text(
                                'Verify Your $deviceText Recovery Phrase',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: deviceColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isSmallScreen ? 6 : 8),
                              Text(
                                'Enter all 12 words from your $deviceText recovery phrase (words $wordRange) in the correct order.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 12 : 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        // Instructions
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
                                size: isSmallScreen ? 16 : 18
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Expanded(
                                child: Text(
                                  'Enter all 12 words separated by spaces, in the exact order they were shown.',
                                  style: TextStyle(
                                    color: Colors.white, 
                                    fontSize: isSmallScreen ? 12 : 13
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        
                        // Mnemonic input field
                        TextField(
                          controller: _mnemonicController,
                          decoration: InputDecoration(
                            labelText: 'Enter your 12 words',
                            labelStyle: TextStyle(color: deviceColor),
                            hintText: 'word1 word2 word3 ...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.black,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: deviceColor),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.red),
                            ),
                            errorText: _isError ? _errorMessage : null,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                          maxLines: 3,
                          minLines: 3,
                        ),
                        
                        SizedBox(height: isSmallScreen ? 16 : 20),
                        
                        // Submit button
                        ElevatedButton(
                          onPressed: _submitVerification,
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
                        
                        // Back to recovery phrase button
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white70,
                          ),
                          child: Text(
                            'Back to Recovery Phrase',
                            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
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
  
  @override
  void dispose() {
    _mnemonicController.dispose();
    super.dispose();
  }
}
