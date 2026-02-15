import 'package:flutter/material.dart';

class TransactionInfo {
  static void showSecurityInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dual Device Security Model'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How It Works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This wallet uses a 2-of-2 threshold signature scheme (TSS) for enhanced security:',
              ),
              SizedBox(height: 16),
              _buildSecurityStep(
                '1',
                'Key Splitting',
                'Your private key is mathematically split between two devices. Neither device has the complete key.',
              ),
              _buildSecurityStep(
                '2',
                'Transaction Creation',
                'When you create a transaction on Device 1, it creates a partial signature using its key share.',
              ),
              _buildSecurityStep(
                '3',
                'Transaction Approval',
                'Device 2 must approve the transaction by contributing its key share to complete the signature.',
              ),
              _buildSecurityStep(
                '4',
                'Blockchain Submission',
                'Only after both devices have contributed can the transaction be submitted to the blockchain.',
              ),
              SizedBox(height: 24),
              Text(
                'Security Benefits',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('Protection against single device compromise'),
              _buildBulletPoint('Malware on one device cannot steal funds'),
              _buildBulletPoint('Physical theft of one device doesn\'t expose your wallet'),
              _buildBulletPoint('Enforces a two-factor authentication model'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _buildSecurityStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class InfoStep {
  final String title;
  final String description;
  final IconData icon;

  InfoStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
