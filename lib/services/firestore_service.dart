import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart';
import 'dart:convert';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _walletsCollection = 'wallets';
  static const String _transactionsCollection = 'transactions';
  static const String _devicesCollection = 'devices';
  static const String _syncCollection = 'sync_data';

  // ==================== DEVICE MANAGEMENT ====================
  
  /// Register a device in Firestore
  static Future<bool> registerDevice({
    required String userId,
    required String deviceId,
    required int deviceType, // 1 or 2
    required String deviceName,
  }) async {
    try {
      await _firestore
          .collection(_devicesCollection)
          .doc('${userId}_device_$deviceType')
          .set({
        'user_id': userId,
        'device_id': deviceId,
        'device_type': deviceType,
        'device_name': deviceName,
        'registered_at': FieldValue.serverTimestamp(),
        'last_seen': FieldValue.serverTimestamp(),
        'is_active': true,
      }, SetOptions(merge: true));
      
      print('Device $deviceType registered for user: $userId');
      return true;
    } catch (e) {
      print('Error registering device: $e');
      return false;
    }
  }

  /// Update device last seen timestamp
  static Future<void> updateDeviceLastSeen(String userId, int deviceType) async {
    try {
      await _firestore
          .collection(_devicesCollection)
          .doc('${userId}_device_$deviceType')
          .update({
        'last_seen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating device last seen: $e');
    }
  }

  /// Check if both devices are registered
  static Future<Map<String, bool>> checkDevicesStatus(String userId) async {
    try {
      final device1Doc = await _firestore
          .collection(_devicesCollection)
          .doc('${userId}_device_1')
          .get();
      
      final device2Doc = await _firestore
          .collection(_devicesCollection)
          .doc('${userId}_device_2')
          .get();
      
      return {
        'device1_registered': device1Doc.exists,
        'device2_registered': device2Doc.exists,
      };
    } catch (e) {
      print('Error checking devices status: $e');
      return {'device1_registered': false, 'device2_registered': false};
    }
  }

  // ==================== WALLET MANAGEMENT ====================
  
  /// Save wallet data to Firestore
  static Future<bool> saveWalletData({
    required String userId,
    required String walletAddress,
    required Map<String, dynamic> walletData,
  }) async {
    try {
      await _firestore
          .collection(_walletsCollection)
          .doc(userId)
          .set({
        'wallet_address': walletAddress,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'wallet_data': walletData,
        'is_active': true,
      }, SetOptions(merge: true));
      
      print('Wallet data saved to Firestore for user: $userId');
      return true;
    } catch (e) {
      print('Error saving wallet data to Firestore: $e');
      return false;
    }
  }

  /// Get wallet data from Firestore
  static Future<Map<String, dynamic>?> getWalletData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_walletsCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting wallet data from Firestore: $e');
      return null;
    }
  }

  // ==================== TRANSACTION MANAGEMENT ====================
  
  /// Save transaction to Firestore for multi-device approval
  static Future<bool> saveTransaction({
    required String userId,
    required WalletTransaction transaction,
  }) async {
    try {
      await _firestore
          .collection(_transactionsCollection)
          .doc(transaction.id)
          .set({
        'user_id': userId,
        'transaction_id': transaction.id,
        'from_address': transaction.from,
        'to_address': transaction.to,
        'amount': transaction.amount,
        'status': transaction.status.name,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'approved_by_device1': transaction.approvedByDevice1,
        'approved_by_device2': transaction.approvedByDevice2,
        'tx_hash': transaction.txHash,
        'error': transaction.error,
        'device1_signature_share': transaction.device1SignatureShare,
        'device2_signature_share': transaction.device2SignatureShare,
      }, SetOptions(merge: true));
      
      print('Transaction saved to Firestore: ${transaction.id}');
      return true;
    } catch (e) {
      print('Error saving transaction to Firestore: $e');
      return false;
    }
  }

  /// Update transaction approval status
  static Future<bool> updateTransactionApproval({
    required String transactionId,
    required int deviceType,
    required bool approved,
    String? signatureShare,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (deviceType == 1) {
        updateData['approved_by_device1'] = approved;
        updateData['device1_approval_at'] = FieldValue.serverTimestamp();
        if (signatureShare != null) {
          updateData['device1_signature_share'] = signatureShare;
        }
      } else {
        updateData['approved_by_device2'] = approved;
        updateData['device2_approval_at'] = FieldValue.serverTimestamp();
        if (signatureShare != null) {
          updateData['device2_signature_share'] = signatureShare;
        }
      }

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update(updateData);
      
      print('Transaction approval updated: $transactionId by device $deviceType');
      return true;
    } catch (e) {
      print('Error updating transaction approval: $e');
      return false;
    }
  }

  /// Update transaction status (completed, failed, etc.)
  static Future<bool> updateTransactionStatus({
    required String transactionId,
    required TransactionStatus status,
    String? txHash,
    String? error,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status.name,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (txHash != null) {
        updateData['tx_hash'] = txHash;
        updateData['completed_at'] = FieldValue.serverTimestamp();
      }

      if (error != null) {
        updateData['error'] = error;
      }

      await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .update(updateData);
      
      print('Transaction status updated: $transactionId to ${status.name}');
      return true;
    } catch (e) {
      print('Error updating transaction status: $e');
      return false;
    }
  }

  /// Get pending transactions for a user
  static Future<List<WalletTransaction>> getPendingTransactions(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('user_id', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'approvedByDevice1', 'approvedByDevice2'])
          .orderBy('created_at', descending: true)
          .get();

      List<WalletTransaction> transactions = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final transaction = _firestoreToTransaction(data);
          transactions.add(transaction);
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
        }
      }

      return transactions;
    } catch (e) {
      print('Error getting pending transactions: $e');
      return [];
    }
  }

  /// Get all transactions for a user
  static Future<List<WalletTransaction>> getAllTransactions(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection(_transactionsCollection)
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(100) // Limit to last 100 transactions
          .get();

      List<WalletTransaction> transactions = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final transaction = _firestoreToTransaction(data);
          transactions.add(transaction);
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
        }
      }

      return transactions;
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  // ==================== REAL-TIME LISTENERS ====================
  
  /// Listen to pending transactions for real-time updates
  static Stream<List<WalletTransaction>> listenToPendingTransactions(String userId) {
    return _firestore
        .collection(_transactionsCollection)
        .where('user_id', isEqualTo: userId)
        .where('status', whereIn: ['pending', 'approvedByDevice1', 'approvedByDevice2'])
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      List<WalletTransaction> transactions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final transaction = _firestoreToTransaction(data);
          transactions.add(transaction);
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
        }
      }
      return transactions;
    });
  }

  /// Listen to a specific transaction for real-time updates
  static Stream<WalletTransaction?> listenToTransaction(String transactionId) {
    return _firestore
        .collection(_transactionsCollection)
        .doc(transactionId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return _firestoreToTransaction(data);
        } catch (e) {
          print('Error parsing transaction $transactionId: $e');
          return null;
        }
      }
      return null;
    });
  }

  // ==================== UTILITY METHODS ====================
  
  /// Convert Firestore document to WalletTransaction
  static WalletTransaction _firestoreToTransaction(Map<String, dynamic> data) {
    return WalletTransaction(
      id: data['transaction_id'] ?? '',
      from: data['from_address'] ?? '',
      to: data['to_address'] ?? '',
      amount: data['amount'] ?? '0',
      txHash: data['tx_hash'],
      timestamp: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: TransactionStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      approvedByDevice1: data['approved_by_device1'] ?? false,
      approvedByDevice2: data['approved_by_device2'] ?? false,
      device1SignatureShare: data['device1_signature_share'],
      device2SignatureShare: data['device2_signature_share'],
      error: data['error'],
    );
  }

  /// Test Firestore connection
  static Future<bool> testConnection() async {
    try {
      await _firestore
          .collection('test')
          .add({
        'test_message': 'Firestore connection test',
        'timestamp': FieldValue.serverTimestamp(),
        'app_version': '1.0.0',
      });
      
      print('Firestore connection test successful!');
      return true;
    } catch (e) {
      print('Firestore connection test failed: $e');
      return false;
    }
  }

  /// Clear all test data (for development)
  static Future<void> clearTestData() async {
    try {
      final testDocs = await _firestore.collection('test').get();
      for (var doc in testDocs.docs) {
        await doc.reference.delete();
      }
      print('Test data cleared from Firestore');
    } catch (e) {
      print('Error clearing test data: $e');
    }
  }

  /// Get a specific transaction by ID
  static Future<WalletTransaction?> getTransactionById(String transactionId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_transactionsCollection)
          .doc(transactionId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _firestoreToTransaction(data);
      }

      return null;
    } catch (e) {
      print('Error getting transaction by ID from Firestore: $e');
      return null;
    }
  }
}
