import 'dart:math';
import 'dart:convert';

/// Implementation of Paillier cryptosystem for homomorphic encryption
class PaillierCrypto {
  // Key parameters
  BigInt? _n;      // n = p * q
  BigInt? _g;      // g = n + 1
  BigInt? _lambda; // lambda = lcm(p-1, q-1)
  BigInt? _mu;     // mu = (L(g^lambda mod n^2))^(-1) mod n
  BigInt? _nSquared; // n^2
  
  // Random number generator
  final Random _random = Random.secure();
  
  // Constructor
  PaillierCrypto();
  
  /// Initialize the cryptosystem with generated keys
  Future<void> initialize({int keySize = 1024}) async {
    if (_n != null) return; // Already initialized
    
    // Generate p and q
    final p = await _generatePrime(keySize ~/ 2);
    final q = await _generatePrime(keySize ~/ 2);
    
    // Calculate n = p * q
    _n = p * q;
    
    // Calculate lambda = lcm(p-1, q-1)
    final pMinus1 = p - BigInt.one;
    final qMinus1 = q - BigInt.one;
    _lambda = _lcm(pMinus1, qMinus1);
    
    // Set g = n + 1
    _g = _n! + BigInt.one;
    
    // Calculate n^2
    _nSquared = _n! * _n!;
    
    // Calculate mu = (L(g^lambda mod n^2))^(-1) mod n
    final gLambdaModNSquared = _modPow(_g!, _lambda!, _nSquared!);
    final lOfGLambda = _L(gLambdaModNSquared);
    _mu = _modInverse(lOfGLambda, _n!);
  }
  
  /// Check if the cryptosystem is initialized
  bool isInitialized() {
    return _n != null && _g != null && _lambda != null && _mu != null && _nSquared != null;
  }
  
  /// Encrypt a message
  Future<String> encrypt(String message) async {
    if (!isInitialized()) {
      throw Exception("Paillier cryptosystem not initialized");
    }
    
    // Convert message to BigInt
    final m = BigInt.parse(message);
    
    // Check that m is in the range [0, n-1]
    if (m < BigInt.zero || m >= _n!) {
      throw Exception("Message out of range");
    }
    
    // Generate random r in the range [1, n-1]
    final r = _generateRandomInRange(BigInt.one, _n! - BigInt.one);
    
    // Calculate c = g^m * r^n mod n^2
    final gm = _modPow(_g!, m, _nSquared!);
    final rn = _modPow(r, _n!, _nSquared!);
    final c = (gm * rn) % _nSquared!;
    
    // Return encrypted message as base64 string
    return base64.encode(utf8.encode(c.toString()));
  }
  
  /// Decrypt a message
  Future<String> decrypt(String encryptedMessage) async {
    if (!isInitialized()) {
      throw Exception("Paillier cryptosystem not initialized");
    }
    
    // Convert base64 string to BigInt
    final cStr = utf8.decode(base64.decode(encryptedMessage));
    final c = BigInt.parse(cStr);
    
    // Calculate m = L(c^lambda mod n^2) * mu mod n
    final cLambdaModNSquared = _modPow(c, _lambda!, _nSquared!);
    final lOfCLambda = _L(cLambdaModNSquared);
    final m = (lOfCLambda * _mu!) % _n!;
    
    return m.toString();
  }
  
  /// Homomorphic addition: E(m1) * E(m2) = E(m1 + m2 mod n)
  Future<String> homomorphicAdd(String encryptedMessage1, String encryptedMessage2) async {
    if (!isInitialized()) {
      throw Exception("Paillier cryptosystem not initialized");
    }
    
    // Convert base64 strings to BigInt
    final c1Str = utf8.decode(base64.decode(encryptedMessage1));
    final c2Str = utf8.decode(base64.decode(encryptedMessage2));
    final c1 = BigInt.parse(c1Str);
    final c2 = BigInt.parse(c2Str);
    
    // Calculate c = c1 * c2 mod n^2
    final c = (c1 * c2) % _nSquared!;
    
    // Return encrypted result as base64 string
    return base64.encode(utf8.encode(c.toString()));
  }
  
