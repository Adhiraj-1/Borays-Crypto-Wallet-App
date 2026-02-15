import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'wallet_page.dart';

class SetPasswordsPage extends StatefulWidget {
  final bool isDevice1;
  final String? mnemonicPart;

  const SetPasswordsPage({
    Key? key, 
    required this.isDevice1,
    this.mnemonicPart,
  }) : super(key: key);

  @override
  State<SetPasswordsPage> createState() => _SetPasswordsPageState();
}

class _SetPasswordsPageState extends State<SetPasswordsPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _txPasswordController = TextEditingController();
  final _confirmTxPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureTxPassword = true;
  bool _obscureConfirmTxPassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _txPasswordController.dispose();
    _confirmTxPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Get the ACTUAL passwords from the controllers
      final password = _passwordController.text.trim();
      final txPassword = _txPasswordController.text.trim();
      
      print('🔄 SetPasswordsPage: Creating wallet with ACTUAL passwords');
      print('  Device: ${widget.isDevice1 ? 'Device 1' : 'Device 2'}');
      print('  Password length: ${password.length}');
      print('  Tx Password length: ${txPassword.length}');
      
      // Validate passwords are not empty
      if (password.isEmpty || txPassword.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Passwords cannot be empty';
        });
        return;
      }
      
      // Generate a new mnemonic
      final mnemonic = walletProvider.generateMnemonic();
      print('  Generated mnemonic: ${mnemonic.substring(0, 20)}...');
      
      // Create wallet with ACTUAL passwords
      bool success;
      if (widget.isDevice1) {
        print('  Creating wallet for Device 1 with:');
        print('    Device1 Password: "$password"');
        print('    Device1 Tx Password: "$txPassword"');
        
        success = await walletProvider.createWallet(
          mnemonic,
          password,           // ACTUAL device1Password
          txPassword,         // ACTUAL device1TxPassword  
          "defaultpass2",     // device2Password (placeholder)
          "defaulttx2"        // device2TxPassword (placeholder)
        );
      } else {
        print('  Creating wallet for Device 2 with:');
        print('    Device2 Password: "$password"');
        print('    Device2 Tx Password: "$txPassword"');
        
        success = await walletProvider.createWallet(
          mnemonic,
          "defaultpass1",     // device1Password (placeholder)
          "defaulttx1",       // device1TxPassword (placeholder)
          password,           // ACTUAL device2Password
          txPassword          // ACTUAL device2TxPassword
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          print('✅ SetPasswordsPage: Wallet created successfully');
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WalletPage(isDevice1: widget.isDevice1),
            ),
          );
        } else {
          print('❌ SetPasswordsPage: Failed to create wallet');
          setState(() {
            _errorMessage = 'Failed to create wallet. Please try again.';
          });
        }
      }
    } catch (e) {
      print('💥 SetPasswordsPage: Error creating wallet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error creating wallet: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.isDevice1 ? 'Device 1' : 'Device 2';
    final deviceColor = widget.isDevice1 ? Colors.blue : Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Text('BORAYS Crypto Wallet - $deviceText'),
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
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: deviceColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: deviceColor),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                widget.isDevice1 ? Icons.phone_android : Icons.tablet_android,
                                size: 40,
                                color: deviceColor,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Create Passwords for $deviceText',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: deviceColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'You\'ll need two different passwords - one for daily access and another for approving transactions.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Login Password Section
                        Text(
                          '$deviceText Login Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deviceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isDevice1 ? 'Used for logging into Device 1' : 'Used for logging into Device 2',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: deviceColor),
                            prefixIcon: Icon(Icons.lock, color: deviceColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: deviceColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: deviceColor),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 4) {
                              return 'Password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Confirm Password Field
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            labelStyle: TextStyle(color: deviceColor),
                            prefixIcon: Icon(Icons.lock_outline, color: deviceColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                color: deviceColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: deviceColor),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Transaction Password Section
                        Text(
                          '$deviceText Transaction Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: deviceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.isDevice1 ? 'Used for approving transactions from Device 1' : 'Used for approving transactions from Device 2',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        
                        // Transaction Password Field
                        TextFormField(
                          controller: _txPasswordController,
                          obscureText: _obscureTxPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Transaction Password',
                            labelStyle: TextStyle(color: deviceColor),
                            prefixIcon: Icon(Icons.security, color: deviceColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureTxPassword ? Icons.visibility : Icons.visibility_off,
                                color: deviceColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureTxPassword = !_obscureTxPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: deviceColor),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a transaction password';
                            }
                            if (value.length < 4) {
                              return 'Transaction password must be at least 4 characters';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Confirm Transaction Password Field
                        TextFormField(
                          controller: _confirmTxPasswordController,
                          obscureText: _obscureConfirmTxPassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Confirm Transaction Password',
                            labelStyle: TextStyle(color: deviceColor),
                            prefixIcon: Icon(Icons.security_outlined, color: deviceColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmTxPassword ? Icons.visibility : Icons.visibility_off,
                                color: deviceColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmTxPassword = !_obscureConfirmTxPassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.black,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: deviceColor),
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
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your transaction password';
                            }
                            if (value != _txPasswordController.text) {
                              return 'Transaction passwords do not match';
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Error Message
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        // Warning
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.withOpacity(0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_outlined, color: Colors.amber),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Remember both passwords for this device! They cannot be recovered if lost.',
                                  style: TextStyle(color: Colors.amber, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Create Button
                        ElevatedButton(
                          onPressed: _createWallet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: deviceColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Complete Wallet Setup',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
