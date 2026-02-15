import 'dart:convert';
import 'package:crypto/crypto.dart';

class Paillier {
  // A simplified implementation of Paillier cryptosystem for demonstration
  // In a real app, you would use a proper cryptographic library
  
  // Encrypt data with password
  String encrypt(String data, String password) {
    // Generate a key from the password
    final key = _generateKeyFromPassword(password);
    
    // Simple XOR encryption (for demonstration only)
    final encrypted = _xorEncrypt(data, key);
    
    // Return base64 encoded result
    return base64Encode(utf8.encode(encrypted));
  }
  
  // Decrypt data with password
  String decrypt(String encryptedData, String password) {
    // Generate a key from the password
    final key = _generateKeyFromPassword(password);
    
    // Decode from base64
    final decodedData = utf8.decode(base64Decode(encryptedData));
    
    // Simple XOR decryption (for demonstration only)
    return _xorEncrypt(decodedData, key);
  }
  
  // Generate a key from password
  String _generateKeyFromPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Simple XOR encryption/decryption
  String _xorEncrypt(String input, String key) {
    final result = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final inputChar = input.codeUnitAt(i);
      final keyChar = key.codeUnitAt(i % key.length);
      result.writeCharCode(inputChar ^ keyChar);
    }
    return result.toString();
  }
}
