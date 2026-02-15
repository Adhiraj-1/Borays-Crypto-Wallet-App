class WalletData {
  final String address;
  final String mnemonic;
  final String device1KeyShare;
  final String device2KeyShare;
  final String device1MnemonicPart;
  final String device2MnemonicPart;
  final String publicKey;

  WalletData({
    required this.address,
    required this.mnemonic,
    required this.device1KeyShare,
    required this.device2KeyShare,
    required this.publicKey,
    this.device1MnemonicPart = '',
    this.device2MnemonicPart = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'mnemonic': mnemonic,
      'device1KeyShare': device1KeyShare,
      'device2KeyShare': device2KeyShare,
      'device1MnemonicPart': device1MnemonicPart,
      'device2MnemonicPart': device2MnemonicPart,
      'publicKey': publicKey,
    };
  }

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      address: json['address'] ?? '',
      mnemonic: json['mnemonic'] ?? '',
      device1KeyShare: json['device1KeyShare'] ?? '',
      device2KeyShare: json['device2KeyShare'] ?? '',
      device1MnemonicPart: json['device1MnemonicPart'] ?? '',
      device2MnemonicPart: json['device2MnemonicPart'] ?? '',
      publicKey: json['publicKey'] ?? '',
    );
  }
}
