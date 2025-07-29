import 'dart:math';
import 'dart:typed_data';

class Utils {
  static Uint8List asUint8List(String s) {
    var ret = Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }

    return ret;
  }

  static String pad(final List<int> dataToPad, final int blockSize,
      {String style = 'pkcs7'}) {
    String padding;
    final paddingLength = blockSize - dataToPad.length % blockSize;
    if (style == 'pkcs7') {
      padding = bchr(paddingLength) * paddingLength;
    } else if (style == 'x923') {
      padding = bchr(0) * (paddingLength - 1) + bchr(paddingLength);
    } else if (style == 'iso7816') {
      padding = bchr(128) + (bchr(0) * (paddingLength - 1));
    } else {
      throw Exception("Unknown padding style");
    }
    return String.fromCharCodes(dataToPad) + padding;
  }

  static String bchr(int c) {
    return String.fromCharCode(c);
  }

  static List<int> unpad(final List<int> paddedData, final int blockSize,
      {String style = 'pkcs7'}) {
    final int pdataLen = paddedData.length;
    if (pdataLen == 0) {
      throw Exception("Zero-length input cannot be unpadded");
    }

    if (pdataLen % blockSize > 0) {
      throw Exception("Input data is not padded");
    }

    if (['pkcs7', 'x923'].contains(style)) {
      final int paddingLength = paddedData[paddedData.length - 1];
      if (paddingLength < 1 || paddingLength > min(blockSize, pdataLen)) {
        throw Exception("Padding is incorrect.");
      }

      if (style == 'pkcs7') {
        final String range = String.fromCharCodes(paddedData.getRange(
            paddedData.length - paddingLength, paddedData.length));
        final String padded = bchr(paddingLength) * paddingLength;
        if (range != padded) {
          throw Exception("PKCS#7 padding is incorrect.");
        }
      } else {
        if (String.fromCharCodes(paddedData.getRange(
                paddedData.length - paddingLength, paddedData.length - 1)) !=
            bchr(0) * (paddingLength - 1)) {
          throw Exception("ANSI X.923 padding is incorrect.");
        }
      }
    }
    // else if (style == 'iso7816') {
    //     final paddingLength = pdata_len - padded_data.reversed.toList(growable: false).firstWhere((x) => x == 128);
    //     if (paddingLength<1 || paddingLength>min(block_size, pdata_len)) {
    //       throw Exception("Padding is incorrect.");
    //     }
    //     if (paddingLength>1 && padded_data[1-paddingLength:]!=bchr(0)*(paddingLength-1)) {
    //       throw Exception("ISO 7816-4 padding is incorrect.");
    //     }
    // }
    else {
      throw Exception("Unknown padding style");
    }

    return paddedData
        .getRange(paddedData.length - 2, paddedData.length)
        .toList(growable: false);
  }

  // String hexlify(dynamic str) {
  //   var result = "";
  //   const padding = "00";
  //   for (var i = 0, l = str.length; i < l; i++) {
  //     var digit = str.charCodeAt(i).toString(16);
  //     var s = padding + digit;
  //     var padded = s.substring(s.length - 2);
  //     result += padded;
  //   }

  //   return result;
  // }
}
