import 'package:http/http.dart' as http;

Future<String> getBalances(String address, String chain) async {
  final url = Uri.parse('https://sepolia.infura.io/v3/96200534d4d240ad9f0c26bbbb038b64');
  
  final body = '''
  {
    "jsonrpc": "2.0",
    "method": "eth_getBalance",
    "params": ["$address", "latest"],
    "id": 1
  }
  ''';

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    return '''
    {
      "balance": "${_parseBalanceResponse(response.body)}"
    }
    ''';
  } else {
    throw Exception('Failed to get balance: ${response.statusCode}');
  }
}

String _parseBalanceResponse(String responseBody) {
  // Extract the hex balance from the JSON response
  final hexBalance = RegExp(r'"result":"(0x[a-fA-F0-9]+)"').firstMatch(responseBody)?.group(1);
  
  if (hexBalance == null) {
    return "0";
  }
  
  // Convert hex to decimal
  return BigInt.parse(hexBalance).toString();
}
