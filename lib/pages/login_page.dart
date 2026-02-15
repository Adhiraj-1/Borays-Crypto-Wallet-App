import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import 'wallet_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  final String walletId;
  final int deviceType;
  final String mnemonicPart;

  const LoginPage({
    Key? key,
    required this.walletId,
    required this.deviceType,
    required this.mnemonicPart,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final enteredPassword = _passwordController.text.trim();
    
    if (enteredPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final doc = await FirebaseFirestore.instance.collection('userData').doc(widget.walletId).get();
      if (doc.exists) {
        final data = doc.data();
        final correctPassword = widget.deviceType == 1 ? data!['device1Password'] : data!['device2Password'];
        if (enteredPassword == correctPassword) {
          // Load wallet info into provider/state
          final walletProvider = Provider.of<WalletProvider>(context, listen: false);

          // Set wallet data in provider using public setters
          walletProvider.setWalletId(widget.walletId);
          walletProvider.setWalletAddress(data['walletAddress'] ?? '');
          walletProvider.setMnemonic(data['mnemonic'] ?? '');
          walletProvider.setPrivateKey(data['privateKey'] ?? '');
          walletProvider.setDeviceType(widget.deviceType == 1);
          walletProvider.setAuthenticated(true);
          walletProvider.setInitialized(true);
          
          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Welcome back to ${widget.deviceType == 1 ? 'Device 1' : 'Device 2'}!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
          // Navigate to main/home page
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => WalletPage(isDevice1: widget.deviceType == 1),
            ),
          );
        } else {
          // Show error: Wrong password
          setState(() {
            _errorMessage = 'Invalid password for ${widget.deviceType == 1 ? 'Device 1' : 'Device 2'}.\n\n'
                           'Please check:\n'
                           '• You entered the correct password\n'
                           '• This password matches the one set for these recovery words\n'
                           '• You are using the right device (${widget.deviceType == 1 ? 'Device 1' : 'Device 2'})';
          });
        }
      } else {
        // Show error: Wallet document not found
        setState(() {
          _errorMessage = 'Wallet document not found';
        });
      }
    } catch (e) {
      print('💥 LoginPage: Error during login: $e');
      setState(() {
        _errorMessage = 'Login failed: ${e.toString()}\n\nPlease try again or contact support if the problem persists.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.deviceType == 1 ? 'Device 1' : 'Device 2';
    final deviceColor = widget.deviceType == 1 ? Colors.blue : Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Text('Login to $deviceText'),
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
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: deviceColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: deviceColor),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              widget.deviceType == 1 ? Icons.phone_android : Icons.tablet_android,
                              size: 48,
                              color: deviceColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Welcome Back!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: deviceColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your $deviceText password to continue',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          labelText: '$deviceText Password',
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
                          fillColor: Colors.black.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: deviceColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: deviceColor.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: deviceColor, width: 2),
                          ),
                        ),
                        onFieldSubmitted: (_) => _login(),
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                      
                      // Login Button
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: deviceColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This is your daily access password for this device.',
                                style: TextStyle(color: Colors.blue, fontSize: 12),
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
}
