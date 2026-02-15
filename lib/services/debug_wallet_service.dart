import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_wallet_service.dart';

class DebugWalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Debug method to check if a wallet exists and print detailed info
  static Future<void> debugWalletLookup(String mnemonic) async {
    print('\n=== DEBUG WALLET LOOKUP ===');
    print('Input mnemonic: "$mnemonic"');
    print('Mnemonic word count: ${mnemonic.split(' ').length}');
    
    // Test hash generation
    final hash = CloudWalletService.hashMnemonic(mnemonic);
    print('Generated hash: $hash');
    
    try {
      // Check if document exists
      final doc = await _firestore
          .collection('wallets')
          .doc(hash)
          .get();
      
      print('Document exists: ${doc.exists}');
      
      if (doc.exists) {
        print('Document data: ${doc.data()}');
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print('Wallet address: ${data['walletAddress']}');
          print('Created at: ${data['createdAt']}');
          print('Device count: ${data['deviceCount']}');
        }
      } else {
        print('Document does not exist in Firestore');
        
        // List all wallet documents to see what's actually there
        final allWallets = await _firestore.collection('wallets').get();
        print('Total wallets in Firestore: ${allWallets.docs.length}');
        
        for (var walletDoc in allWallets.docs) {
          print('  Document ID: ${walletDoc.id}');
          final data = walletDoc.data();
          print('  Wallet address: ${data['walletAddress']}');
        }
      }
    } catch (e) {
      print('Error during debug lookup: $e');
    }
    
    print('=== END DEBUG ===\n');
  }

  /// Test mnemonic normalization
  static void testMnemonicNormalization(String mnemonic) {
    print('\n=== MNEMONIC NORMALIZATION TEST ===');
    print('Original: "$mnemonic"');
    
    // Test different variations
    final variations = [
      mnemonic,
      mnemonic.toLowerCase(),
      mnemonic.toUpperCase(),
      mnemonic.trim(),
      mnemonic.trim().toLowerCase(),
      mnemonic.replaceAll(RegExp(r'\s+'), ' '),
      mnemonic.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '),
    ];
    
    for (int i = 0; i < variations.length; i++) {
      final variation = variations[i];
      final hash = CloudWalletService.hashMnemonic(variation);
      print('Variation $i: "$variation" -> $hash');
    }
    
    print('=== END NORMALIZATION TEST ===\n');
  }

  /// Check what's actually in Firestore
  static Future<void> listAllWallets() async {
    print('\n=== ALL WALLETS IN FIRESTORE ===');
    
    try {
      final snapshot = await _firestore.collection('wallets').get();
      print('Total wallets: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        print('\nDocument ID (hash): ${doc.id}');
        final data = doc.data();
        print('  Wallet address: ${data['walletAddress']}');
        print('  Created at: ${data['createdAt']}');
        print('  Device count: ${data['deviceCount'] ?? 0}');
        print('  Transaction count: ${data['transactionCount'] ?? 0}');
      }
    } catch (e) {
      print('Error listing wallets: $e');
    }
    
    print('=== END WALLET LIST ===\n');
  }
}
