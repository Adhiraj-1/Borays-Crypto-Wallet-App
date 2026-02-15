import 'package:flutter/material.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:tw_wallet_ui/common/secure_storage.dart';
import 'package:tw_wallet_ui/models/wallet_model.dart';
import 'package:tw_wallet_ui/providers/wallet_provider.dart';
import 'package:tw_wallet_ui/views/home/home.dart';
import 'package:provider/provider.dart';

class CreateWalletPage extends StatefulWidget {
  final bool isDevice1;

  const CreateWalletPage({Key? key, required this.isDevice1}) : super(key: key);

  @override
  State<CreateWalletPage> createState() => _CreateWalletPageState();
}

class _CreateWalletPageState extends State<CreateWalletPage> {
  String _mnemonic = '';
  String _privateKey = '';
  String _walletAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateWalletData();
  }

  Future<void> _generateWalletData() async {
    setState(() {
      _isLoading = true;
    });

    // Generate mnemonic, private key, and wallet address
    _mnemonic = bip39.generateMnemonic();
    // TODO: Derive private key and wallet address from mnemonic

    setState(() {
      _privateKey = '0x1234567890abcdef'; // Replace with actual private key
      _walletAddress = '0xabcdef1234567890'; // Replace with actual wallet address
      _isLoading = false;
    });
  }

  Future<void> _saveWallet() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('🔄 CreateWalletPage: Starting wallet save process...');
      
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Create a new wallet with the generated data and save EVERYTHING to Firebase
      final success = await walletProvider.createWallet(
        _mnemonic,
        "device1password", // Default password for demo
        "device1txpassword", // Default transaction password for demo
        "device2password", // Default password for demo
        "device2txpassword", // Default transaction password for demo
      );
      
      setState(() {
        _isLoading = false;
      });
      
      if (success) {
        print('✅ CreateWalletPage: Wallet created successfully');
        
        // Navigate to wallet page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WalletPage(isDevice1: widget.isDevice1),
          ),
        );
      } else {
        print('❌ CreateWalletPage: Failed to create wallet');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save wallet to Firebase'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('💥 CreateWalletPage: Error saving wallet: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save wallet: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create BORAYS Crypto Wallet'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mnemonic:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_mnemonic),
                  const SizedBox(height: 16),
                  const Text(
                    'Private Key:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_privateKey),
                  const SizedBox(height: 16),
                  const Text(
                    'Wallet Address:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(_walletAddress),
                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveWallet,
                      child: const Text('Save Wallet to Firebase'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
