import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/models/transaction.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:web3_wallet/pages/transaction_approval_page.dart';
import 'package:intl/intl.dart';

class PendingTransactionsPage extends StatefulWidget {
  const PendingTransactionsPage({Key? key}) : super(key: key);

  @override
  _PendingTransactionsPageState createState() => _PendingTransactionsPageState();
}

class _PendingTransactionsPageState extends State<PendingTransactionsPage> {
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }
  
  Future<void> _refreshTransactions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await Provider.of<WalletProvider>(context, listen: false).syncTransactions();
    } catch (e) {
      print('Error refreshing transactions: $e');
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
    final walletProvider = Provider.of<WalletProvider>(context);
    final isDevice1 = walletProvider.isDevice1;
    
    // Filter transactions based on status and device
    final pendingTransactions = walletProvider.transactions.where((tx) {
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
    
    // Sort by timestamp (newest first)
    pendingTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Pending Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.neonGreen),
            onPressed: _refreshTransactions,
            tooltip: 'Refresh transactions',
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
          : SafeArea(
              child: pendingTransactions.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _refreshTransactions,
                    color: AppTheme.neonGreen,
                    backgroundColor: Colors.black,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: pendingTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = pendingTransactions[index];
                        return _buildTransactionCard(context, transaction);
                      },
                    ),
                  ),
            ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.neonGreen.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No pending transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All transactions have been processed',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionCard(BuildContext context, WalletTransaction transaction) {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final isDevice1 = walletProvider.isDevice1;
    
    // Determine status text and color
    String statusText;
    Color statusColor;
    
    if (transaction.status == TransactionStatus.pending) {
      statusText = 'Pending Approval';
      statusColor = Colors.orange;
    } else if (transaction.status == TransactionStatus.approvedByDevice1) {
      statusText = 'Waiting for Device 2 Approval';
      statusColor = Colors.blue;
    } else if (transaction.status == TransactionStatus.approvedByDevice2) {
      statusText = 'Waiting for Device 1 Approval';
      statusColor = Colors.purple;
    } else if (transaction.status == TransactionStatus.completed) {
      statusText = 'Completed';
      statusColor = Colors.green;
    } else if (transaction.status == TransactionStatus.rejected) {
      statusText = 'Rejected';
      statusColor = Colors.red;
    } else {
      statusText = 'Failed';
      statusColor = Colors.red;
    }
    
    // Format date
    final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(transaction.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionApprovalPage(transactionId: transaction.id),
            ),
          ).then((_) {
            // Refresh after returning from approval page
            _refreshTransactions();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pending_actions,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Transaction details
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'From:',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      transaction.from.isEmpty 
                          ? 'Loading address...' 
                          : _formatAddress(transaction.from),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(
                    Icons.arrow_forward,
                    color: AppTheme.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'To:',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatAddress(transaction.to),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(
                    Icons.attach_money,
                    color: AppTheme.neonGreen,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Amount:',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${transaction.amount} ETH',
                    style: const TextStyle(
                      color: AppTheme.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white54,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Approval status
              Row(
                children: [
                  Expanded(
                    child: _buildApprovalStatus(
                      isDevice1: true,
                      isApproved: transaction.approvedByDevice1,
                      isCurrentDevice: isDevice1,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildApprovalStatus(
                      isDevice1: false,
                      isApproved: transaction.approvedByDevice2,
                      isCurrentDevice: !isDevice1,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionApprovalPage(transactionId: transaction.id),
                        ),
                      ).then((_) {
                        // Refresh after returning from approval page
                        _refreshTransactions();
                      });
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.neonGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.neonGreen.withOpacity(0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildApprovalStatus({
    required bool isDevice1,
    required bool isApproved,
    required bool isCurrentDevice,
  }) {
    final deviceText = isDevice1 ? 'Device 1' : 'Device 2';
    final deviceColor = isDevice1 ? Colors.blue : Colors.purple;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: isApproved 
            ? Colors.green.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isApproved 
              ? Colors.green.withOpacity(0.5) 
              : Colors.grey.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDevice1 ? Icons.smartphone : Icons.tablet_android,
            color: deviceColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceText,
                  style: TextStyle(
                    color: deviceColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isApproved ? 'Approved' : 'Pending',
                  style: TextStyle(
                    color: isApproved ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isApproved ? Icons.check_circle : Icons.pending,
            color: isApproved ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }
  
  String _formatAddress(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}
