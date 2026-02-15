import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:web3_wallet/pages/device_specific_verify_page.dart';

class SetDualDevicePasswordsPage extends StatefulWidget {
  final String mnemonic;
  final String device1Words;
  final String device2Words;
  
  const SetDualDevicePasswordsPage({
    Key? key, 
    required this.mnemonic,
    required this.device1Words,
    required this.device2Words,
  }) : super(key: key);

  @override
  State<SetDualDevicePasswordsPage> createState() => _SetDualDevicePasswordsPageState();
}

class _SetDualDevicePasswordsPageState extends State<SetDualDevicePasswordsPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Device 1 password controllers
  final _device1PasswordController = TextEditingController();
  final _device1ConfirmPasswordController = TextEditingController();
  final _device1TransactionPasswordController = TextEditingController();
  final _device1ConfirmTransactionPasswordController = TextEditingController();
  
  // Device 2 password controllers
  final _device2PasswordController = TextEditingController();
  final _device2ConfirmPasswordController = TextEditingController();
  final _device2TransactionPasswordController = TextEditingController();
  final _device2ConfirmTransactionPasswordController = TextEditingController();
  
  // Password visibility toggles
  bool _obscureDevice1Password = true;
  bool _obscureDevice1ConfirmPassword = true;
  bool _obscureDevice1TransactionPassword = true;
  bool _obscureDevice1ConfirmTransactionPassword = true;
  
  bool _obscureDevice2Password = true;
  bool _obscureDevice2ConfirmPassword = true;
  bool _obscureDevice2TransactionPassword = true;
  bool _obscureDevice2ConfirmTransactionPassword = true;
  
  bool _isLoading = false;

  @override
  void dispose() {
    // Dispose Device 1 controllers
    _device1PasswordController.dispose();
    _device1ConfirmPasswordController.dispose();
    _device1TransactionPasswordController.dispose();
    _device1ConfirmTransactionPasswordController.dispose();
    
    // Dispose Device 2 controllers
    _device2PasswordController.dispose();
    _device2ConfirmPasswordController.dispose();
    _device2TransactionPasswordController.dispose();
    _device2ConfirmTransactionPasswordController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Set Device Passwords'),
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
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'Set Passwords for Both Devices',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'For maximum security, you need to create separate passwords for each device. '
                        'Each device requires a login password and a transaction password.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Device 1 Passwords Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device 1 Passwords',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Device 1 Login Password
                          TextFormField(
                            controller: _device1PasswordController,
                            obscureText: _obscureDevice1Password,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Device 1 Login Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Enter a strong password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice1Password ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice1Password = !_obscureDevice1Password;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Device 1 Confirm Login Password
                          TextFormField(
                            controller: _device1ConfirmPasswordController,
                            obscureText: _obscureDevice1ConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Device 1 Login Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Confirm your password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice1ConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice1ConfirmPassword = !_obscureDevice1ConfirmPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _device1PasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Device 1 Transaction Password
                          TextFormField(
                            controller: _device1TransactionPasswordController,
                            obscureText: _obscureDevice1TransactionPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Device 1 Transaction Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Enter a different strong password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.security, color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice1TransactionPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice1TransactionPassword = !_obscureDevice1TransactionPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a transaction password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (value == _device1PasswordController.text) {
                                return 'Transaction password must be different from login password';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Device 1 Confirm Transaction Password
                          TextFormField(
                            controller: _device1ConfirmTransactionPasswordController,
                            obscureText: _obscureDevice1ConfirmTransactionPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Device 1 Transaction Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Confirm your transaction password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.security_outlined, color: Colors.blue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice1ConfirmTransactionPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice1ConfirmTransactionPassword = !_obscureDevice1ConfirmTransactionPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your transaction password';
                              }
                              if (value != _device1TransactionPasswordController.text) {
                                return 'Transaction passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Device 2 Passwords Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device 2 Passwords',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Device 2 Login Password
                          TextFormField(
                            controller: _device2PasswordController,
                            obscureText: _obscureDevice2Password,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Device 2 Login Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Enter a strong password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.lock, color: Colors.purple),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice2Password ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.purple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice2Password = !_obscureDevice2Password;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.purple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.purple, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Device 2 Confirm Login Password
                          TextFormField(
                            controller: _device2ConfirmPasswordController,
                            obscureText: _obscureDevice2ConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Device 2 Login Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Confirm your password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice2ConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.purple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice2ConfirmPassword = !_obscureDevice2ConfirmPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.purple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.purple, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _device2PasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Device 2 Transaction Password
                          TextFormField(
                            controller: _device2TransactionPasswordController,
                            obscureText: _obscureDevice2TransactionPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Device 2 Transaction Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Enter a different strong password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.security, color: Colors.purple),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice2TransactionPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.purple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice2TransactionPassword = !_obscureDevice2TransactionPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.purple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.purple, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a transaction password';
                              }
                              if (value.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              if (value == _device2PasswordController.text) {
                                return 'Transaction password must be different from login password';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Device 2 Confirm Transaction Password
                          TextFormField(
                            controller: _device2ConfirmTransactionPasswordController,
                            obscureText: _obscureDevice2ConfirmTransactionPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirm Device 2 Transaction Password',
                              labelStyle: const TextStyle(color: Colors.white70),
                              hintText: 'Confirm your transaction password',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                              prefixIcon: const Icon(Icons.security_outlined, color: Colors.purple),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureDevice2ConfirmTransactionPassword ? Icons.visibility : Icons.visibility_off,
                                  color: Colors.purple,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureDevice2ConfirmTransactionPassword = !_obscureDevice2ConfirmTransactionPassword;
                                  });
                                },
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.purple.withOpacity(0.5)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.purple, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.red, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.5),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your transaction password';
                              }
                              if (value != _device2TransactionPasswordController.text) {
                                return 'Transaction passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Password strength indicators
                    _buildPasswordStrengthIndicator(_device1PasswordController.text, 'Device 1 Login Password', Colors.blue),
                    const SizedBox(height: 16),
                    _buildPasswordStrengthIndicator(_device1TransactionPasswordController.text, 'Device 1 Transaction Password', Colors.blue),
                    const SizedBox(height: 16),
                    _buildPasswordStrengthIndicator(_device2PasswordController.text, 'Device 2 Login Password', Colors.purple),
                    const SizedBox(height: 16),
                    _buildPasswordStrengthIndicator(_device2TransactionPasswordController.text, 'Device 2 Transaction Password', Colors.purple),
                    
                    const SizedBox(height: 32),
                    
                    // Continue button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _continueToVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : const Text(
                                'Create Wallet',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password, String label, Color color) {
    double strength = 0;
    String strengthLabel = 'No Password';
    Color strengthColor = Colors.grey;
    
    if (password.isNotEmpty) {
      // Calculate password strength
      if (password.length >= 8) strength += 0.2;
      if (password.length >= 12) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;
      
      // Set label and color based on strength
      if (strength <= 0.2) {
        strengthLabel = 'Very Weak';
        strengthColor = Colors.red;
      } else if (strength <= 0.4) {
        strengthLabel = 'Weak';
        strengthColor = Colors.orange;
      } else if (strength <= 0.6) {
        strengthLabel = 'Medium';
        strengthColor = Colors.yellow;
      } else if (strength <= 0.8) {
        strengthLabel = 'Strong';
        strengthColor = Colors.lightGreen;
      } else {
        strengthLabel = 'Very Strong';
        strengthColor = AppTheme.neonGreen;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label Strength:',
              style: TextStyle(
                color: color.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              strengthLabel,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: strength,
            backgroundColor: Colors.grey.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // Update the _continueToVerification method to navigate to the verification page for Device 1 first
  Future<void> _continueToVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Set the passwords in the provider
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Store the passwords in the provider with explicit validation
      final device1Password = _device1PasswordController.text.trim();
      final device1TxPassword = _device1TransactionPasswordController.text.trim();
      final device2Password = _device2PasswordController.text.trim();
      final device2TxPassword = _device2TransactionPasswordController.text.trim();
      
      // Debug logging for password validation
      print('📝 Password Validation:');
      print('  Device 1 Password: "${device1Password}" (Length: ${device1Password.length})');
      print('  Device 1 Tx Password: "${device1TxPassword}" (Length: ${device1TxPassword.length})');
      print('  Device 2 Password: "${device2Password}" (Length: ${device2Password.length})');
      print('  Device 2 Tx Password: "${device2TxPassword}" (Length: ${device2TxPassword.length})');
      
      // Validate that passwords are not empty and have proper length
      if (device1Password.isEmpty || device1TxPassword.isEmpty || 
          device2Password.isEmpty || device2TxPassword.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All passwords must be filled'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      await walletProvider.setDevice1Password(device1Password);
      await walletProvider.setDevice1TransactionPassword(device1TxPassword);
      await walletProvider.setDevice2Password(device2Password);
      await walletProvider.setDevice2TransactionPassword(device2TxPassword);
      
      // Navigate to verification page for Device 1 first
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceSpecificVerifyPage(
            mnemonic: widget.mnemonic,
            isDevice1: true, // Start with Device 1 verification
            deviceMnemonic: widget.device1Words,
            wordIndexRange: WordIndexRange(0, 12),
            fullMnemonic: widget.mnemonic, // Add the missing parameter
          ),
        ),
      );
      
      setState(() {
        _isLoading = false;
      });
    }
  }
}
