import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/pages/wallet_page.dart';
import 'package:web3_wallet/theme/app_theme.dart';

class CreateWalletFlowPage extends StatefulWidget {
  final String mnemonic;
  
  const CreateWalletFlowPage({
    Key? key,
    required this.mnemonic,
  }) : super(key: key);

  @override
  State<CreateWalletFlowPage> createState() => _CreateWalletFlowPageState();
}

class _CreateWalletFlowPageState extends State<CreateWalletFlowPage> {
  final _device1PasswordController = TextEditingController();
  final _device2PasswordController = TextEditingController();
  final _device1TxPasswordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _passwordsVisible = false;

  @override
  void dispose() {
    _device1PasswordController.dispose();
    _device2PasswordController.dispose();
    _device1TxPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate inputs
      if (_device1PasswordController.text.isEmpty ||
          _device2PasswordController.text.isEmpty ||
          _device1TxPasswordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Please fill in all password fields';
          _isLoading = false;
        });
        return;
      }

      if (_device1PasswordController.text.length < 6 ||
          _device2PasswordController.text.length < 6 ||
          _device1TxPasswordController.text.length < 6) {
        setState(() {
          _errorMessage = 'All passwords must be at least 6 characters';
          _isLoading = false;
        });
        return;
      }

      print('🔄 Creating wallet and saving to Firestore...');
      
      // Split mnemonic for dual-device setup
      final words = widget.mnemonic.split(' ');
      final device1Mnemonic = words.take(12).join(' ');
      final device2Mnemonic = words.skip(12).join(' ');

      // IMMEDIATE FIRESTORE SAVE ON CREATE BUTTON CLICK
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.finalizeWalletCreation(
        device1Mnemonic,
        device2Mnemonic,
        _device1PasswordController.text,
        _device2PasswordController.text,
        _device1TxPasswordController.text,
      );

      if (success) {
        print('✅ Wallet created and saved to Firestore successfully!');
        
        // Navigate to wallet page
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletPage(),
            ),
            (route) => false,
          );
        }
      } else {
        print('❌ Failed to create wallet');
        setState(() {
          _errorMessage = 'Failed to create wallet. This wallet may already exist.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('💥 Error during wallet creation: $e');
      setState(() {
        _errorMessage = 'Failed to create wallet. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Set Passwords'),
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Title
                const Text(
                  'Secure Your Wallet',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                const Text(
                  'Set passwords for both devices and transactions',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Password Fields
                _buildPasswordField(
                  'Device 1 Password',
                  _device1PasswordController,
                  'Password for Device 1 access',
                ),
                
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  'Device 2 Password',
                  _device2PasswordController,
                  'Password for Device 2 access',
                ),
                
                const SizedBox(height: 16),
                
                _buildPasswordField(
                  'Transaction Password',
                  _device1TxPasswordController,
                  'Password for approving transactions',
                ),
                
                const SizedBox(height: 16),
                
                // Show/Hide Passwords Toggle
                Row(
                  children: [
                    Checkbox(
                      value: _passwordsVisible,
                      onChanged: (value) {
                        setState(() {
                          _passwordsVisible = value ?? false;
                        });
                      },
                      activeColor: AppTheme.neonGreen,
                    ),
                    const Text(
                      'Show passwords',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Create Wallet Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _createWallet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating & Saving to Cloud...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Wallet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                const Spacer(),
                
                // Security Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cloud_upload, color: AppTheme.neonGreen),
                          SizedBox(width: 8),
                          Text(
                            'Cloud Backup',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your wallet will be securely saved to the cloud. You can import it on any device using your recovery phrase.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !_passwordsVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.neonGreen),
            ),
          ),
          enabled: !_isLoading,
        ),
      ],
    );
  }
}
