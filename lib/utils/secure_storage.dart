import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ==================== CORE STORAGE METHODS ====================
  
  // Read a value from secure storage
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      print('Error reading from secure storage: $e');
      return null;
    }
  }

  // Write a value to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('Stored data for key: $key');
    } catch (e) {
      print('Error writing to secure storage: $e');
      throw e;
    }
  }

  // Delete a value from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      print('Deleted data for key: $key');
    } catch (e) {
      print('Error deleting from secure storage: $e');
      throw e;
    }
  }

  // Clear all secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('Cleared all secure storage');
    } catch (e) {
      print('Error clearing secure storage: $e');
      throw e;
    }
  }

  // ==================== WALLET DATA STORAGE ====================

  // Store wallet address
  Future<void> saveWalletAddress(String address) async {
    await write('wallet_address', address);
  }

  // Get wallet address
  Future<String?> getWalletAddress() async {
    return await read('wallet_address');
  }

  // Store complete wallet data
  Future<void> saveWalletData(String walletData) async {
    await write('wallet_data', walletData);
  }

  // Get complete wallet data
  Future<String?> getWalletData() async {
    return await read('wallet_data');
  }

  // Store private key
  Future<void> savePrivateKey(String privateKey) async {
    await write('private_key', privateKey);
  }

  // Get private key
  Future<String?> getPrivateKey() async {
    return await read('private_key');
  }

  // Store mnemonic phrase
  Future<void> saveMnemonic(String mnemonic) async {
    await write('mnemonic', mnemonic);
  }

  // Get mnemonic phrase
  Future<String?> getMnemonic() async {
    return await read('mnemonic');
  }

  // Store public key
  Future<void> savePublicKey(String publicKey) async {
    await write('public_key', publicKey);
  }

  // Get public key
  Future<String?> getPublicKey() async {
    return await read('public_key');
  }

  // ==================== DEVICE PASSWORDS ====================

  // Store device 1 password
  Future<void> storeDevice1Password(String password) async {
    await write('device1_password', password);
  }

  // Get device 1 password
  Future<String?> getDevice1Password() async {
    return await read('device1_password');
  }

  // Store device 1 transaction password
  Future<void> storeDevice1TransactionPassword(String password) async {
    await write('device1_transaction_password', password);
  }

  // Get device 1 transaction password
  Future<String?> getDevice1TransactionPassword() async {
    return await read('device1_transaction_password');
  }

  // Store device 2 password
  Future<void> storeDevice2Password(String password) async {
    await write('device2_password', password);
  }

  // Get device 2 password
  Future<String?> getDevice2Password() async {
    return await read('device2_password');
  }

  // Store device 2 transaction password
  Future<void> storeDevice2TransactionPassword(String password) async {
    await write('device2_transaction_password', password);
  }

  // Get device 2 transaction password
  Future<String?> getDevice2TransactionPassword() async {
    return await read('device2_transaction_password');
  }

  // ==================== MNEMONIC PARTS ====================

  // Store device 1 mnemonic part
  Future<void> storeDevice1MnemonicPart(String mnemonicPart) async {
    await write('device1_mnemonic_part', mnemonicPart);
  }

  // Get device 1 mnemonic part
  Future<String?> getDevice1MnemonicPart() async {
    return await read('device1_mnemonic_part');
  }

  // Store device 2 mnemonic part
  Future<void> storeDevice2MnemonicPart(String mnemonicPart) async {
    await write('device2_mnemonic_part', mnemonicPart);
  }

  // Get device 2 mnemonic part
  Future<String?> getDevice2MnemonicPart() async {
    return await read('device2_mnemonic_part');
  }

  // ==================== KEY SHARES ====================

  // Store device 1 key share
  Future<void> storeDevice1KeyShare(String keyShare) async {
    await write('device1_key_share', keyShare);
  }

  // Get device 1 key share
  Future<String?> getDevice1KeyShare() async {
    return await read('device1_key_share');
  }

  // Store device 2 key share
  Future<void> storeDevice2KeyShare(String keyShare) async {
    await write('device2_key_share', keyShare);
  }

  // Get device 2 key share
  Future<String?> getDevice2KeyShare() async {
    return await read('device2_key_share');
  }

  // ==================== TRANSACTIONS ====================

  // Store transactions
  Future<void> saveTransactions(String transactions) async {
    await write('transactions', transactions);
    print('Saved transactions to secure storage');
  }

  // Get transactions
  Future<String?> getTransactions() async {
    return await read('transactions');
  }

  // ==================== WALLET BALANCE ====================

  // Store wallet balance
  Future<void> saveWalletBalance(String balance) async {
    await write('wallet_balance', balance);
    await storeLastBalanceUpdate(DateTime.now());
  }

  // Get wallet balance
  Future<String?> getWalletBalance() async {
    return await read('wallet_balance');
  }

  // Get last balance update time
  Future<DateTime?> getLastBalanceUpdate() async {
    return await getLastBalanceUpdateSecure();
  }

  // ==================== DEVICE SETTINGS ====================

  // Store device type
  Future<void> storeDeviceType(bool isDevice1) async {
    await write('device_type', isDevice1.toString());
  }

  // Get device type
  Future<bool> getDeviceType() async {
    final deviceType = await read('device_type');
    return deviceType == 'true';
  }

  // Store device ID (SINGLE IMPLEMENTATION - REMOVED DUPLICATE)
  Future<void> storeDeviceId(String deviceId) async {
    await write('device_id', deviceId);
  }

  // Get device ID (SINGLE IMPLEMENTATION - REMOVED DUPLICATE)
  Future<String?> getDeviceId() async {
    return await read('device_id');
  }

  // ==================== TEMPORARY STORAGE ====================

  // Store temporary full mnemonic (during wallet creation)
  Future<void> storeTempFullMnemonic(String mnemonic) async {
    await write('temp_full_mnemonic', mnemonic);
  }

  // Get temporary full mnemonic
  Future<String?> getTempFullMnemonic() async {
    return await read('temp_full_mnemonic');
  }

  // Clear temporary full mnemonic
  Future<void> clearTempFullMnemonic() async {
    await delete('temp_full_mnemonic');
  }

  // ==================== WALLET STATE ====================

  // Store wallet initialization state
  Future<void> storeWalletInitialized(bool isInitialized) async {
    await write('wallet_initialized', isInitialized.toString());
  }

  // Get wallet initialization state
  Future<bool> getWalletInitialized() async {
    final initialized = await read('wallet_initialized');
    return initialized == 'true';
  }

  // Store last sync time
  Future<void> storeLastSyncTime(DateTime syncTime) async {
    await write('last_sync_time', syncTime.millisecondsSinceEpoch.toString());
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final syncTimeStr = await read('last_sync_time');
    if (syncTimeStr != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(syncTimeStr));
    }
    return null;
  }

  // ==================== USER ID MANAGEMENT ====================

  // Store user ID
  Future<void> saveUserId(String userId) async {
    await write('user_id', userId);
  }

  // Get user ID
  Future<String?> getUserId() async {
    return await read('user_id');
  }

  // ==================== UTILITY METHODS ====================

  // Check if wallet exists
  Future<bool> doesWalletExist() async {
    final address = await getWalletAddress();
    return address != null && address.isNotEmpty;
  }

  // Check if device setup is complete
  Future<bool> isDeviceSetupComplete(bool isDevice1) async {
    if (isDevice1) {
      final password = await getDevice1Password();
      final txPassword = await getDevice1TransactionPassword();
      final mnemonicPart = await getDevice1MnemonicPart();
      return password != null && txPassword != null && mnemonicPart != null;
    } else {
      final password = await getDevice2Password();
      final txPassword = await getDevice2TransactionPassword();
      final mnemonicPart = await getDevice2MnemonicPart();
      return password != null && txPassword != null && mnemonicPart != null;
    }
  }

  // Get all wallet data as JSON
  Future<Map<String, dynamic>> getAllWalletData() async {
    return {
      'wallet_address': await getWalletAddress(),
      'wallet_data': await getWalletData(),
      'private_key': await getPrivateKey(),
      'mnemonic': await getMnemonic(),
      'public_key': await getPublicKey(),
      'device1_password': await getDevice1Password(),
      'device1_transaction_password': await getDevice1TransactionPassword(),
      'device2_password': await getDevice2Password(),
      'device2_transaction_password': await getDevice2TransactionPassword(),
      'device1_mnemonic_part': await getDevice1MnemonicPart(),
      'device2_mnemonic_part': await getDevice2MnemonicPart(),
      'device1_key_share': await getDevice1KeyShare(),
      'device2_key_share': await getDevice2KeyShare(),
      'transactions': await getTransactions(),
      'wallet_balance': await getWalletBalance(),
      'device_type': await getDeviceType(),
      'device_id': await getDeviceId(),
      'wallet_initialized': await getWalletInitialized(),
      'last_sync_time': (await getLastSyncTime())?.toIso8601String(),
    };
  }

  // Store complete wallet backup
  Future<void> storeWalletBackup(Map<String, dynamic> backupData) async {
    final backupJson = jsonEncode(backupData);
    await write('wallet_backup', backupJson);
  }

  // Get complete wallet backup
  Future<Map<String, dynamic>?> getWalletBackup() async {
    final backupJson = await read('wallet_backup');
    if (backupJson != null) {
      return jsonDecode(backupJson);
    }
    return null;
  }

  // Store last balance update time in secure storage
  Future<void> storeLastBalanceUpdate(DateTime updateTime) async {
    await write('last_balance_update', updateTime.millisecondsSinceEpoch.toString());
  }

  // Get last balance update time from secure storage  
  Future<DateTime?> getLastBalanceUpdateSecure() async {
    final timestamp = await read('last_balance_update');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
    }
    return null;
  }

  // ==================== DEBUG METHODS ====================

  // Print all stored keys (for debugging)
  Future<void> printAllKeys() async {
    try {
      final allData = await getAllWalletData();
      print('=== ALL STORED DATA ===');
      allData.forEach((key, value) {
        if (value != null) {
          print('$key: ${value.toString().length > 50 ? value.toString().substring(0, 50) + "..." : value}');
        }
      });
      print('=====================');
    } catch (e) {
      print('Error printing all keys: $e');
    }
  }
}
