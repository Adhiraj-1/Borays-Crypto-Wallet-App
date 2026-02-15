import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/services/firestore_service.dart';

class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({Key? key}) : super(key: key);

  @override
  State<FirestoreTestPage> createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  String _testResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Firestore Connection',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading 
                  ? const CircularProgressIndicator()
                  : const Text('Test Firestore Connection'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testWalletData,
              child: const Text('Test Save Wallet Data'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testTransactionData,
              child: const Text('Test Save Transaction'),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearTestData,
              child: const Text('Clear Test Data'),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.isEmpty ? 'Test results will appear here...' : _testResult,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testing Firestore connection...\n';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final success = await walletProvider.testFirestoreConnection();
      
      setState(() {
        _testResult += success 
            ? '✅ Firestore connection successful!\n'
            : '❌ Firestore connection failed!\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Error testing connection: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testWalletData() async {
    setState(() {
      _isLoading = true;
      _testResult += '\nTesting wallet data save...\n';
    });

    try {
      final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      final testWalletAddress = '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6';
      
      final success = await FirestoreService.saveWalletData(
        userId: testUserId,
        walletAddress: testWalletAddress,
        walletData: {
          'test': true,
          'created_at': DateTime.now().toIso8601String(),
          'device_type': 1,
        },
      );
      
      setState(() {
        _testResult += success 
            ? '✅ Wallet data saved successfully!\n'
            : '❌ Failed to save wallet data!\n';
        _testResult += 'User ID: $testUserId\n';
        _testResult += 'Wallet Address: $testWalletAddress\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Error saving wallet data: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testTransactionData() async {
    setState(() {
      _isLoading = true;
      _testResult += '\nTesting transaction save...\n';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      
      // Create a test transaction
      final success = await walletProvider.createTransaction(
        '0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6', // to address
        '0.001', // amount
        'test_password', // This will fail password check, but that's ok for testing
      );
      
      setState(() {
        _testResult += success 
            ? '✅ Transaction created successfully!\n'
            : '❌ Transaction creation failed (expected if password is wrong)\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Error creating transaction: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _testResult += '\nClearing test data...\n';
    });

    try {
      final walletProvider = Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.clearFirestoreTestData();
      
      setState(() {
        _testResult += '✅ Test data cleared!\n';
      });
    } catch (e) {
      setState(() {
        _testResult += '❌ Error clearing test data: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
