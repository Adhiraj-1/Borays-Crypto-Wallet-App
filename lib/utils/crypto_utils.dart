import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:web3dart/crypto.dart' as web3_crypto;

class CryptoUtils {
  // Convert bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return web3_crypto.bytesToHex(bytes);
  }
  
  // Convert hex string to bytes
  static Uint8List hexToBytes(String hexStr) {
    return web3_crypto.hexToBytes(hexStr);
  }
  
  // Keccak256 hash function
  static Uint8List keccak256(Uint8List input) {
    return web3_crypto.keccak256(input);
  }
  
  // Derive private key from mnemonic
  static String derivePrivateKeyFromMnemonic(String mnemonic) {
    // This is a simplified implementation
    // In a real app, you would use BIP39 and BIP32 to derive the private key
    final bytes = utf8.encode(mnemonic);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  // Encrypt data with password
  static String encryptData(String data, String password) {
    // Simple XOR encryption for demonstration
    final List<int> dataBytes = utf8.encode(data);
    final List<int> keyBytes = utf8.encode(password);
    final List<int> encrypted = [];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encrypted);
  }
  
  // Decrypt data with password
  static String decryptData(String encryptedData, String password) {
    // Simple XOR decryption for demonstration
    final List<int> encryptedBytes = base64.decode(encryptedData);
    final List<int> keyBytes = utf8.encode(password);
    final List<int> decrypted = [];
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decrypted);
  }
  
  // Convert public key to Ethereum address
  static String publicKeyToAddress(String publicKey) {
    // Remove '0x' prefix if present
    if (publicKey.startsWith('0x')) {
      publicKey = publicKey.substring(2);
    }
    
    // Convert public key to bytes
    final publicKeyBytes = hexToBytes(publicKey);
    
    // Take the last 20 bytes of the keccak256 hash
    final addressBytes = keccak256(publicKeyBytes).sublist(12);
    
    // Convert to hex and add '0x' prefix
    return '0x${bytesToHex(addressBytes)}';
  }
}
