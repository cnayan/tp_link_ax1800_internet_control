import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/pointycastle.dart';

class Aes {
  static String encryptWithPublicKey(final String plainText, final String modulus_, String exponent_) {
    final modulus = BigInt.parse(modulus_, radix: 16);
    final exponent = BigInt.parse(exponent_, radix: 16);
    final RSAPublicKey publicKey = RSAPublicKey(modulus, exponent);

    final Encrypter encrypter = Encrypter(RSA(publicKey: publicKey, encoding: RSAEncoding.PKCS1));
    final Encrypted encrypted = encrypter.encrypt(plainText);
    final String asString = hex.encode(encrypted.bytes);
    return asString;
  }

  static String encryptData(String plainText, final Key key, final IV iv) {
    final Encrypter encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"));
    final Encrypted encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  static String decryptData(Uint8List encryptedBytes, final Key key, final IV iv) {
    final Encrypter encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: "PKCS7"));
    final String decrypted = encrypter.decrypt(Encrypted(encryptedBytes), iv: iv);
    return decrypted;
  }
}
