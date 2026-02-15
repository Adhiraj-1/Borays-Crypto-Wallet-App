import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:web3_wallet/pages/send_transaction_page.dart';
import 'package:web3_wallet/utils/wallet_api.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/widgets/faucet_dialog.dart';
import 'package:web3_wallet/pages/pending_transactions_page.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web3_wallet/models/transaction.dart';
import 'package:web3_wallet/pages/landing_page.dart';
import 'dart:async';

// Original wallet page with black theme and improved balance fetching
class WalletPage extends StatefulWidget {
  final bool isDevice1;

  const WalletPage({Key? key, required this.isDevice1}) : super(key: key);

  @override
  _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with SingleTickerProviderStateMixin {
  String walletAddress = '';
  String balance = '0.0';
  String pvKey = '';
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _pendingTransactionsCount = 0;
  Timer? _syncTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    _tabController = TabController(length: 2, vsync: this);
    
    // Load wallet data
    loadWalletData();
    
    // Sync transactions when the page is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      walletProvider.syncTransactions();
      _updatePendingTransactionsCount();
      
      // Set up a timer to periodically sync transactions and balance
      _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        if (mounted) {
          print('⏰ Periodic sync triggered');
          _syncTransactionsAndBalance();
        }
      });
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadWalletData() async {
    try {
      // Get wallet provider
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Initialize the provider (this loads data from SecureStorage)
      await walletProvider.initialize();
      
      // Set device type
      walletProvider.setDeviceType(widget.isDevice1);
      
      // Get wallet address from provider
      final address = walletProvider.walletAddress;
      
      // Count pending transactions
      _updatePendingTransactionsCount();
      
      setState(() {
        walletAddress = address.isNotEmpty ? address : 'No address available';
        _isLoading = false;
      });
      
      // Fetch real-time balance if we have an address
      if (address.isNotEmpty) {
        await _fetchBalance(address, forceRefresh: true);
      }
      
    } catch (e) {
      print('Error loading wallet data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePendingTransactionsCount() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final isDevice1 = widget.isDevice1;
    final transactions = walletProvider.transactions;
    
    // Filter transactions based on status and device
    final pendingTransactions = transactions.where((tx) {
      if (tx.status == TransactionStatus.completed || 
          tx.status == TransactionStatus.rejected) {
        return false;
      }
      
      if (isDevice1) {
        // For Device 1, show transactions that need approval from Device 1
        // or are waiting for Device 2 approval
        return !tx.approvedByDevice1 || !tx.approvedByDevice2;
      } else {
        // For Device 2, show transactions that need approval from Device 2
        // or are waiting for Device 1 approval
        return !tx.approvedByDevice2 || !tx.approvedByDevice1;
      }
    }).toList();
    
    if (mounted) {
      setState(() {
        _pendingTransactionsCount = pendingTransactions.length;
      });
    }
  }

  Future<void> _syncTransactionsAndBalance() async {
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Sync transactions
      await walletProvider.syncTransactions();
      
      // Update pending transactions count
      _updatePendingTransactionsCount();
      
      // Refresh balance if we have a valid address
      if (walletAddress.isNotEmpty && walletAddress != 'No address available') {
        await _fetchBalance(walletAddress, forceRefresh: true);
      }
      
      print('✅ Sync completed');
    } catch (e) {
      print('💥 Error during sync: $e');
    }
  }

  // Update the _fetchBalance method to handle errors better
  Future<void> _fetchBalance(String address, {bool forceRefresh = false}) async {
    if (address.isEmpty || address == 'No address available') return;
    
    try {
      setState(() {
        _isRefreshing = true;
      });
      
      print('🔄 Fetching balance (forceRefresh: $forceRefresh)');
      print('  📍 Wallet address: $address');
      
      // Get wallet provider to use its balance method
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Test RPC connection first
      await WalletApi.testRpcConnection();
      
      // Get real balance from the blockchain
      final ethBalance = await walletProvider.getWalletBalance(forceRefresh: forceRefresh);
      
      if (mounted) {
        setState(() {
          balance = ethBalance;
          _isRefreshing = false;
        });
        print('✅ Balance updated in UI: $balance ETH');
      }
    } catch (e) {
      print('💥 Error fetching balance: $e');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          // Don't update balance to 0.0 on error - keep previous value
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch balance: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _fetchBalance(address, forceRefresh: true),
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Manual refresh requested');
      
      // Comprehensive sync
      await _syncTransactionsAndBalance();
      
    } catch (e) {
      print('💥 Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openEtherscan() async {
    if (walletAddress != 'No address available') {
      final url = WalletApi.getEtherscanAddressUrl(walletAddress);
      try {
        // Copy URL to clipboard since we can't directly launch it
        await Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Etherscan URL copied to clipboard: $url'),
            backgroundColor: Colors.black,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.neonGreen,
              onPressed: () {},
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Etherscan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyAddressToClipboard() {
    if (walletAddress != 'No address available') {
      Clipboard.setData(ClipboardData(text: walletAddress));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          backgroundColor: Colors.black,
        ),
      );
    }
  }

  void _showFaucetDialog() {
    showDialog(
      context: context,
      builder: (context) => FaucetDialog(walletAddress: walletAddress),
    );
  }

  void _navigateToPendingTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PendingTransactionsPage(),
      ),
    ).then((_) {
      // Refresh data when returning from pending transactions page
      _updatePendingTransactionsCount();
    });
  }

  void _logout() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.clearAllData();
    
    // Navigate to landing page and clear navigation stack
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LandingPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceText = widget.isDevice1 ? 'Device 1 (Primary)' : 'Device 2 (Secondary)';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('BORAYS Crypto Wallet - $deviceText'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Pending transactions button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.pending_actions, color: AppTheme.neonGreen),
                onPressed: _navigateToPendingTransactions,
                tooltip: 'Pending Transactions',
              ),
              if (_pendingTransactionsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _pendingTransactionsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.neonGreen),
            onPressed: _logout,
          ),
        ],
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
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: AppTheme.neonGreen,
              backgroundColor: Colors.black,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Device indicator
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: widget.isDevice1 
                              ? Colors.blue.withOpacity(0.2) 
                              : Colors.purple.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.isDevice1 ? Colors.blue : Colors.purple,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isDevice1 ? Icons.smartphone : Icons.devices_other,
                              color: widget.isDevice1 ? Colors.blue : Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              deviceText,
                              style: TextStyle(
                                color: widget.isDevice1 ? Colors.blue : Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Pending transactions notification
                      if (_pendingTransactionsCount > 0)
                        GestureDetector(
                          onTap: _navigateToPendingTransactions,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pending_actions,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.isDevice1
                                        ? '$_pendingTransactionsCount transaction${_pendingTransactionsCount == 1 ? '' : 's'} pending approval'
                                        : '$_pendingTransactionsCount transaction${_pendingTransactionsCount == 1 ? '' : 's'} pending approval',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.orange,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      Container(
                        margin: const EdgeInsets.all(16.0),
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.neonGreen.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonGreen.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Wallet Address',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.neonGreen,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (walletAddress != 'No address available') ...[
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppTheme.neonGreen, size: 20),
                                    onPressed: _copyAddressToClipboard,
                                    tooltip: 'Copy address',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new, color: AppTheme.neonGreen, size: 20),
                                    onPressed: _openEtherscan,
                                    tooltip: 'View on Etherscan',
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            GestureDetector(
                              onTap: _copyAddressToClipboard,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
                                ),
                                child: Text(
                                  walletAddress,
                                  style: const TextStyle(fontSize: 14.0, color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Balance: ',
                                  style: TextStyle(
                                    fontSize: 24.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                _isRefreshing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.neonGreen,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      '$balance ETH',
                                      style: const TextStyle(
                                        fontSize: 24.0,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.neonGreen,
                                      ),
                                    ),
                              ],
                            ),
                            if (walletAddress != 'No address available') ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () => _fetchBalance(walletAddress, forceRefresh: true),
                                icon: const Icon(Icons.refresh, color: AppTheme.neonGreen, size: 16),
                                label: const Text(
                                  'Refresh Balance',
                                  style: TextStyle(color: AppTheme.neonGreen, fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.send,
                            label: 'Send',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SendTransactionPage(),
                                ),
                              ).then((_) {
                                // Refresh data when returning from send page
                                _updatePendingTransactionsCount();
                                _fetchBalance(walletAddress, forceRefresh: true);
                              });
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.qr_code_scanner,
                            label: 'Receive',
                            onTap: () {
                              // Show QR code for receiving
                              _showReceiveDialog(context, walletAddress);
                            },
                          ),
                          _buildActionButton(
                            icon: Icons.pending_actions,
                            label: 'Pending',
                            badge: _pendingTransactionsCount > 0 ? _pendingTransactionsCount.toString() : null,
                            onTap: _navigateToPendingTransactions,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      
                      // Tab bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.neonGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: AppTheme.neonGreen,
                          unselectedLabelColor: Colors.white60,
                          indicatorColor: AppTheme.neonGreen,
                          tabs: const [
                            Tab(text: 'Assets'),
                            Tab(text: 'NFTs'),
                          ],
                        ),
                      ),
                      
                      // Tab content
                      SizedBox(
                        height: 250,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // Assets Tab
                            _buildAssetsTab(),
                            // NFTs Tab - Simplified
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_outlined,
                                    size: 64,
                                    color: AppTheme.neonGreen.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'NFT functionality coming soon',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Add some bottom padding to avoid overflow
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFaucetDialog();
        },
        backgroundColor: AppTheme.neonGreen,
        foregroundColor: Colors.black,
        child: const Icon(Icons.water_drop),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badge,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.neonGreen.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: AppTheme.neonGreen),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                right: 10,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.black,
          elevation: 4,
          shadowColor: AppTheme.neonGreen.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppTheme.neonGreen.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.neonGreen.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonGreen.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.attach_money, color: AppTheme.neonGreen),
            ),
            title: const Text(
              'Sepolia ETH',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Ethereum Testnet',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Text(
              '$balance ETH',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.neonGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showReceiveDialog(BuildContext context, String address) {
    if (address == 'No address available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No wallet address available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Receive ETH',
          style: TextStyle(color: AppTheme.neonGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share your wallet address:',
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
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      address,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppTheme.neonGreen),
                    onPressed: _copyAddressToClipboard,
                    tooltip: 'Copy address',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Generate real QR code
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: address,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR code to receive ETH',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.neonGreen),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
