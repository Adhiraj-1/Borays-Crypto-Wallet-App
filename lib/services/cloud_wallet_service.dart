import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as Math;
import '../models/transaction.dart';

class CloudWalletService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection names
  static const String _walletsCollection = 'wallets';
  static const String _transactionsSubcollection = 'transactions';
  static const String _devicesSubcollection = 'devices';
  static const String _userDataCollection = 'userData';

  // ==================== MNEMONIC HASHING ====================
  
  /// Hash mnemonic for secure storage and lookup
  static String hashMnemonic(String mnemonic) {
    final normalizedMnemonic = mnemonic
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    
    final hash = sha256.convert(utf8.encode(normalizedMnemonic)).toString();
    
    print('🔑 CloudWalletService.hashMnemonic:');
    print('  📝 Original: "$mnemonic"');
    print('  🔧 Normalized: "$normalizedMnemonic"');
    print('  🏷️ Hash (DocID): $hash');
    
    return hash;
  }

  /// Verify if a mnemonic matches a stored hash
  static bool verifyMnemonicHash(String mnemonic, String storedHash) {
    return hashMnemonic(mnemonic) == storedHash;
  }

  // ==================== WALLET DATA STORAGE ====================

  /// Save complete wallet data to Firebase - CRITICAL FUNCTION
  static Future<bool> saveCompleteWalletData({
    required String walletId,
    required String walletAddress,
    required String privateKey,
    required String mnemonic,
    required String publicKey,
    required String device1Password,
    required String device1TxPassword,
    required String device2Password,
    required String device2TxPassword,
    required String device1MnemonicPart,
    required String device2MnemonicPart,
    required Map<String, dynamic> additionalData,
  }) async {
    try {
      print('💾 CloudWalletService: Saving complete wallet data to Firebase...');
      print('  🆔 Wallet ID: $walletId');
      print('  📍 Wallet Address: $walletAddress');
      
      // CRITICAL: Validate passwords are not empty
      if (device1Password.isEmpty || device2Password.isEmpty || 
        device1TxPassword.isEmpty || device2TxPassword.isEmpty) {
        print('❌ ERROR: One or more passwords are empty!');
        print('  Device1 Password: "${device1Password}" (length: ${device1Password.length})');
        print('  Device1 Tx Password: "${device1TxPassword}" (length: ${device1TxPassword.length})');
        print('  Device2 Password: "${device2Password}" (length: ${device2Password.length})');
        print('  Device2 Tx Password: "${device2TxPassword}" (length: ${device2TxPassword.length})');
        return false;
      }
      
      print('  🔐 Device1 Password: "$device1Password" ✓');
      print('  🔐 Device1 Tx Password: "$device1TxPassword" ✓');
      print('  🔐 Device2 Password: "$device2Password" ✓');
      print('  🔐 Device2 Tx Password: "$device2TxPassword" ✓');
      print('  📝 Device1 Words: $device1MnemonicPart');
      print('  📝 Device2 Words: $device2MnemonicPart');
      
      // Prepare the complete data object with explicit password values
      final completeWalletData = {
        'walletAddress': walletAddress,
        'privateKey': privateKey,
        'mnemonic': mnemonic,
        'publicKey': publicKey,
        'device1Password': device1Password,
        'device1TransactionPassword': device1TxPassword,
        'device2Password': device2Password,
        'device2TransactionPassword': device2TxPassword,
        'device1MnemonicPart': device1MnemonicPart,
        'device2MnemonicPart': device2MnemonicPart,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'additionalData': additionalData,
      };
      
      print('📦 Complete data object prepared with ${completeWalletData.keys.length} fields');
      print('📦 Password fields in data object:');
      print('  device1Password: "${completeWalletData['device1Password']}"');
      print('  device1TransactionPassword: "${completeWalletData['device1TransactionPassword']}"');
      print('  device2Password: "${completeWalletData['device2Password']}"');
      print('  device2TransactionPassword: "${completeWalletData['device2TransactionPassword']}"');
      
      // Save main wallet document to userData collection
      await _firestore.collection(_userDataCollection).doc(walletId).set(
        completeWalletData, 
        SetOptions(merge: false) // Use merge: false to ensure complete overwrite
      );
      
      print('✅ Main wallet data saved to userData/$walletId');

      // Also save to wallets collection for backward compatibility
      final mnemonicHash = hashMnemonic(mnemonic);
      await _firestore.collection(_walletsCollection).doc(mnemonicHash).set({
        'walletAddress': walletAddress,
        'publicKey': publicKey,
        'walletId': walletId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'additionalData': additionalData,
      }, SetOptions(merge: false));
      
      print('✅ Backup wallet data saved to wallets/$mnemonicHash');

      // CRITICAL: Verify the data was actually saved with passwords
      final verificationDoc = await _firestore.collection(_userDataCollection).doc(walletId).get();
      if (verificationDoc.exists) {
        final savedData = verificationDoc.data() as Map<String, dynamic>;
        print('✅ Verification successful - Found ${savedData.keys.length} fields in Firebase');
        print('  📍 Wallet Address: ${savedData['walletAddress']}');
        print('  🔐 Device1 Password: "${savedData['device1Password']}"');
        print('  🔐 Device1 Tx Password: "${savedData['device1TransactionPassword']}"');
        print('  🔐 Device2 Password: "${savedData['device2Password']}"');
        print('  🔐 Device2 Tx Password: "${savedData['device2TransactionPassword']}"');
        print('  📝 Device1 Words: ${savedData['device1MnemonicPart']}');
        print('  📝 Device2 Words: ${savedData['device2MnemonicPart']}');
      
        // Check if all critical fields are present and NOT empty
        final requiredFields = [
          'walletAddress', 'privateKey', 'mnemonic', 'publicKey',
          'device1Password', 'device1TransactionPassword',
          'device2Password', 'device2TransactionPassword',
          'device1MnemonicPart', 'device2MnemonicPart'
        ];
        
        bool allFieldsPresent = true;
        for (String field in requiredFields) {
          final value = savedData[field];
          if (value == null || value.toString().isEmpty || value.toString() == '-') {
            print('❌ Missing or empty field: $field = "$value"');
            allFieldsPresent = false;
          } else {
            print('✅ Field OK: $field = "${value.toString().substring(0, Math.min(20, value.toString().length))}..."');
          }
        }
        
        if (allFieldsPresent) {
          print('✅ ALL REQUIRED FIELDS ARE PRESENT AND NON-EMPTY IN FIREBASE');
          return true;
        } else {
          print('❌ SOME REQUIRED FIELDS ARE MISSING OR EMPTY');
          return false;
        }
      } else {
        print('❌ Verification failed - Document not found in Firebase');
        return false;
      }

    } catch (e) {
      print('💥 Error saving wallet data: $e');
      print('💥 Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Get complete wallet data from Firebase
  static Future<Map<String, dynamic>?> getCompleteWalletData(String walletId) async {
    try {
      print('🔍 Getting complete wallet data from Firebase...');
      print('  🆔 Wallet ID: $walletId');
      
      DocumentSnapshot doc = await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        print('✅ Wallet data retrieved from Firebase with ${data.keys.length} fields');
        print('  📍 Wallet Address: ${data['walletAddress']}');
        print('  🔐 Device1 Password: ${data['device1Password']}');
        print('  📝 Device1 Words: ${data['device1MnemonicPart']}');
        return data;
      }

      print('❌ No wallet data found for wallet: $walletId');
      return null;
    } catch (e) {
      print('💥 Error getting wallet data: $e');
      return null;
    }
  }

  /// Update wallet data in Firebase
  static Future<bool> updateWalletData(String walletId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_userDataCollection).doc(walletId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating wallet data: $e');
      return false;
    }
  }

  // ==================== DEVICE MANAGEMENT ====================

  /// Register device with complete data
  static Future<bool> registerDevice({
    required String walletId,
    required String deviceId,
    required String deviceName,
    required int deviceType,
    required String password,
    required String transactionPassword,
    required String mnemonicPart,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      print('📱 Registering device: $deviceName (Type: $deviceType)');
      
      await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .collection(_devicesSubcollection)
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'password': password,
        'transactionPassword': transactionPassword,
        'mnemonicPart': mnemonicPart,
        'deviceInfo': deviceInfo,
        'registeredAt': FieldValue.serverTimestamp(),
        'lastSeenAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: true));

      print('✅ Device registered: $deviceName');
      return true;
    } catch (e) {
      print('💥 Error registering device: $e');
      return false;
    }
  }

  /// Verify device credentials
  static Future<Map<String, dynamic>?> verifyDeviceCredentials({
    required String mnemonicPart,
    required int deviceType,
    required String password,
  }) async {
    try {
      print('🔍 Verifying device credentials...');
      print('  📝 Mnemonic: "$mnemonicPart"');
      print('  🔢 Device type: $deviceType');
      print('  🔐 Password: "${password.replaceAll(RegExp(r'.'), '*')}"');
      
      // Normalize inputs
      final normalizedInputMnemonic = mnemonicPart.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final normalizedInputPassword = password.trim();
      
      // Search all wallets for matching device
      QuerySnapshot walletsSnapshot = await _firestore
          .collection(_userDataCollection)
          .get();

      for (var walletDoc in walletsSnapshot.docs) {
        final walletId = walletDoc.id;
        final walletData = walletDoc.data() as Map<String, dynamic>;
        
        // Get stored mnemonic part and password for this device type
        String? storedMnemonicPart;
        String? storedPassword;
        
        if (deviceType == 1) {
          storedMnemonicPart = walletData['device1MnemonicPart'] as String?;
          storedPassword = walletData['device1Password'] as String?;
        } else {
          storedMnemonicPart = walletData['device2MnemonicPart'] as String?;
          storedPassword = walletData['device2Password'] as String?;
        }

        if (storedMnemonicPart != null && storedPassword != null) {
          final normalizedStoredMnemonic = storedMnemonicPart.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
          final normalizedStoredPassword = storedPassword.trim();

          print('  🔍 Checking wallet $walletId:');
          print('    📝 Mnemonic match: ${normalizedInputMnemonic == normalizedStoredMnemonic}');
          print('    🔐 Password match: ${normalizedInputPassword == normalizedStoredPassword}');

          if (normalizedInputMnemonic == normalizedStoredMnemonic &&
              normalizedInputPassword == normalizedStoredPassword) {
          
            print('✅ Device credentials verified for wallet $walletId');
          
            return {
              'walletId': walletId,
              'deviceId': 'device_${deviceType}_${walletId}', // Generate consistent device ID
              'deviceType': deviceType,
              'walletData': walletData,
              'deviceData': {
                'mnemonicPart': storedMnemonicPart,
                'password': storedPassword,
                'deviceType': deviceType,
              },
            };
          }
        }
      }

      print('❌ Device credentials verification failed');
      return null;
    } catch (e) {
      print('💥 Error verifying device credentials: $e');
      return null;
    }
  }

  /// Update device last seen
  static Future<void> updateDeviceLastSeen(String walletId, String deviceId) async {
    try {
      await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .collection(_devicesSubcollection)
          .doc(deviceId)
          .update({
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating device last seen: $e');
    }
  }

  // ==================== TRANSACTION MANAGEMENT ====================

  /// Save transaction to Firebase
  static Future<bool> saveTransaction({
    required String walletId,
    required WalletTransaction transaction,
  }) async {
    try {
      await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .collection(_transactionsSubcollection)
          .doc(transaction.id)
          .set(transaction.toJson(), SetOptions(merge: true));

      print('✅ Transaction saved: ${transaction.id}');
      return true;
    } catch (e) {
      print('💥 Error saving transaction: $e');
      return false;
    }
  }

  /// Get all transactions for wallet
  static Future<List<WalletTransaction>> getWalletTransactions(String walletId, {int limit = 100}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .collection(_transactionsSubcollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      List<WalletTransaction> transactions = [];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          transactions.add(WalletTransaction.fromJson(data));
        } catch (e) {
          print('Error parsing transaction ${doc.id}: $e');
        }
      }

      return transactions;
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// Update transaction in Firebase
  static Future<bool> updateTransaction({
    required String walletId,
    required String transactionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .collection(_transactionsSubcollection)
          .doc(transactionId)
          .update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  // ==================== BALANCE MANAGEMENT ====================

  /// Save wallet balance to Firebase
  static Future<bool> saveWalletBalance(String walletId, String balance) async {
    try {
      await _firestore.collection(_userDataCollection).doc(walletId).update({
        'balance': balance,
        'lastBalanceUpdate': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error saving balance: $e');
      return false;
    }
  }

  /// Get wallet balance from Firebase
  static Future<String?> getWalletBalance(String walletId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['balance'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting balance: $e');
      return null;
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if wallet exists
  static Future<bool> walletExists(String walletId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(_userDataCollection)
          .doc(walletId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking wallet existence: $e');
      return false;
    }
  }

  /// Delete all wallet data
  static Future<bool> deleteWalletData(String walletId) async {
    try {
      // Delete wallet document and all subcollections
      await _firestore.collection(_userDataCollection).doc(walletId).delete();
      
      // Note: Subcollections need to be deleted manually in a real app
      // This is a simplified version
      
      return true;
    } catch (e) {
      print('Error deleting wallet data: $e');
      return false;
    }
  }

  /// Test Firebase connection
  static Future<bool> testConnection() async {
    try {
      await _firestore
          .collection('test_connection')
          .add({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      print('✅ Firebase connection successful');
      return true;
    } catch (e) {
      print('❌ Firebase connection failed: $e');
      return false;
    }
  }

  // ==================== LEGACY SUPPORT METHODS ====================
  
  /// Verify device mnemonic part (FIXED VERSION)
  static Future<Map<String, dynamic>?> verifyDeviceMnemonicPart({
    required String mnemonicPart,
    required int deviceType,
  }) async {
    try {
      print('🔍 CloudWalletService.verifyDeviceMnemonicPart - FIXED VERSION');
      print('  📝 Input mnemonic: "$mnemonicPart"');
      print('  🔢 Device type: $deviceType');
      
      // Normalize input mnemonic
      final normalizedInput = mnemonicPart.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      print('  🔧 Normalized input: "$normalizedInput"');
      
      // Search all wallets for matching device mnemonic part
      QuerySnapshot walletsSnapshot = await _firestore
          .collection(_userDataCollection)
          .get();

      print('  📊 Found ${walletsSnapshot.docs.length} wallets to check');

      for (var walletDoc in walletsSnapshot.docs) {
        final walletId = walletDoc.id;
        final walletData = walletDoc.data() as Map<String, dynamic>;
        
        // Get the correct mnemonic part based on device type
        String? storedMnemonicPart;
        if (deviceType == 1) {
          storedMnemonicPart = walletData['device1MnemonicPart'] as String?;
        } else {
          storedMnemonicPart = walletData['device2MnemonicPart'] as String?;
        }

        if (storedMnemonicPart != null) {
          final normalizedStored = storedMnemonicPart.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
        
          print('  🔍 Checking wallet $walletId:');
          print('    📝 Stored (device$deviceType): "$normalizedStored"');
          print('    📝 Input:  "$normalizedInput"');
          print('    ✅ Match: ${normalizedInput == normalizedStored}');

          if (normalizedInput == normalizedStored) {
            print('✅ FOUND MATCHING MNEMONIC for device $deviceType in wallet $walletId');
            return {
              'walletId': walletId,
              'walletAddress': walletData['walletAddress'],
              'publicKey': walletData['publicKey'],
              'deviceType': deviceType,
              'walletData': walletData,
            };
          }
        } else {
          print('  ⚠️ No device${deviceType}MnemonicPart found in wallet $walletId');
        }
      }

      print('❌ NO MATCHING MNEMONIC FOUND for device $deviceType');
      return null;
    } catch (e) {
      print('💥 Error in verifyDeviceMnemonicPart: $e');
      print('💥 Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}
