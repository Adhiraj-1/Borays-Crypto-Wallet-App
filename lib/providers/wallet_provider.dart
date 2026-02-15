import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:web3_wallet/utils/wallet_api.dart';
import 'package:web3_wallet/models/transaction.dart';
import 'package:web3_wallet/services/cloud_wallet_service.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletProvider with ChangeNotifier {
  
  String _walletAddress = '';
  String _walletId = '';
  String _mnemonic = '';
  String _privateKey = '';
  bool _isDevice1 = true;
  List<WalletTransaction> _transactions = [];
  bool _isInitialized = false;
  bool _isAuthenticated = false;
  String _currentDeviceId = '';

  // Getters
  String get walletAddress => _walletAddress;
  String get walletId => _walletId;
  String get mnemonic => _mnemonic;
  String get privateKey => _privateKey;
  bool get isDevice1 => _isDevice1;
  List<WalletTransaction> get transactions => _transactions;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _isAuthenticated;
  String get currentDeviceId => _currentDeviceId;

  // Legacy getter for backward compatibility
  String get userId => _walletId;

  // ==================== INITIALIZATION ====================
  
  Future<void> initialize() async {
    try {
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing wallet provider: $e');
    }
  }

  // ==================== WALLET CREATION ====================
  
  Future<bool> createWallet(
    String mnemonic,
    String device1Password,
    String device1TxPassword,
    String device2Password,
    String device2TxPassword,
  ) async {
    try {
      print('🔄 WalletProvider.createWallet called');
      print('  📝 Mnemonic: ${mnemonic.substring(0, 20)}...');
      print('  🔐 Device1 Password: "$device1Password"');
      print('  🔐 Device1 Tx Password: "$device1TxPassword"');
      print('  🔐 Device2 Password: "$device2Password"');
      print('  🔐 Device2 Tx Password: "$device2TxPassword"');
      
      // CRITICAL: Validate that actual passwords are provided
      if (device1Password.isEmpty || device2Password.isEmpty || 
          device1TxPassword.isEmpty || device2TxPassword.isEmpty) {
        print('❌ ERROR: Empty passwords provided to createWallet');
        return false;
      }
      
      // Generate wallet from mnemonic
      final walletData = await WalletApi.createWalletFromMnemonic(mnemonic);
      print('✅ Generated wallet address: ${walletData['address']}');
      
      // Generate wallet ID
      _walletId = _generateWalletId();
      print('🆔 Generated wallet ID: $_walletId');
      
      // Split mnemonic parts
      final splitParts = splitMnemonic(mnemonic);
      print('📝 Device 1 words: ${splitParts['device1']}');
      print('📝 Device 2 words: ${splitParts['device2']}');
      
      print('🔐 ACTUAL passwords being saved:');
      print('  Device1 Password: "$device1Password"');
      print('  Device1 Tx Password: "$device1TxPassword"');
      print('  Device2 Password: "$device2Password"');
      print('  Device2 Tx Password: "$device2TxPassword"');
      
      // Save complete wallet data to Firebase
      print('💾 Saving ALL wallet data to Firebase...');
      final success = await CloudWalletService.saveCompleteWalletData(
        walletId: _walletId,
        walletAddress: walletData['address']!,
        privateKey: walletData['privateKey']!,
        mnemonic: mnemonic,
        publicKey: walletData['publicKey'] ?? '',
        device1Password: device1Password,
        device1TxPassword: device1TxPassword,
        device2Password: device2Password,
        device2TxPassword: device2TxPassword,
        device1MnemonicPart: splitParts['device1']!,
        device2MnemonicPart: splitParts['device2']!,
        additionalData: {
          'created_by_wallet': _walletId,
          'app_version': '1.0.0',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      if (success) {
        print('✅ Complete wallet data saved to Firebase');
        
        // Register both devices
        await _registerDeviceInFirebase(1, 'Device 1', device1Password, device1TxPassword, splitParts['device1']!);
        await _registerDeviceInFirebase(2, 'Device 2', device2Password, device2TxPassword, splitParts['device2']!);
        
        // Update local state
        _walletAddress = walletData['address']!;
        _mnemonic = mnemonic;
        _privateKey = walletData['privateKey']!;
        _isInitialized = true;
        _isAuthenticated = true;
        
        // Verify data was saved by reading it back
        await _verifyDataSaved();
        
        print('✅ Wallet created and saved to Firebase successfully');
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to save wallet data to Firebase');
        return false;
      }
      
    } catch (e) {
      print('💥 Error creating wallet: $e');
      return false;
    }
  }

  /// Verify that all data was properly saved to Firebase
  Future<void> _verifyDataSaved() async {
    try {
      print('🔍 Verifying data was saved to Firebase...');
      final savedData = await CloudWalletService.getCompleteWalletData(_walletId);
      
      if (savedData != null) {
        print('✅ Verification successful - Data found in Firebase:');
        print('  📍 Wallet Address: ${savedData['walletAddress']}');
        print('  🔐 Device1 Password: ${savedData['device1Password']}');
        print('  🔐 Device2 Password: ${savedData['device2Password']}');
        print('  📝 Device1 Words: ${savedData['device1MnemonicPart']}');
        print('  📝 Device2 Words: ${savedData['device2MnemonicPart']}');
        print('  🔑 Private Key: ${savedData['privateKey']?.substring(0, 10)}...');
        print('  📝 Full Mnemonic: ${savedData['mnemonic']?.substring(0, 20)}...');
      } else {
        print('❌ Verification failed - No data found in Firebase!');
      }
    } catch (e) {
      print('💥 Error verifying saved data: $e');
    }
  }

  Future<void> _registerDeviceInFirebase(
    int deviceType,
    String deviceName,
    String password,
    String transactionPassword,
    String mnemonicPart,
  ) async {
    try {
      final deviceId = _generateDeviceId();
      
      await CloudWalletService.registerDevice(
        walletId: _walletId,
        deviceId: deviceId,
        deviceName: deviceName,
        deviceType: deviceType,
        password: password,
        transactionPassword: transactionPassword,
        mnemonicPart: mnemonicPart,
        deviceInfo: {
          'platform': 'flutter',
          'registeredAt': DateTime.now().toIso8601String(),
        },
      );
      
      print('✅ $deviceName registered in Firebase');
    } catch (e) {
      print('💥 Error registering $deviceName: $e');
    }
  }

  // ==================== DEVICE VERIFICATION & LOGIN ====================

  /// Verify device mnemonic part and prepare for login
  Future<Map<String, dynamic>?> verifyDeviceMnemonicPart({
    required String mnemonicPart,
    required int deviceType, // 1 for device1, 2 for device2
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final fieldName = deviceType == 1 ? 'device1MnemonicPart' : 'device2MnemonicPart';

      final query = await firestore
          .collection('userData')
          .where(fieldName, isEqualTo: mnemonicPart)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return {
          'walletId': doc.id,
          ...doc.data(), // All wallet info for later use
        };
      } else {
        return null;
      }
    } catch (e) {
      print("Error verifying mnemonic: $e");
      return null;
    }
  }

  /// Complete device login with password (updated signature)
  Future<bool> completeDeviceLogin(String password) async {
    try {
      print('🔄 WalletProvider.completeDeviceLogin called');
      return false;
    } catch (e) {
      print('💥 Error completing device login: $e');
      return false;
    }
  }

  /// Complete device login with full credentials
  Future<bool> completeDeviceLoginWithCredentials({
    required String mnemonicPart,
    required int deviceType,
    required String password,
  }) async {
    try {
      print('🔄 WalletProvider.completeDeviceLoginWithCredentials called');
      print('  📝 Mnemonic: "$mnemonicPart"');
      print('  🔢 Device type: $deviceType');
      print('  🔐 Password: "${password.replaceAll(RegExp(r'.'), '*')}"');
      
      // Verify device credentials against Firebase
      final verificationResult = await CloudWalletService.verifyDeviceCredentials(
        mnemonicPart: mnemonicPart,
        deviceType: deviceType,
        password: password,
      );
      
      if (verificationResult != null) {
        _walletId = verificationResult['walletId'];
        _currentDeviceId = verificationResult['deviceId'];
        _isDevice1 = (deviceType == 1);
        
        // Load complete wallet data
        final walletData = verificationResult['walletData'] as Map<String, dynamic>;
        _walletAddress = walletData['walletAddress'] ?? '';
        _mnemonic = walletData['mnemonic'] ?? '';
        _privateKey = walletData['privateKey'] ?? '';
        
        // Load transactions
        _transactions = await CloudWalletService.getWalletTransactions(_walletId);
        
        // Update device last seen
        await CloudWalletService.updateDeviceLastSeen(_walletId, _currentDeviceId);
        
        _isAuthenticated = true;
        _isInitialized = true;
        
        print('✅ Device login completed successfully');
        notifyListeners();
        return true;
      }
      
      print('❌ Device login failed - invalid credentials');
      return false;
    } catch (e) {
      print('💥 Error completing device login: $e');
      return false;
    }
  }

  // ==================== TRANSACTION MANAGEMENT ====================
  
  Future<bool> createTransaction(
    String to,
    String amount,
    String password,
  ) async {
    try {
      if (!_isAuthenticated) return false;
      
      // Get wallet data to verify transaction password
      final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
      if (walletData == null) return false;
      
      final storedTxPassword = _isDevice1
          ? walletData['device1TransactionPassword']
          : walletData['device2TransactionPassword'];

      if (storedTxPassword != password) {
        return false;
      }

      // Create new transaction
      final transaction = WalletTransaction(
        id: _generateTransactionId(),
        from: _walletAddress,
        to: to,
        amount: amount,
        timestamp: DateTime.now(),
        status: TransactionStatus.pending,
        approvedByDevice1: _isDevice1,
        approvedByDevice2: !_isDevice1,
      );

      // Save to Firebase
      final success = await CloudWalletService.saveTransaction(
        walletId: _walletId,
        transaction: transaction,
      );
      
      if (success) {
        _transactions.add(transaction);
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      print('Error creating transaction: $e');
      return false;
    }
  }

  Future<bool> approveTransaction(String transactionId) async {
    try {
      if (!_isAuthenticated) return false;
      
      final transactionIndex = _transactions.indexWhere((tx) => tx.id == transactionId);
      if (transactionIndex == -1) return false;

      final transaction = _transactions[transactionIndex];

      // Update approval status
      if (_isDevice1) {
        transaction.approvedByDevice1 = true;
      } else {
        transaction.approvedByDevice2 = true;
      }

      // Check if both devices have approved
      if (transaction.approvedByDevice1 && transaction.approvedByDevice2) {
        // Execute the transaction
        try {
          final txHash = await WalletApi.sendTransaction(
            _privateKey,
            transaction.to,
            transaction.amount,
          );
          
          transaction.txHash = txHash;
          transaction.status = TransactionStatus.completed;
        } catch (e) {
          print('Error executing transaction: $e');
          transaction.status = TransactionStatus.failed;
        }
      } else {
        // Update status based on which device approved
        if (_isDevice1) {
          transaction.status = TransactionStatus.approvedByDevice1;
        } else {
          transaction.status = TransactionStatus.approvedByDevice2;
        }
      }

      // Update in Firebase
      await CloudWalletService.updateTransaction(
        walletId: _walletId,
        transactionId: transactionId,
        updates: {
          'approvedByDevice1': transaction.approvedByDevice1,
          'approvedByDevice2': transaction.approvedByDevice2,
          'status': transaction.status.name,
          'txHash': transaction.txHash,
        },
      );

      _transactions[transactionIndex] = transaction;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error approving transaction: $e');
      return false;
    }
  }

  Future<bool> rejectTransaction(String transactionId) async {
    try {
      if (!_isAuthenticated) return false;
      
      final transactionIndex = _transactions.indexWhere((tx) => tx.id == transactionId);
      if (transactionIndex == -1) return false;

      // Update in Firebase
      await CloudWalletService.updateTransaction(
        walletId: _walletId,
        transactionId: transactionId,
        updates: {
          'status': TransactionStatus.rejected.name,
        },
      );

      _transactions[transactionIndex].status = TransactionStatus.rejected;
      notifyListeners();

      return true;
    } catch (e) {
      print('Error rejecting transaction: $e');
      return false;
    }
  }

  Future<void> syncTransactions() async {
    if (_isAuthenticated) {
      _transactions = await CloudWalletService.getWalletTransactions(_walletId);
      notifyListeners();
    }
  }

  // ==================== BALANCE MANAGEMENT ====================
  
  Future<String> getWalletBalance({bool forceRefresh = false}) async {
  try {
    print('🔄 Getting wallet balance (forceRefresh: $forceRefresh)');
    print('  📍 Current wallet address: $_walletAddress');
    print('  🔐 Is authenticated: $_isAuthenticated');
    
    if (!_isAuthenticated || _walletAddress.isEmpty) {
      print('❌ Not authenticated or no wallet address');
      return '0.0';
    }

    // Always fetch fresh balance from blockchain when forceRefresh is true
    if (forceRefresh) {
      print('🔄 Force refreshing balance from blockchain...');
      final balance = await WalletApi.getEthBalance(_walletAddress);
      
      // Save to Firebase cache
      if (_walletId.isNotEmpty) {
        await CloudWalletService.saveWalletBalance(_walletId, balance);
      }
      
      print('✅ Fresh balance: $balance ETH');
      return balance;
    }

    // Try to get cached balance from Firebase first
    if (_walletId.isNotEmpty) {
      final cachedBalance = await CloudWalletService.getWalletBalance(_walletId);
      if (cachedBalance != null) {
        print('📦 Using cached balance: $cachedBalance ETH');
        return cachedBalance;
      }
    }

    // Fetch fresh balance from blockchain as fallback
    print('🔄 No cached balance, fetching from blockchain...');
    final balance = await WalletApi.getEthBalance(_walletAddress);

    // Save to Firebase cache
    if (_walletId.isNotEmpty) {
      await CloudWalletService.saveWalletBalance(_walletId, balance);
    }

    print('✅ Balance fetched: $balance ETH');
    return balance;
  } catch (e) {
    print('💥 Error getting wallet balance: $e');
    // Don't return 0.0 on error, rethrow to handle in UI
    throw Exception('Failed to fetch balance: $e');
  }
}

  // ==================== UTILITY METHODS ====================
  
  String generateMnemonic({int strength = 256}) {
    return bip39.generateMnemonic(strength: strength);
  }

  Map<String, String> splitMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(' ');
    
    if (words.length != 24) {
      throw Exception('Mnemonic must be exactly 24 words, got ${words.length}');
    }
    
    final firstHalf = words.take(12).join(' ');
    final secondHalf = words.skip(12).take(12).join(' ');
    
    return {
      'device1': firstHalf,
      'device2': secondHalf,
    };
  }

  String _generateTransactionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'tx_${timestamp}_$randomNum';
  }

  String _generateWalletId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'wallet_${timestamp}_$randomNum';
  }

  String _generateDeviceId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'device_${timestamp}_$randomNum';
  }

  // ==================== SESSION MANAGEMENT ====================
  
  void setDeviceType(bool isDevice1) {
    _isDevice1 = isDevice1;
    notifyListeners();
  }

  Future<bool> login(String password) async {
    return false;
  }

  Future<bool> doesWalletExist() async {
    return _isAuthenticated && _walletAddress.isNotEmpty;
  }

  Future<void> clearAllData() async {
    _walletAddress = '';
    _walletId = '';
    _mnemonic = '';
    _privateKey = '';
    _isDevice1 = true;
    _transactions = [];
    _isInitialized = false;
    _isAuthenticated = false;
    _currentDeviceId = '';
    
    // Clear temporary passwords
    _tempDevice1Password = null;
    _tempDevice1TxPassword = null;
    _tempDevice2Password = null;
    _tempDevice2TxPassword = null;
    
    notifyListeners();
  }

  // ==================== LEGACY SUPPORT METHODS ====================
  
  Future<bool> importWallet(String mnemonic) async {
    return false;
  }

  Future<void> initializeWalletCreation(String fullMnemonic) async {
    // Use Future.microtask to avoid setState during build
    Future.microtask(() {
      _mnemonic = fullMnemonic;
      notifyListeners();
    });
  }

  // ==================== PASSWORD MANAGEMENT METHODS ====================

  // Temporary password storage during wallet creation
  String? _tempDevice1Password;
  String? _tempDevice1TxPassword;
  String? _tempDevice2Password;
  String? _tempDevice2TxPassword;

  Future<void> setDevice1Password(String password) async {
    print('🔐 Storing Device1 password: "$password"');
    _tempDevice1Password = password;
    notifyListeners();
  }

  Future<void> setDevice1TransactionPassword(String password) async {
    print('🔐 Storing Device1 transaction password: "$password"');
    _tempDevice1TxPassword = password;
    notifyListeners();
  }

  Future<void> setDevice2Password(String password) async {
    print('🔐 Storing Device2 password: "$password"');
    _tempDevice2Password = password;
    notifyListeners();
  }

  Future<void> setDevice2TransactionPassword(String password) async {
    print('🔐 Storing Device2 transaction password: "$password"');
    _tempDevice2TxPassword = password;
    notifyListeners();
  }

  // Password retrieval methods (now retrieve from Firebase)
  Future<String?> getDevice1Password() async {
    if (_tempDevice1Password != null) {
      return _tempDevice1Password;
    }
    if (!_isAuthenticated) return null;
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    return walletData?['device1Password'];
  }

  Future<String?> getDevice1TransactionPassword() async {
    if (_tempDevice1TxPassword != null) {
      return _tempDevice1TxPassword;
    }
    if (!_isAuthenticated) return null;
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    return walletData?['device1TransactionPassword'];
  }

  Future<String?> getDevice2Password() async {
    if (_tempDevice2Password != null) {
      return _tempDevice2Password;
    }
    if (!_isAuthenticated) return null;
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    return walletData?['device2Password'];
  }

  Future<String?> getDevice2TransactionPassword() async {
    if (_tempDevice2TxPassword != null) {
      return _tempDevice2TxPassword;
    }
    if (!_isAuthenticated) return null;
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    return walletData?['device2TransactionPassword'];
  }

  // Public setters for login functionality
  void setWalletId(String walletId) {
    _walletId = walletId;
    notifyListeners();
  }

  void setWalletAddress(String address) {
    _walletAddress = address;
    notifyListeners();
  }

  void setMnemonic(String mnemonic) {
    _mnemonic = mnemonic;
    notifyListeners();
  }

  void setPrivateKey(String privateKey) {
    _privateKey = privateKey;
    notifyListeners();
  }

  void setAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    notifyListeners();
  }

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  Future<bool> finalizeWalletCreation(
    String fullMnemonic,
    String device1Password,
    String device1TxPassword,
    String device2Password,
    String device2TxPassword,
  ) async {
    // Use stored passwords if provided parameters are empty
    final d1Pass = device1Password.isNotEmpty ? device1Password : (_tempDevice1Password ?? '');
    final d1TxPass = device1TxPassword.isNotEmpty ? device1TxPassword : (_tempDevice1TxPassword ?? '');
    final d2Pass = device2Password.isNotEmpty ? device2Password : (_tempDevice2Password ?? '');
    final d2TxPass = device2TxPassword.isNotEmpty ? device2TxPassword : (_tempDevice2TxPassword ?? '');
    
    print('🔄 finalizeWalletCreation using:');
    print('  Device1 Password: "$d1Pass"');
    print('  Device1 Tx Password: "$d1TxPass"');
    print('  Device2 Password: "$d2Pass"');
    print('  Device2 Tx Password: "$d2TxPass"');
    
    final success = await createWallet(
      fullMnemonic,
      d1Pass,
      d1TxPass,
      d2Pass,
      d2TxPass,
    );
    
    // Clear temporary passwords after wallet creation
    if (success) {
      _tempDevice1Password = null;
      _tempDevice1TxPassword = null;
      _tempDevice2Password = null;
      _tempDevice2TxPassword = null;
    }
    
    return success;
  }

  Future<WalletTransaction?> getTransactionById(String transactionId) async {
    return _transactions.where((tx) => tx.id == transactionId).firstOrNull;
  }

  List<WalletTransaction> getPendingApprovalsForDevice() {
    return _transactions.where((tx) {
      if (_isDevice1) {
        return !tx.approvedByDevice1 && 
               (tx.status == TransactionStatus.pending || 
                tx.status == TransactionStatus.approvedByDevice2);
      } else {
        return !tx.approvedByDevice2 && 
               (tx.status == TransactionStatus.pending || 
               tx.status == TransactionStatus.approvedByDevice1);
      }
    }).toList();
  }

  Future<bool> isDeviceSetupComplete(int deviceType) async {
    if (!_isAuthenticated) return false;
    
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    if (walletData == null) return false;
    
    if (deviceType == 1) {
      return walletData['device1Password'] != null && 
             walletData['device1TransactionPassword'] != null;
    } else {
      return walletData['device2Password'] != null && 
             walletData['device2TransactionPassword'] != null;
    }
  }

  Future<bool> testCloudConnection() async {
    return await CloudWalletService.testConnection();
  }

  Future<void> printAllStoredData() async {
    print('=== ALL DATA NOW STORED IN FIREBASE ===');
    if (_isAuthenticated) {
      final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
      print('Wallet Data: $walletData');
    } else {
      print('Wallet not authenticated');
    }
  }

  Future<String?> getDeviceMnemonicPart(bool isDevice1) async {
    if (!_isAuthenticated) return null;
    final walletData = await CloudWalletService.getCompleteWalletData(_walletId);
    if (isDevice1) {
      return walletData?['device1MnemonicPart'];
    } else {
      return walletData?['device2MnemonicPart'];
    }
  }

  Future<bool> verifyMnemonicPart(String mnemonicPart) async {
    final storedPart = await getDeviceMnemonicPart(_isDevice1);
    return storedPart == mnemonicPart;
  }
}
