import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'wallet_page.dart';
import 'device_specific_verify_page.dart';

class SetDevicePasswordsPage extends StatefulWidget {
  final String mnemonic;
  final bool isDevice1;
  final String fullMnemonic;
  final String deviceMnemonic;
  
  const SetDevicePasswordsPage({
    Key? key, 
    required this.mnemonic,
    required this.isDevice1,
    required this.fullMnemonic,
    required this.deviceMnemonic,
  }) : super(key: key);

  @override
  _SetDevicePasswordsPageState createState() => _SetDevicePasswordsPageState();
}

class _SetDevicePasswordsPageState extends State<SetDevicePasswordsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _transactionPasswordController = TextEditingController();
  final TextEditingController _confirmTransactionPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureTransactionPassword = true;
  bool _obscureConfirmTransactionPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _transactionPasswordController.dispose();
    _confirmTransactionPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setPasswords() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Set device-specific passwords
      if (widget.isDevice1) {
        await walletProvider.setDevice1Password(_passwordController.text);
        await walletProvider.setDevice1TransactionPassword(_transactionPasswordController.text);
      } else {
        await walletProvider.setDevice2Password(_passwordController.text);
        await walletProvider.setDevice2TransactionPassword(_transactionPasswordController.text);
      }
      
      if (!mounted) return;
      
      // If this is Device 1, navigate to Device 2 verification
      if (widget.isDevice1) {
        // Get the split mnemonic parts
        final fullMnemonic = widget.fullMnemonic;
        final splitParts = walletProvider.splitMnemonic(fullMnemonic);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DeviceSpecificVerifyPage(
              mnemonic: splitParts['device2']!,
              deviceMnemonic: splitParts['device2']!,
              isDevice1: false,
              wordIndexRange: WordIndexRange(12, 23),
              fullMnemonic: fullMnemonic,
            ),
          ),
        );
      } else {
        // If this is Device 2, finalize wallet creation and go to wallet page
        final device1Password = await walletProvider.getDevice1Password() ?? '';
        final device1TxPassword = await walletProvider.getDevice1TransactionPassword() ?? '';
        final device2Password = await walletProvider.getDevice2Password() ?? '';
        final device2TxPassword = await walletProvider.getDevice2TransactionPassword() ?? '';
        
        final success = await walletProvider.finalizeWalletCreation(
          widget.fullMnemonic,
          device1Password,
          device1TxPassword,
          device2Password,
          device2TxPassword,
        );
        
        if (success) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => WalletPage(isDevice1: true)),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create wallet. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error setting passwords: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Set Passwords - $deviceText'),
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: SafeArea(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: deviceColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              widget.isDevice1 ? Icons.phone_android : Icons.tablet_android,
                              size: 48,
                              color: deviceColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create Passwords for $deviceText',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'You\'ll need two different passwords - one for daily access and another for approving transactions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Primary Password Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: deviceColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$deviceText Login Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Used for logging into $deviceText',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
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
                              ),
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscurePassword,
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
                            
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
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
                              ),
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscureConfirmPassword,
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
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transaction Password Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: deviceColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$deviceText Transaction Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Used for approving transactions from $deviceText',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _transactionPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Transaction Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                prefixIcon: Icon(Icons.security, color: deviceColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureTransactionPassword ? Icons.visibility : Icons.visibility_off,
                                    color: deviceColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureTransactionPassword = !_obscureTransactionPassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscureTransactionPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a transaction password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (value == _passwordController.text) {
                                  return 'Transaction password must be different from login password';
                                }
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _confirmTransactionPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm Transaction Password',
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: deviceColor),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                prefixIcon: Icon(Icons.security_outlined, color: deviceColor),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmTransactionPassword ? Icons.visibility : Icons.visibility_off,
                                    color: deviceColor,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmTransactionPassword = !_obscureConfirmTransactionPassword;
                                    });
                                  },
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              obscureText: _obscureConfirmTransactionPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your transaction password';
                                }
                                if (value != _transactionPasswordController.text) {
                                  return 'Transaction passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Remember both passwords for this device! They cannot be recovered if lost.',
                                style: TextStyle(
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      ElevatedButton(
                        onPressed: _setPasswords,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deviceColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.isDevice1 
                              ? 'Continue to Device 2 Setup' 
                              : 'Complete Wallet Setup',
                          style: const TextStyle(
                            fontSize: 18,
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
