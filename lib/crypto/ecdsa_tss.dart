import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:web3dart/crypto.dart';
import 'package:crypto/crypto.dart';

/// Implementation of ECDSA Threshold Signature Scheme (TSS)
/// This is a simplified version for educational purposes
class EcdsaTss {
  // Elliptic curve parameters (secp256k1)
  static final ECDomainParameters _params = ECCurve_secp256k1();
  static final BigInt _n = _params.n;
  static final ECPoint _G = _params.G;

  // Helper method to convert hex string to BigInt
  static BigInt hexToBigInt(String hex) {
    // Remove '0x' prefix if present
    if (hex.startsWith('0x')) {
      hex = hex.substring(2);
    }
    return BigInt.parse(hex, radix: 16);
  }

  // Generate a key pair
  static Map<String, dynamic> generateKeyPair() {
    final secureRandom = FortunaRandom();
    secureRandom.seed(KeyParameter(Uint8List.fromList(
        List.generate(32, (_) => Random.secure().nextInt(256)))));

    // Generate private key
    BigInt privateKey;
    do {
      // Fixed: Using a different approach to generate BigInt
      final randomBytes = secureRandom.nextBytes(32);
      privateKey = BigInt.parse(
          bytesToHex(randomBytes, include0x: false),
          radix: 16);
    } while (privateKey >= _n || privateKey <= BigInt.zero);

    // Calculate public key
    final publicKey = _params.G * privateKey;

    return {
      'privateKey': privateKey,
      'publicKey': publicKey,
    };
  }

  // Split a private key into two shares (2-of-2 threshold scheme)
  static Map<String, BigInt> splitPrivateKey(BigInt privateKey) {
    try {
      // Generate a random share for device 1
      final random = Random.secure();
      final share1 = BigInt.from(random.nextInt(1 << 30)) + BigInt.from(random.nextInt(1 << 30)) * BigInt.from(1 << 30);
      
      // Calculate share2 such that share1 + share2 = privateKey (mod n)
      final n = BigInt.parse('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141', radix: 16);
      var share2 = (privateKey - share1) % n;
      
      // Ensure share2 is positive
      if (share2 < BigInt.zero) {
        share2 = share2 + n;
      }
      
      return {
        'share1': share1,
        'share2': share2,
      };
    } catch (e) {
      print('Error splitting private key: $e');
      throw Exception('Failed to split private key: $e');
    }
  }

  // Combine shares to reconstruct the private key
  static BigInt combineShares(BigInt share1, BigInt share2) {
    // In a real TSS implementation, this would be a secure protocol
    // For this demo, we'll use a simple addition modulo the curve order
    // This is NOT secure and is only for demonstration purposes
    
    // Ethereum's secp256k1 curve order
    final curveOrder = BigInt.parse('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141', radix: 16);
    
    // Combine shares (simple addition modulo curve order)
    return (share1 + share2) % curveOrder;
  }

  // Generate a signature share (partial signature)
  static Map<String, BigInt> generateSignatureShare(BigInt keyShare, Uint8List messageHash) {
    try {
      // ECDSA parameters
      final n = BigInt.parse('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141', radix: 16);
      
      // Generate a random k value (this should be deterministic in production)
      final random = Random.secure();
      final k = BigInt.from(random.nextInt(1 << 30)) + BigInt.from(random.nextInt(1 << 30)) * BigInt.from(1 << 30);
      
      // Calculate r = (g^k mod p) mod n
      // In a real implementation, this would involve elliptic curve point multiplication
      // For simplicity, we'll just use a hash of k as r
      final kBytes = _bigIntToBytes(k);
      final rBytes = sha256.convert(kBytes).bytes;
      final r = _bytesToBigInt(Uint8List.fromList(rBytes)) % n;
      
      // Calculate s share: s_i = k_i^(-1) * (z + r*d_i) mod n
      // where z is the message hash, d_i is the key share, and k_i is our k value
      
      // Convert message hash to BigInt
      final z = _bytesToBigInt(messageHash) % n;
      
      // Calculate k^(-1) mod n
      final kInv = _modInverse(k, n);
      
      // Calculate s share
      final sShare = (kInv * (z + (r * keyShare) % n)) % n;
      
      return {
        'r': r,
        'sShare': sShare,
      };
    } catch (e) {
      print('Error generating signature share: $e');
      throw Exception('Failed to generate signature share: $e');
    }
  }

  // Combine signature shares to create a complete signature
  static BigInt combineSignatureShares(BigInt r, BigInt s1, BigInt s2) {
    try {
      // ECDSA parameters
      final n = BigInt.parse('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141', radix: 16);
      
      // Combine signature shares: s = (s1 + s2) mod n
      final s = (s1 + s2) % n;
      
      // In a real implementation, we would return the full signature (r, s)
      // For simplicity, we'll just return s
      return s;
    } catch (e) {
      print('Error combining signature shares: $e');
      throw Exception('Failed to combine signature shares: $e');
    }
  }

  // Verify a signature against a public key
  static bool verifySignature(
      ECPoint publicKey, Uint8List messageHash, BigInt r, BigInt s) {
    if (r <= BigInt.zero || r >= _n || s <= BigInt.zero || s >= _n) {
      return false;
    }

    // Convert messageHash to BigInt
    BigInt e = BigInt.parse(bytesToHex(messageHash, include0x: false), radix: 16);

    // Calculate u1 and u2
    final sInv = s.modInverse(_n);
    final u1 = (e * sInv) % _n;
    final u2 = (r * sInv) % _n;

    // Calculate R' = u1*G + u2*publicKey
    final ECPoint? point1 = _G * u1;
    final ECPoint? point2 = publicKey * u2;
    
    if (point1 == null || point2 == null) {
      return false;
    }
    
    final ECPoint? R = point1 + point2;
    if (R == null) {
      return false;
    }

    // Verify that R'.x mod n equals r
    final BigInt? rX = R.x?.toBigInteger();
    if (rX == null) {
      return false;
    }
    
    return (rX % _n) == r;
  }

  static Uint8List _bigIntToBytes(BigInt bigInt) {
    String hex = bigInt.toRadixString(16);
    if (hex.length % 2 != 0) {
      hex = '0' + hex;
    }
    return Uint8List.fromList(hex.replaceAll(' ', '').split('').map((hexChar) => int.parse(hexChar, radix: 16)).toList());
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }

  static BigInt _modInverse(BigInt a, BigInt n) {
    BigInt m0 = n;
    BigInt y = BigInt.zero, x = BigInt.one;

    if (n == BigInt.one) {
      return BigInt.zero;
    }

    while (a > BigInt.one) {
      // q is quotient
      BigInt q = a ~/ n;

      BigInt t = n;

      // m is remainder now, process same as
      // Euclid's algo
      n = a % n;
      a = t;
      t = y;

      // Update y and x
      y = x - q * y;
      x = t;
    }

    // Make x positive
    if (x < BigInt.zero) {
      x = x + m0;
    }

    return x;
  }
}
