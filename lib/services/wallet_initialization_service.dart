import '../providers/wallet_provider.dart';
import 'cloud_wallet_service.dart';

class WalletInitializationService {
  /// Initialize wallet provider with proper cloud sync
  static Future<bool> initializeWallet(WalletProvider provider) async {
    try {
      print('Starting wallet initialization...');
      
      // Check if Firestore is available
      final isCloudAvailable = await CloudWalletService.isFirestoreAvailable();
      if (!isCloudAvailable) {
        print('Warning: Cloud services not available, running in offline mode');
      }
      
      // Initialize the provider (loads local data)
      await provider.initialize();
      
      // If cloud is available and wallet exists, sync with cloud
      if (isCloudAvailable && provider.isInitialized) {
        print('Syncing with cloud...');
        await provider.forceCloudSync();
      }
      
      print('Wallet initialization completed successfully');
      return true;
    } catch (e) {
      print('Error during wallet initialization: $e');
      return false;
    }
  }
  
  /// Test all cloud services
  static Future<Map<String, bool>> testAllServices() async {
    final results = <String, bool>{};
    
    try {
      // Test Firestore connection
      results['firestore'] = await CloudWalletService.testConnection();
      
      // Test cloud wallet service
      results['cloudWallet'] = await CloudWalletService.isFirestoreAvailable();
      
      print('Service test results: $results');
      return results;
    } catch (e) {
      print('Error testing services: $e');
      return {'error': false};
    }
  }
}
