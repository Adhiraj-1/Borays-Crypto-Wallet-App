import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Utility class for secure communication between devices
class DeviceCommunication {
  // For demo purposes, we'll use a simple in-memory storage
  // In a real app, this would be a secure server or direct device-to-device communication
  static final Map<String, Map<String, dynamic>> _pendingTransactions = {};
  static final Uuid _uuid = Uuid();
  
  // Generate a QR code payload for device communication
  static String generateQRPayload(Map<String, dynamic> data) {
    // Add a timestamp to prevent replay attacks
    data['timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Convert the data to JSON
    final jsonData = json.encode(data);
    
    // Add a checksum for data integrity
    final checksum = _generateChecksum(jsonData);
    
    // Create the final payload with the checksum
    final payload = {
      'data': jsonData,
      'checksum': checksum,
    };
    
    // Return the encoded payload
    return json.encode(payload);
  }
  
  // Parse a QR code payload
  static Map<String, dynamic>? parseQRPayload(String payload) {
    try {
      // Decode the payload
      final Map<String, dynamic> decodedPayload = json.decode(payload);
      
      // Extract the data and checksum
      final String jsonData = decodedPayload['data'];
      final String checksum = decodedPayload['checksum'];
      
      // Verify the checksum
      if (_generateChecksum(jsonData) != checksum) {
        return null; // Invalid checksum
      }
      
      // Decode the data
      final Map<String, dynamic> data = json.decode(jsonData);
      
      // Check for timestamp expiration (optional)
      final timestamp = int.parse(data['timestamp']);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > 5 * 60 * 1000) { // 5 minutes
        return null; // Expired payload
      }
      
      return data;
    } catch (e) {
      return null; // Invalid payload
    }
  }
  
  // Generate a checksum for data integrity
  static String _generateChecksum(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Store transaction data for the other device to retrieve
  static Future<String> storeTransactionData(Map<String, dynamic> data) async {
    final transactionId = _uuid.v4();
    _pendingTransactions[transactionId] = {
      'id': transactionId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'data': data,
    };
    return transactionId;
  }
  
  // Retrieve transaction data by ID
  static Map<String, dynamic>? getTransactionData(String transactionId) {
    return _pendingTransactions[transactionId];
  }
  
  // Remove transaction data after it's been processed
  static void removeTransactionData(String transactionId) {
    _pendingTransactions.remove(transactionId);
  }
  
  // In a real app, these would be API calls to a secure server
  
  // Send transaction data to server
  static Future<bool> sendToServer(String deviceId, Map<String, dynamic> data) async {
    try {
      // This is a placeholder - in a real app, this would be an API call
      debugPrint('Sending data to server for device $deviceId: $data');
      return true;
    } catch (e) {
      debugPrint('Error sending data to server: $e');
      return false;
    }
  }
  
  // Retrieve transaction data from server
  static Future<Map<String, dynamic>?> retrieveFromServer(String deviceId) async {
    try {
      // This is a placeholder - in a real app, this would be an API call
      debugPrint('Retrieving data from server for device $deviceId');
      
      // For demo purposes, return the first pending transaction
      if (_pendingTransactions.isNotEmpty) {
        return _pendingTransactions.values.first;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error retrieving data from server: $e');
      return null;
    }
  }
}
