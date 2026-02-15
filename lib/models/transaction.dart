import 'dart:convert';
import 'package:uuid/uuid.dart';

enum TransactionStatus {
  pending,
  approvedByDevice1,
  approvedByDevice2,
  completed,
  rejected,
  failed
}

class WalletTransaction {
  final String id;
  final String from;
  final String to;
  final String amount;
  String? txHash;
  final DateTime timestamp;
  TransactionStatus status;
  bool approvedByDevice1;
  bool approvedByDevice2;
  String? device1SignatureShare;
  String? device2SignatureShare;
  String? error;
  
  WalletTransaction({
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    this.txHash,
    required this.timestamp,
    required this.status,
    required this.approvedByDevice1,
    required this.approvedByDevice2,
    this.device1SignatureShare,
    this.device2SignatureShare,
    this.error,
  });
  
  // Factory method to create a new transaction
  factory WalletTransaction.create({
    required String from,
    required String to,
    required String amount,
  }) {
    return WalletTransaction(
      id: const Uuid().v4(),
      from: from,
      to: to,
      amount: amount,
      timestamp: DateTime.now(),
      status: TransactionStatus.pending,
      approvedByDevice1: false,
      approvedByDevice2: false,
    );
  }
  
  // Create a copy with updated fields
  WalletTransaction copyWith({
    String? id,
    String? from,
    String? to,
    String? amount,
    String? txHash,
    DateTime? timestamp,
    TransactionStatus? status,
    bool? approvedByDevice1,
    bool? approvedByDevice2,
    String? device1SignatureShare,
    String? device2SignatureShare,
    String? error,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      amount: amount ?? this.amount,
      txHash: txHash ?? this.txHash,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      approvedByDevice1: approvedByDevice1 ?? this.approvedByDevice1,
      approvedByDevice2: approvedByDevice2 ?? this.approvedByDevice2,
      device1SignatureShare: device1SignatureShare ?? this.device1SignatureShare,
      device2SignatureShare: device2SignatureShare ?? this.device2SignatureShare,
      error: error ?? this.error,
    );
  }
  
  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': from,
      'to': to,
      'amount': amount,
      'txHash': txHash,
      'timestamp': timestamp.toIso8601String(),
      'status': status.index,
      'approvedByDevice1': approvedByDevice1,
      'approvedByDevice2': approvedByDevice2,
      'device1SignatureShare': device1SignatureShare,
      'device2SignatureShare': device2SignatureShare,
      'error': error,
    };
  }
  
  // Create from JSON
  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'],
      from: json['from'],
      to: json['to'],
      amount: json['amount'],
      txHash: json['txHash'],
      timestamp: DateTime.parse(json['timestamp']),
      status: TransactionStatus.values[json['status']],
      approvedByDevice1: json['approvedByDevice1'],
      approvedByDevice2: json['approvedByDevice2'],
      device1SignatureShare: json['device1SignatureShare'],
      device2SignatureShare: json['device2SignatureShare'],
      error: json['error'],
    );
  }
  
  // Encode a list of transactions to JSON string
  static String encodeList(List<WalletTransaction> transactions) {
    final jsonList = transactions.map((tx) => tx.toJson()).toList();
    return jsonEncode(jsonList);
  }
  
  // Decode a JSON string to a list of transactions
  static List<WalletTransaction> decodeList(String encodedList) {
    final jsonList = jsonDecode(encodedList) as List;
    return jsonList.map((json) => WalletTransaction.fromJson(json)).toList();
  }
}
