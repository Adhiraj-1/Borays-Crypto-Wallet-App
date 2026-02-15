import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3_wallet/providers/wallet_provider.dart';
import 'package:web3_wallet/pages/device_selection_page.dart'; // Changed import
import 'package:web3dart/web3dart.dart';
import 'package:web3_wallet/utils/get_balances.dart';
import 'dart:convert';

// Create the NFTListPage widget
class NFTListPage extends StatefulWidget {
 final String address;
 final String chain;
 
 const NFTListPage({Key? key, required this.address, required this.chain}) : super(key: key);
 
 @override
 _NFTListPageState createState() => _NFTListPageState();
}

class _NFTListPageState extends State<NFTListPage> {
 bool _isLoading = true;
 List<Map<String, dynamic>> _nfts = [];
 
 @override
 void initState() {
   super.initState();
   _loadNFTs();
 }
 
 Future<void> _loadNFTs() async {
   // In a real app, you would fetch NFTs from an API
   await Future.delayed(const Duration(seconds: 1));
   setState(() {
     _isLoading = false;
     // Empty list for now
   });
 }
 
 @override
 Widget build(BuildContext context) {
   if (_isLoading) {
     return const Center(child: CircularProgressIndicator());
   }
   
   if (_nfts.isEmpty) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(
             Icons.image_not_supported,
             size: 64,
             color: Colors.grey.withAlpha(150),
           ),
           const SizedBox(height: 16),
           const Text(
             'No NFTs found',
             style: TextStyle(
               fontSize: 18,
               fontWeight: FontWeight.bold,
               color: Colors.grey,
             ),
           ),
           const SizedBox(height: 8),
           const Text(
             'Your NFT collection will appear here',
             style: TextStyle(
               color: Colors.grey,
             ),
           ),
         ],
       ),
     );
   }
   
   return GridView.builder(
     padding: const EdgeInsets.all(16),
     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
       crossAxisCount: 2,
       childAspectRatio: 0.75,
       crossAxisSpacing: 16,
       mainAxisSpacing: 16,
     ),
     itemCount: _nfts.length,
     itemBuilder: (context, index) {
       final nft = _nfts[index];
       return Card(
         clipBehavior: Clip.antiAlias,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Expanded(
               child: Container(
                 width: double.infinity,
                 color: Colors.grey.shade200,
                 child: Image.network(
                   nft['image'] as String,
                   fit: BoxFit.cover,
                 ),
               ),
             ),
             Padding(
               padding: const EdgeInsets.all(12),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     nft['name'] as String,
                     style: const TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                   const SizedBox(height: 4),
                   Text(
                     nft['collection'] as String,
                     style: TextStyle(
                       color: Colors.grey.shade600,
                       fontSize: 12,
                     ),
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                   ),
                 ],
               ),
             ),
           ],
         ),
       );
     },
   );
 }
}

// Create the SendTokensPage widget
class SendTokensPage extends StatefulWidget {
 final String privateKey;
 
 const SendTokensPage({Key? key, required this.privateKey}) : super(key: key);
 
 @override
 _SendTokensPageState createState() => _SendTokensPageState();
}

class _SendTokensPageState extends State<SendTokensPage> {
 final _formKey = GlobalKey<FormState>();
 final _addressController = TextEditingController();
 final _amountController = TextEditingController();
 bool _isLoading = false;
 String? _errorMessage;
 
 @override
 void dispose() {
   _addressController.dispose();
   _amountController.dispose();
   super.dispose();
 }
 
 Future<void> _sendTransaction() async {
   if (!_formKey.currentState!.validate()) {
     return;
   }
   
   setState(() {
     _isLoading = true;
     _errorMessage = null;
   });
   
   try {
     // In a real app, you would send the transaction here
     await Future.delayed(const Duration(seconds: 2));
     
     if (!mounted) return;
     Navigator.pop(context);
     ScaffoldMessenger.of(context).showSnackBar(
       const SnackBar(content: Text('Transaction sent successfully')),
     );
   } catch (e) {
     setState(() {
       _errorMessage = 'Error: ${e.toString()}';
     });
   } finally {
     if (mounted) {
       setState(() {
         _isLoading = false;
       });
     }
   }
 }
 
 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Send Tokens'),
     ),
     body: _isLoading
         ? const Center(child: CircularProgressIndicator())
         : SingleChildScrollView(
             padding: const EdgeInsets.all(16),
             child: Form(
               key: _formKey,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Text(
                     'Recipient Address',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 8),
                   TextFormField(
                     controller: _addressController,
                     decoration: InputDecoration(
                       hintText: '0x...',
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                       prefixIcon: const Icon(Icons.account_balance_wallet),
                     ),
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please enter a recipient address';
                       }
                       if (!value.startsWith('0x') || value.length != 42) {
                         return 'Please enter a valid Ethereum address';
                       }
                       return null;
                     },
                   ),
                   
                   const SizedBox(height: 16),
                   
                   const Text(
                     'Amount (ETH)',
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 8),
                   TextFormField(
                     controller: _amountController,
                     keyboardType: const TextInputType.numberWithOptions(decimal: true),
                     decoration: InputDecoration(
                       hintText: '0.0',
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                       prefixIcon: const Icon(Icons.attach_money),
                       suffixText: 'ETH',
                     ),
                     validator: (value) {
                       if (value == null || value.isEmpty) {
                         return 'Please enter an amount';
                       }
                       try {
                         final amount = double.parse(value);
                         if (amount <= 0) {
                           return 'Amount must be greater than 0';
                         }
                         return null;
                       } catch (e) {
                         return 'Please enter a valid number';
                       }
                     },
                   ),
                   
                   if (_errorMessage != null) ...[
                     const SizedBox(height: 16),
                     Container(
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Colors.red.withAlpha(30),
                         borderRadius: BorderRadius.circular(8),
                         border: Border.all(color: Colors.red),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.error, color: Colors.red),
                           const SizedBox(width: 8),
                           Expanded(
                             child: Text(
                               _errorMessage!,
                               style: const TextStyle(color: Colors.red),
                             ),
                           ),
                         ],
                       ),
                     ),
                   ],
                   
                   const SizedBox(height: 24),
                   
                   SizedBox(
                     width: double.infinity,
                     child: ElevatedButton(
                       onPressed: _sendTransaction,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blue,
                         foregroundColor: Colors.white,
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8),
                         ),
                       ),
                       child: const Text('Send Transaction'),
                     ),
                   ),
                 ],
               ),
             ),
           ),
   );
 }
}

