import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:web3_wallet/utils/wallet_api.dart';

class FaucetDialog extends StatefulWidget {
  final String? walletAddress; // Make walletAddress optional
  
  const FaucetDialog({Key? key, this.walletAddress}) : super(key: key);

  @override
  _FaucetDialogState createState() => _FaucetDialogState();
}

class _FaucetDialogState extends State<FaucetDialog> {
  bool _isLoading = false;
  bool _isSuccess = false;
  String _message = '';
  late String _walletAddress;

  @override
  void initState() {
    super.initState();
    // If walletAddress is not provided, get it from the provider
    _walletAddress = widget.walletAddress ?? '';
    if (_walletAddress.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final walletProvider = Provider.of<WalletProvider>(context, listen: false);
        setState(() {
          _walletAddress = walletProvider.walletAddress;
        });
      });
    }
  }

  Future<void> _requestTestEth() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _message = '';
    });
    
    try {
      final success = await WalletApi.requestTestnetEth(_walletAddress);
      
      setState(() {
        _isLoading = false;
        _isSuccess = success;
        _message = success 
            ? 'Request successful! It may take a few minutes for the ETH to arrive.'
            : 'Failed to request test ETH. Please try again later.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: const Text(
        'Request Test ETH',
        style: TextStyle(color: AppTheme.neonGreen),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Request test ETH from the Sepolia faucet to use in your wallet.',
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonGreen.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Text(
              _walletAddress.isEmpty ? 'Loading wallet address...' : _walletAddress,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator(color: AppTheme.neonGreen)
          else if (_message.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isSuccess ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                style: TextStyle(
                  color: _isSuccess ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _walletAddress.isEmpty || _isLoading ? null : _requestTestEth,
          child: Text(
            'Request ETH',
            style: TextStyle(
              color: _walletAddress.isEmpty || _isLoading ? AppTheme.neonGreen.withOpacity(0.5) : AppTheme.neonGreen,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
