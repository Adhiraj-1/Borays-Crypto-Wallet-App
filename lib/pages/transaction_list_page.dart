import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  _TransactionListPageState createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  final TextEditingController _transactionPasswordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedTransactionId;

  @override
  void dispose() {
    _transactionPasswordController.dispose();
    super.dispose();
  }

  // Show approval dialog
  void _showApprovalDialog(String transactionId) {
    setState(() {
      _selectedTransactionId = transactionId;
      _transactionPasswordController.clear();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.neonGreen, width: 1),
        ),
        title: const Text(
          'Approve Transaction',
          style: TextStyle(color: AppTheme.neonGreen),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your transaction password to approve this transaction',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _transactionPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Transaction Password',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.black38,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.neonGreen.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.neonGreen),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: AppTheme.neonGreen,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _approveTransaction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: Colors.black,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  // Show reject confirmation dialog
  void _showRejectDialog(String transactionId) {
    setState(() {
      _selectedTransactionId = transactionId;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.red, width: 1),
        ),
        title: const Text(
          'Reject Transaction',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to reject this transaction? This action cannot be undone.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _rejectTransaction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Approve transaction
  Future<void> _approveTransaction() async {
    if (_selectedTransactionId == null) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.approveTransaction(
      _selectedTransactionId!,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to approve transaction. Invalid password.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reject transaction
  Future<void> _rejectTransaction() async {
    if (_selectedTransactionId == null) return;

    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final success = await walletProvider.rejectTransaction(_selectedTransactionId!);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reject transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format transaction status
  String _formatTransactionStatus(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.approvedByDevice1:
        return 'Approved by Device 1';
      case TransactionStatus.approvedByDevice2:
        return 'Approved by Device 2';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.rejected:
        return 'Rejected';
      case TransactionStatus.failed:
        return 'Failed';
      default:
        return 'Unknown'; // Add default return value
    }
  }

  // Get color for transaction status
  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.approvedByDevice1:
      case TransactionStatus.approvedByDevice2:
        return Colors.blue;
      case TransactionStatus.completed:
        return AppTheme.neonGreen;
      case TransactionStatus.rejected:
        return Colors.red;
      case TransactionStatus.failed:
        return Colors.red.shade900;
      default:
        return Colors.grey; // Add default return value
    }
  }

  // Format amount with ETH suffix
  String _formatAmount(String amount) {
    return '$amount ETH';
  }

  // Format address to shorter version
  String _formatAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  // Can current device approve this transaction?
  bool _canApprove(WalletTransaction transaction, bool isDevice1) {
    if (transaction.status == TransactionStatus.completed || 
        transaction.status == TransactionStatus.rejected) {
      return false;
    }
    
    if (isDevice1 && !transaction.approvedByDevice1) {
      return true;
    }
    
    if (!isDevice1 && !transaction.approvedByDevice2) {
      return true;
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transactions'),
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
        child: Consumer<WalletProvider>(
          builder: (context, walletProvider, child) {
            final transactions = walletProvider.transactions;
            final isDevice1 = walletProvider.isDevice1;
            
            if (transactions.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 64,
                      color: AppTheme.neonGreen,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When you create or receive transactions, they will appear here',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return ListView.builder(
              padding: const EdgeInsets.only(top: 100, bottom: 24, left: 16, right: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                final canApprove = _canApprove(transaction, isDevice1);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(transaction.status).withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(transaction.status).withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              transaction.status == TransactionStatus.completed
                                  ? Icons.check_circle_outline
                                  : transaction.status == TransactionStatus.rejected
                                      ? Icons.cancel_outlined
                                      : Icons.pending_outlined,
                              color: _getStatusColor(transaction.status),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatTransactionStatus(transaction.status),
                                style: TextStyle(
                                  color: _getStatusColor(transaction.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              _formatAmount(transaction.amount),
                              style: const TextStyle(
                                color: AppTheme.neonGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Transaction details
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'From',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      Text(
                                        _formatAddress(transaction.from),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white30,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'To',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      Text(
                                        _formatAddress(transaction.to),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Date',
                                        style: TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                      Text(
                                        '${transaction.timestamp.day}/${transaction.timestamp.month}/${transaction.timestamp.year} ${transaction.timestamp.hour}:${transaction.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                if (transaction.txHash != null && transaction.txHash!.isNotEmpty)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Transaction Hash',
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Text(
                                          _formatAddress(transaction.txHash!),
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Approval status
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                _buildApprovalStatus('Device 1', transaction.approvedByDevice1),
                                const SizedBox(width: 16),
                                _buildApprovalStatus('Device 2', transaction.approvedByDevice2),
                              ],
                            ),
                            
                            // Approval Actions
                            if (canApprove) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showApprovalDialog(transaction.id),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.neonGreen,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _showRejectDialog(transaction.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildApprovalStatus(String device, bool isApproved) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isApproved ? AppTheme.neonGreen.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isApproved ? AppTheme.neonGreen.withOpacity(0.5) : Colors.red.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isApproved ? Icons.check_circle : Icons.pending,
              color: isApproved ? AppTheme.neonGreen : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    isApproved ? 'Approved' : 'Pending',
                    style: TextStyle(
                      color: isApproved ? AppTheme.neonGreen : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