class WalletPage extends StatefulWidget {
 final bool isDevice1;
 
 const WalletPage({Key? key, required this.isDevice1}) : super(key: key);

 @override
 _WalletPageState createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
 String walletAddress = '';
 String balance = '';
 String pvKey = '';

 @override
 void initState() {
   super.initState();
   loadWalletData();
 }

 Future<void> loadWalletData() async {
   SharedPreferences prefs = await SharedPreferences.getInstance();
   String? privateKey = prefs.getString('privateKey');
   if (privateKey != null) {
     final walletProvider = WalletProvider();
     // Initialize wallet provider
     await walletProvider.initialize();
     
     // Get wallet address
     EthereumAddress address = EthPrivateKey.fromHex(privateKey).address;
     setState(() {
       walletAddress = address.hex;
       pvKey = privateKey;
     });
     
     // Get balance
     try {
       String response = await getBalances(address.hex, 'sepolia');
       dynamic data = json.decode(response);
       String newBalance = data['balance'] ?? '0';

       // Transform balance from wei to ether
       EtherAmount latestBalance =
           EtherAmount.fromBigInt(EtherUnit.wei, BigInt.parse(newBalance));
       String latestBalanceInEther =
           latestBalance.getValueInUnit(EtherUnit.ether).toString();

       setState(() {
         balance = latestBalanceInEther;
       });
     } catch (e) {
       print('Error getting balance: $e');
       setState(() {
         balance = '0';
       });
     }
   }
 }

 @override
 Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Wallet'),
     ),
     body: Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         Container(
           height: MediaQuery.of(context).size.height * 0.4,
           padding: const EdgeInsets.all(16.0),
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               const Text(
                 'Wallet Address',
                 style: TextStyle(
                   fontSize: 24.0,
                   fontWeight: FontWeight.bold,
                 ),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 16.0),
               Text(
                 walletAddress,
                 style: const TextStyle(
                   fontSize: 20.0,
                 ),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 32.0),
               const Text(
                 'Balance',
                 style: TextStyle(
                   fontSize: 24.0,
                   fontWeight: FontWeight.bold,
                 ),
                 textAlign: TextAlign.center,
               ),
               const SizedBox(height: 16.0),
               Text(
                 balance,
                 style: const TextStyle(
                   fontSize: 20.0,
                 ),
                 textAlign: TextAlign.center,
               ),
             ],
           ),
         ),
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
             Column(
               children: [
                 FloatingActionButton(
                   heroTag: 'sendButton', // Unique tag for send button
                   onPressed: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(
                           builder: (context) =>
                               SendTokensPage(privateKey: pvKey)),
                     );
                   },
                   child: const Icon(Icons.send),
                 ),
                 const SizedBox(height: 8.0),
                 const Text('Send'),
               ],
             ),
             Column(
               children: [
                 FloatingActionButton(
                   heroTag: 'refreshButton', // Unique tag for refresh button
                   onPressed: () {
                     loadWalletData();
                   },
                   child: const Icon(Icons.replay_outlined),
                 ),
                 const SizedBox(height: 8.0),
                 const Text('Refresh'),
               ],
             ),
           ],
         ),
         const SizedBox(height: 30.0),
         Expanded(
           child: DefaultTabController(
             length: 3,
             child: Column(
               children: [
                 const TabBar(
                   labelColor: Colors.blue,
                   tabs: [
                     Tab(text: 'Assets'),
                     Tab(text: 'NFTs'),
                     Tab(text: 'Options'),
                   ],
                 ),
                 Expanded(
                   child: TabBarView(
                     children: [
                       // Assets Tab
                       Column(
                         children: [
                           Card(
                             margin: const EdgeInsets.all(16.0),
                             child: Padding(
                               padding: const EdgeInsets.all(16.0),
                               child: Row(
                                 mainAxisAlignment:
                                     MainAxisAlignment.spaceBetween,
                                 children: [
                                   const Text(
                                     'Sepolia ETH',
                                     style: TextStyle(
                                       fontSize: 24.0,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                   Text(
                                     balance,
                                     style: const TextStyle(
                                       fontSize: 24.0,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   )
                                 ],
                               ),
                             ),
                           )
                         ],
                       ),
                       // NFTs Tab
                       NFTListPage(address: walletAddress, chain: 'sepolia'),
                       // Activities Tab
                       Center(
                         child: ListTile(
                           leading: const Icon(Icons.logout),
                           title: const Text('Logout'),
                           onTap: () async {
                             SharedPreferences prefs =
                                 await SharedPreferences.getInstance();
                             await prefs.remove('privateKey');
                             // ignore: use_build_context_synchronously
                             Navigator.pushAndRemoveUntil(
                               context,
                               MaterialPageRoute(
                                 builder: (context) =>
                                     const DeviceSelectionPage(isImporting: false),
                               ),
                               (route) => false,
                             );
                           },
                         ),
                       ),
                     ],
                   ),
                 ),
               ],
             ),
           ),
         ),
       ],
     ),
   );
 }
}
