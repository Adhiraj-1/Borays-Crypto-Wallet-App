import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/models/transaction.dart';
import 'package:web3_wallet/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:web3_wallet/utils/wallet_api.dart';

class TransactionApprovalPage extends StatefulWidget {
  final String transactionId;
  
  const TransactionApprovalPage({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  _TransactionApprovalPageState createState() => _TransactionApprovalPageState();
}

class _TransactionApprovalPageState extends State<TransactionApprovalPage> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isApproving = false;
  bool _isRejecting = false;
  WalletTransaction? _transaction;
  bool _isRefreshingBalance = false;
  
  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }
  
  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTransaction() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final transaction = await walletProvider.getTransactionById(widget.transactionId);
      
      if (mounted) {
        setState(() {
          _transaction = transaction;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading transaction: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _approveTransaction() async {
    if (_transaction == null) return;
    
    setState(() {
      _isApproving = true;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // For simplicity, we're skipping password verification for now
      // In a real app, you would verify the transaction password here
      
      final success = await walletProvider.approveTransaction(widget.transactionId);
      
      if (mounted) {
        if (success) {
          // First, show the approval message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Reload transaction to show updated status
          await _loadTransaction();
          
          // If both devices have approved, ensure balance is updated
          if (_transaction?.approvedByDevice1 == true && 
              _transaction?.approvedByDevice2 == true) {
            
            setState(() {
              _isRefreshingBalance = true;
            });
            
            // Force refresh balance before showing completion message
            await walletProvider.getWalletBalance();
            
            // Show a more detailed success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction fully approved and submitted to blockchain!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
            
            // Add delay to allow blockchain transaction to process
            await Future.delayed(const Duration(seconds: 3));
            
            // Force one more balance refresh
            await walletProvider.getWalletBalance();
            
            setState(() {
              _isRefreshingBalance = false;
            });
            
            if (mounted) {
              // Open Etherscan link if transaction has a hash
              if (_transaction?.txHash != null && _transaction!.txHash!.isNotEmpty) {
                final etherscanUrl = WalletApi.getEtherscanTxUrl(_transaction!.txHash!);
                await Clipboard.setData(ClipboardData(text: etherscanUrl));
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Etherscan link copied to clipboard'),
                    backgroundColor: Colors.black,
                    action: SnackBarAction(
                      label: 'OK',
                      textColor: AppTheme.neonGreen,
                      onPressed: () {},
                    ),
                  ),
                );
              }
              
              Navigator.pop(context);
              
              // Force refresh on the wallet page when returning
              await walletProvider.syncTransactions();
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to approve transaction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error approving transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApproving = false;
        });
      }
    }
  }
  
  Future<void> _rejectTransaction() async {
    if (_transaction == null) return;
    
    setState(() {
      _isRejecting = true;
    });
    
    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.rejectTransaction(widget.transactionId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction rejected'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // Navigate back after rejection
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject transaction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error rejecting transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRejecting = false;
        });
      }
    }
  }
  
  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.black,
      ),
    );
  }
  
  void _openInEtherscan(String txHash) {
    final url = WalletApi.getEtherscanTxUrl(txHash);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Etherscan URL copied: $url'),
        backgroundColor: Colors.black,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.neonGreen,
          onPressed: () {},
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final walletProvider = Provider.of<WalletProvider>(context);
    final isDevice1 = walletProvider.isDevice1;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transaction Details'),
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
          : _transaction == null
              ? const Center(child: Text('Transaction not found', style: TextStyle(color: Colors.white)))
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Transaction status card
                        _buildStatusCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Transaction details
                        _buildDetailsCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Approval status
                        _buildApprovalStatusCard(isDevice1),
                        
                        const SizedBox(height: 24),
                        
                        // Action buttons
                        _buildActionButtons(isDevice1),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    if (_transaction == null) return const SizedBox.shrink();
    
    // Determine status text and color
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    switch (_transaction!.status) {
      case TransactionStatus.pending:
        statusText = 'Pending Approval';
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
      case TransactionStatus.approvedByDevice1:
        statusText = 'Waiting for Device 2 Approval';
        statusColor = Colors.blue;
        statusIcon = Icons.hourglass_top;
        break;
      case TransactionStatus.approvedByDevice2:
        statusText = 'Waiting for Device 1 Approval';
        statusColor = Colors.purple;
        statusIcon = Icons.hourglass_top;
        break;
      case TransactionStatus.completed:
        statusText = 'Completed';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TransactionStatus.rejected:
        statusText = 'Rejected';
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusText = 'Failed';
        statusColor = Colors.red;
        statusIcon = Icons.error;
    }
    
    // Format date
    final formattedDate = DateFormat('MMMM d, yyyy • h:mm a').format(_transaction!.timestamp);
    
    return Card(
      color: Colors.black,
      elevation: 4,
      shadowColor: statusColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              statusIcon,
              color: statusColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formattedDate,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            if (_transaction!.txHash != null && _transaction!.txHash!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Transaction Hash: ',
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openInEtherscan(_transaction!.txHash!),
                    child: Row(
                      children: [
                        Text(
                          _formatHash(_transaction!.txHash!),
                          style: const TextStyle(
                            color: AppTheme.neonGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          color: AppTheme.neonGreen,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailsCard() {
    if (_transaction == null) return const SizedBox.shrink();
    
    return Card(
      color: Colors.black,
      elevation: 4,
      shadowColor: AppTheme.neonGreen.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.neonGreen.withOpacity(0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Details',
              style: TextStyle(
                color: AppTheme.neonGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            // From address
            _buildDetailRow(
              label: 'From',
              value: _transaction!.from.isEmpty ? 'Loading address...' : _transaction!.from,
              icon: Icons.account_balance_wallet,
              onCopy: _transaction!.from.isEmpty ? null : () => _copyToClipboard(_transaction!.from),
            ),
            
            const SizedBox(height: 16),
            
            // To address
            _buildDetailRow(
              label: 'To',
              value: _transaction!.to,
              icon: Icons.arrow_forward,
              onCopy: () => _copyToClipboard(_transaction!.to),
            ),
            
            const SizedBox(height: 16),
            
            // Amount
            _buildDetailRow(
              label: 'Amount',
              value: '${_transaction!.amount} ETH',
              icon: Icons.attach_money,
              valueColor: AppTheme.neonGreen,
              valueFontSize: 18,
              showCopyIcon: false,
            ),
            
            const SizedBox(height: 16),
            
            // Transaction ID
            _buildDetailRow(
              label: 'Transaction ID',
              value: _transaction!.id,
              icon: Icons.tag,
              onCopy: () => _copyToClipboard(_transaction!.id),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onCopy,
    Color? valueColor,
    double? valueFontSize,
    bool showCopyIcon = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.neonGreen,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: valueColor ?? Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: valueFontSize ?? 14,
                      ),
                    ),
                  ),
                  if (showCopyIcon && onCopy != null)
                    IconButton(
                      icon: const Icon(
                        Icons.copy,
                        color: AppTheme.neonGreen,
                        size: 16,
                      ),
                      onPressed: onCopy,
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      tooltip: 'Copy to clipboard',
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildApprovalStatusCard(bool isDevice1) {
    if (_transaction == null) return const SizedBox.shrink();
    
    return Card(
      color: Colors.black,
      elevation: 4,
      shadowColor: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approval Status',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white24),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildDeviceApprovalStatus(
                    deviceNumber: 1,
                    isApproved: _transaction!.approvedByDevice1,
                    isCurrentDevice: isDevice1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDeviceApprovalStatus(
                    deviceNumber: 2,
                    isApproved: _transaction!.approvedByDevice2,
                    isCurrentDevice: !isDevice1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDeviceApprovalStatus({
    required int deviceNumber,
    required bool isApproved,
    required bool isCurrentDevice,
  }) {
    final deviceColor = deviceNumber == 1 ? Colors.blue : Colors.purple;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isApproved 
            ? Colors.green.withOpacity(0.1) 
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isApproved 
              ? Colors.green.withOpacity(0.5) 
              : Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                deviceNumber == 1 ? Icons.smartphone : Icons.tablet_android,
                color: deviceColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Device $deviceNumber',
                style: TextStyle(
                  color: deviceColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isApproved 
                  ? Colors.green.withOpacity(0.2) 
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isApproved ? Icons.check : Icons.pending,
              color: isApproved ? Colors.green : Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isApproved ? 'Approved' : 'Pending',
            style: TextStyle(
              color: isApproved ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isCurrentDevice && !isApproved) ...[
            const SizedBox(height: 8),
            const Text(
              'Your approval needed',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(bool isDevice1) {
    if (_transaction == null) return const SizedBox.shrink();
    
    // Determine if this device has already approved
    final hasApproved = isDevice1 
        ? _transaction!.approvedByDevice1 
        : _transaction!.approvedByDevice2;
    
    // Don't show action buttons for completed or rejected transactions
    if (_transaction!.status == TransactionStatus.completed || 
        _transaction!.status == TransactionStatus.rejected) {
      return ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.neonGreen,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Back to Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasApproved) ...[
          ElevatedButton(
            onPressed: _isApproving || _isRefreshingBalance ? null : _approveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.green.withOpacity(0.3),
            ),
            child: _isApproving || _isRefreshingBalance
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        _isApproving ? 'Approving...' : 'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Approve Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _isRejecting ? null : _rejectTransaction,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            child: _isRejecting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Rejecting...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Reject Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ] else ...[
          // If this device has already approved, show waiting message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_top,
                  color: Colors.blue,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for ${isDevice1 ? 'Device 2' : 'Device 1'} approval',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This transaction has been approved from your device and is waiting for approval from the other device.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _isRejecting ? null : _rejectTransaction,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            child: _isRejecting
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.red,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Cancelling...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Cancel Transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Back to Transactions'),
        ),
      ],
    );
  }
  
  String _formatHash(String hash) {
    if (hash.length < 10) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }
}
