import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  late RSAPublicKey _publicKey;
  String? _peerPublicKeyPem;
  
  // Generate RSA key pair
  Future<void> generateKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(_seed())),
      ));

    final pair = keyGen.generateKeyPair();
    _publicKey = pair.publicKey as RSAPublicKey;
  }

  Uint8List _seed() {
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    return Uint8List.fromList(seeds);
  }

  // Get public key as PEM string
  String getPublicKeyPem() {
    final modulus = _publicKey.modulus!.toRadixString(16);
    final exponent = _publicKey.exponent!.toRadixString(16);
    return 'RSA:$modulus:$exponent';
  }

  // Get key fingerprint for display
  String getKeyFingerprint() {
    final publicKeyPem = getPublicKeyPem();
    final bytes = utf8.encode(publicKeyPem);
    final digest = sha256.convert(bytes);
    final hex = digest.toString();
    
    // Format as: XX:XX:XX:XX:XX:XX:XX:XX
    final parts = <String>[];
    for (int i = 0; i < 32; i += 4) {
      parts.add(hex.substring(i, i + 4).toUpperCase());
    }
    return parts.join(':');
  }

  // Store peer's public key
  void setPeerPublicKey(String peerKeyPem) {
    _peerPublicKeyPem = peerKeyPem;
  }

  // Get peer's key fingerprint
  String? getPeerKeyFingerprint() {
    if (_peerPublicKeyPem == null) return null;
    
    final bytes = utf8.encode(_peerPublicKeyPem!);
    final digest = sha256.convert(bytes);
    final hex = digest.toString();
    
    final parts = <String>[];
    for (int i = 0; i < 32; i += 4) {
      parts.add(hex.substring(i, i + 4).toUpperCase());
    }
    return parts.join(':');
  }

  // Verify keys match (for end-to-end encryption verification)
  bool verifyPeerKey(String displayedFingerprint) {
    return getPeerKeyFingerprint() == displayedFingerprint;
  }
}