  /// Homomorphic multiplication: E(m1)^k = E(m1 * k mod n)
  Future<String> homomorphicMultiply(String encryptedMessage, String k) async {
    if (!isInitialized()) {
      throw Exception("Paillier cryptosystem not initialized");
    }
    
    // Convert base64 string to BigInt
    final cStr = utf8.decode(base64.decode(encryptedMessage));
    final c = BigInt.parse(cStr);
    final kBigInt = BigInt.parse(k);
    
    // Calculate c' = c^k mod n^2
    final cPrime = _modPow(c, kBigInt, _nSquared!);
    
    // Return encrypted result as base64 string
    return base64.encode(utf8.encode(cPrime.toString()));
  }
  
  /// Generate a probable prime number of the specified bit length
  Future<BigInt> _generatePrime(int bitLength) async {
    while (true) {
      final candidate = _generateRandomBits(bitLength);
      if (await _isProbablePrime(candidate, 10)) {
        return candidate;
      }
    }
  }
  
  /// Generate a random BigInt with the specified number of bits
  BigInt _generateRandomBits(int bitLength) {
    final bytes = List<int>.generate(
      (bitLength + 7) ~/ 8,
      (i) => _random.nextInt(256),
    );
    
    // Ensure the number has exactly bitLength bits
    bytes[0] |= 0x80; // Set the high bit
    bytes[bytes.length - 1] |= 0x01; // Ensure it's odd (for primality)
    
    return BigInt.parse(
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      radix: 16,
    );
  }
  
  /// Generate a random BigInt in the range [min, max]
  BigInt _generateRandomInRange(BigInt min, BigInt max) {
    final range = max - min;
    final bitLength = range.bitLength;
    
    while (true) {
      final candidate = _generateRandomBits(bitLength);
      if (candidate <= range) {
        return min + candidate;
      }
    }
  }
  
  /// Check if a number is probably prime using the Miller-Rabin test
  Future<bool> _isProbablePrime(BigInt n, int k) async {
    if (n <= BigInt.one) return false;
    if (n <= BigInt.from(3)) return true;
    if (n.isEven) return false;
    
    // Write n-1 as 2^r * d
    BigInt d = n - BigInt.one;
    int r = 0;
    while (d.isEven) {
      d = d ~/ BigInt.two;
      r++;
    }
    
    // Witness loop
    for (int i = 0; i < k; i++) {
      final a = _generateRandomInRange(BigInt.two, n - BigInt.two);
      var x = _modPow(a, d, n);
      
      if (x == BigInt.one || x == n - BigInt.one) continue;
      
      bool continueOuterLoop = false;
      for (int j = 0; j < r - 1; j++) {
        x = _modPow(x, BigInt.two, n);
        if (x == BigInt.one) return false;
        if (x == n - BigInt.one) {
          continueOuterLoop = true;
          break;
        }
      }
      
      if (continueOuterLoop) continue;
      return false;
    }
    
    return true;
  }
  
  /// Calculate the least common multiple of two numbers
  BigInt _lcm(BigInt a, BigInt b) {
    return (a * b) ~/ _gcd(a, b);
  }
  
  /// Calculate the greatest common divisor of two numbers
  BigInt _gcd(BigInt a, BigInt b) {
    while (b != BigInt.zero) {
      final temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }
  
  /// L function: L(x) = (x - 1) / n
  BigInt _L(BigInt x) {
    return (x - BigInt.one) ~/ _n!;
  }
  
  /// Calculate modular exponentiation: base^exponent mod modulus
  BigInt _modPow(BigInt base, BigInt exponent, BigInt modulus) {
    if (modulus == BigInt.one) return BigInt.zero;
    
    BigInt result = BigInt.one;
    base = base % modulus;
    
    while (exponent > BigInt.zero) {
      if (exponent & BigInt.one == BigInt.one) {
        result = (result * base) % modulus;
      }
      exponent = exponent >> 1;
      base = (base * base) % modulus;
    }
    
    return result;
  }
  
  /// Calculate modular inverse: a^(-1) mod m
  BigInt _modInverse(BigInt a, BigInt m) {
    BigInt m0 = m;
    BigInt y = BigInt.zero;
    BigInt x = BigInt.one;
    
    if (m == BigInt.one) return BigInt.zero;
    
    while (a > BigInt.one) {
      BigInt q = a ~/ m;
      BigInt t = m;
      
      m = a % m;
      a = t;
      t = y;
      
      y = x - q * y;
      x = t;
    }
    
    if (x < BigInt.zero) x += m0;
    
    return x;
  }
}
