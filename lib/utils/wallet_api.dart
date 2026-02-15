import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:crypto/crypto.dart';

class WalletApi {
  // Fixed Sepolia testnet RPC URL - direct URL string, not JSON
  static const String _rpcUrl = 'https://sepolia.infura.io/v3/96200534d4d240ad9f0c26bbbb038b64';
  
  // Create a new client for each request to avoid connection issues
  static Web3Client _createClient() {
    return Web3Client(_rpcUrl, http.Client());
  }

  /// Get ETH balance for a wallet address
  static Future<String> getEthBalance(String address) async {
    if (address.isEmpty) {
      print('❌ Empty address provided');
      return '0.0';
    }

    Web3Client? ethClient;
    try {
      print('🔄 Getting ETH balance for address: $address');
      print('  🌐 Using RPC URL: $_rpcUrl');
      
      // Create a fresh client for this request
      ethClient = _createClient();
      
      // Convert address string to EthereumAddress
      final ethAddress = EthereumAddress.fromHex(address);
      
      // Get balance from blockchain
      final balance = await ethClient.getBalance(ethAddress);
      
      // Convert Wei to ETH with 6 decimal places
      final ethBalance = balance.getValueInUnit(EtherUnit.ether);
      final formattedBalance = ethBalance.toStringAsFixed(6);
      
      print('✅ Balance fetched: $formattedBalance ETH');
      return formattedBalance;
      
    } catch (e) {
      print('💥 Error getting ETH balance: $e');
      // Don't return 0.0 on error, rethrow to handle in UI
      throw Exception('Failed to fetch balance: $e');
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }

  /// Create wallet from mnemonic
  static Future<Map<String, String>> createWalletFromMnemonic(String mnemonic) async {
    try {
      print('🔄 Creating wallet from mnemonic...');
      
      // Validate mnemonic
      if (!bip39.validateMnemonic(mnemonic)) {
        throw Exception('Invalid mnemonic phrase');
      }

      // Generate seed from mnemonic
      final seed = bip39.mnemonicToSeed(mnemonic);
      
      // Create credentials from seed
      final credentials = EthPrivateKey.fromHex(
        bytesToHex(seed.sublist(0, 32))
      );
      
      final address = await credentials.extractAddress();
      final privateKey = bytesToHex(credentials.privateKey);
      final publicKey = bytesToHex(credentials.publicKey.getEncoded());
      
      print('✅ Wallet created successfully');
      print('  📍 Address: ${address.hex}');
      print('  🔑 Private Key: ${privateKey.substring(0, 10)}...');
      
      return {
        'address': address.hex,
        'privateKey': privateKey,
        'publicKey': publicKey,
      };
      
    } catch (e) {
      print('💥 Error creating wallet: $e');
      throw Exception('Failed to create wallet: $e');
    }
  }

  /// Send ETH transaction
  static Future<String> sendTransaction(
    String privateKeyHex,
    String toAddress,
    String amountEth,
  ) async {
    Web3Client? ethClient;
    try {
      print('🔄 Sending transaction...');
      print('  📍 To: $toAddress');
      print('  💰 Amount: $amountEth ETH');
      print('  🌐 Using RPC URL: $_rpcUrl');
      
      // Create a fresh client for this request
      ethClient = _createClient();
      
      final credentials = EthPrivateKey.fromHex(privateKeyHex);
      final to = EthereumAddress.fromHex(toAddress);
      
      // Parse amount string to double, then convert to BigInt for Wei
      final double ethAmount = double.parse(amountEth);
      final BigInt weiAmount = BigInt.from(ethAmount * 1e18);
      final amount = EtherAmount.fromBigInt(EtherUnit.wei, weiAmount);
      
      // Get current gas price
      final gasPrice = await ethClient.getGasPrice();
      
      // Send transaction
      final txHash = await ethClient.sendTransaction(
        credentials,
        Transaction(
          to: to,
          gasPrice: gasPrice,
          maxGas: 21000,
          value: amount,
        ),
        chainId: 11155111, // Sepolia chain ID
      );
      
      print('✅ Transaction sent: $txHash');
      return txHash;
      
    } catch (e) {
      print('💥 Error sending transaction: $e');
      throw Exception('Failed to send transaction: $e');
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }

  /// Get transaction details
  static Future<Map<String, dynamic>?> getTransactionDetails(String txHash) async {
    Web3Client? ethClient;
    try {
      // Create a fresh client for this request
      ethClient = _createClient();
      
      final receipt = await ethClient.getTransactionReceipt(txHash);
      if (receipt == null) return null;
      
      return {
        'hash': txHash,
        'status': receipt.status,
        'gasUsed': receipt.gasUsed?.toString(),
        'blockNumber': receipt.blockNumber?.toString(),
      };
      
    } catch (e) {
      print('Error getting transaction details: $e');
      return null;
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }

  /// Get Etherscan URL for transaction
  static String getEtherscanTxUrl(String txHash) {
    return 'https://sepolia.etherscan.io/tx/$txHash';
  }

  /// Get Etherscan URL for address
  static String getEtherscanAddressUrl(String address) {
    return 'https://sepolia.etherscan.io/address/$address';
  }

  /// Request testnet ETH from faucet (mock implementation)
  static Future<bool> requestTestnetEth(String address) async {
    try {
      print('🔄 Requesting testnet ETH for: $address');
      
      // Mock implementation - in real app, this would call a faucet API
      await Future.delayed(const Duration(seconds: 2));
      
      print('✅ Testnet ETH request completed (mock)');
      return true;
      
    } catch (e) {
      print('💥 Error requesting testnet ETH: $e');
      return false;
    }
  }

  /// Convert bytes to hex string
  static String bytesToHex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generate random mnemonic
  static String generateMnemonic({int strength = 256}) {
    return bip39.generateMnemonic(strength: strength);
  }

  /// Validate mnemonic phrase
  static bool validateMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  /// Get current gas price
  static Future<String> getCurrentGasPrice() async {
    Web3Client? ethClient;
    try {
      // Create a fresh client for this request
      ethClient = _createClient();
      final gasPrice = await ethClient.getGasPrice();
      return gasPrice.getValueInUnit(EtherUnit.gwei).toStringAsFixed(2);
    } catch (e) {
      print('Error getting gas price: $e');
      return '0.0';
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }

  /// Get network info
  static Future<Map<String, dynamic>> getNetworkInfo() async {
    Web3Client? ethClient;
    try {
      // Create a fresh client for this request
      ethClient = _createClient();
      final networkId = await ethClient.getNetworkId();
      final blockNumber = await ethClient.getBlockNumber();
      
      return {
        'networkId': networkId.toString(),
        'blockNumber': blockNumber.toString(),
        'rpcUrl': _rpcUrl,
      };
    } catch (e) {
      print('Error getting network info: $e');
      return {
        'networkId': 'unknown',
        'blockNumber': 'unknown',
        'rpcUrl': _rpcUrl,
      };
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }
  
  /// Test RPC connection
  static Future<bool> testRpcConnection() async {
    Web3Client? ethClient;
    try {
      print('🔄 Testing RPC connection to: $_rpcUrl');
      
      // Create a fresh client for this request
      ethClient = _createClient();
      
      // Try to get the latest block number as a simple test
      final blockNumber = await ethClient.getBlockNumber();
      
      print('✅ RPC connection successful! Latest block: $blockNumber');
      return true;
    } catch (e) {
      print('❌ RPC connection failed: $e');
      return false;
    } finally {
      // Always close the client to prevent resource leaks
      ethClient?.dispose();
    }
  }
}
