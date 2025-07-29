import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart' show md5;
import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import '../crypt/aes.dart';
import '../utils/utils.dart';
import 'models/device.dart';

class TpLink {
  // ignore: non_constant_identifier_names
  final _HEADERS = {
    "Accept": "application/json, text/javascript, */*; q=0.01",
    "Accept-Encoding": "gzip, deflate",
    "Accept-Language": "en-US,en;q=0.9",
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv {90.0) Gecko/20100101 Firefox/90.0',
    "X-Requested-With": "XMLHttpRequest",
    "Connection": "keep-alive",
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    "Referer": "http://tplinkwifi.net/webpages/index.html?t=29ba1aa0",
  };

  final _uuid = const Uuid();
  late final String _host;
  late String? _token;
  late String? _md5HashPassword;
  late Tuple2<String, String> _generatedKeyAndIV;
  late Tuple2<String, String> _rsaPasswordPubKeys;
  late Tuple3<String, String, int> _rsaAuthPubKeys;
  late String _encryptedPassword;
  // req;

  TpLink(this._host) {
    // req = requests.Session()
    _token = null;
  }

  Future connectAsync(String user, String password,
      {bool logoutOthers = false}) async {
    // hash the password
    _md5HashPassword = __hashPassword(user, password);

    // generate AES key
    _generatedKeyAndIV = __genAESKey();

    // request public RSA keys from the router
    _rsaPasswordPubKeys = await __reqRSAPasswordKeysAsync();
    _rsaAuthPubKeys = await __reqRSAAuthKeysAsync();

    // encrypt the password
    _encryptedPassword = __encryptPassword(password);

    // authenticate
    try {
      _token = await __reqLoginAsync(_encryptedPassword);
    } catch (e) {
      if (!logoutOthers) {
        rethrow;
      }

      _token = await __reqLoginAsync(_encryptedPassword, forceLogin: true);
    }
  }

  Future logoutAsync() async {
    if (_token == null) {
      return false;
    }

    final success = await __reqLogoutAsync();
    _token = null;

    return success;
  }

  Future<List<dynamic>> getSmartNetworkAsync() async {
    var data = await getApiAsync('admin/smart_network', 'game_accelerator',
        data: {'operation': 'loadDevice'});
    if (data == null) return [];
    return data;
  }

  // Future<List<dynamic>> getClientList() async {
  //   final data = await getApi('admin/status', 'client_status');
  //   if (data == null) return [];
  //   return data["access_devices_wireless_host"];
  // }

  // Future<dynamic> getAll() async {
  //   final data = await getApi('admin/status', 'all');
  //   return data;
  // }

  Future<List<dynamic>> getBlackListAsync() async {
    final data = await getApiAsync('admin/access_control', 'black_list',
        data: {'operation': 'load'});
    if (data is Map<String, dynamic> && data.isEmpty) {
      return [];
    }

    if (data == null) {
      return [];
    }

    return data;
  }

  Future blockAsync(Device device) async {
    final data =
        await getApiAsync('admin/access_control', 'black_devices', data: {
      "operation": "block",
      "key": device.key,
      "data": [
        {
          "key": device.key,
          "deviceType": device.deviceType.toString().split('.').last,
          "name": device.name,
          "mac": device.mac,
          "ipaddr": device.ip,
          "conn_type": "wireless",
          "host": "NOT HOST",
        }
      ],
      "index": device.index!,
    });

    if (data == null) return [];
    return data;
  }

  Future<List<dynamic>> unblockAsync(int index) async {
    // Generate a v1 (time-based) id
    final String guid = _uuid.v1(); // -> '6c84fb90-12c4-11e1-840d-7b25c5ee775a'

    final data = await getApiAsync('admin/access_control', 'black_list', data: {
      "key": "key-$guid",
      "index": "$index",
      "operation": "remove",
    });

    if (data == null) return [];
    return data;
  }

  Future<dynamic> getApiAsync(final String api, final String endpoint,
      {Map<String, dynamic> data = const {'operation': 'read'}}) async {
    final url = _getUrl(api, endpoint);

    var resp = await __requestAsync(url, data, encrypt: true);
    if (resp["success"] == true) {
      return resp["data"];
    } else {
      log("Error: $resp");
    }

    return null;
  }

  void __updateCookie(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      _HEADERS['cookie'] = rawCookie;
    }
  }

  Future<Map<String, dynamic>> __requestAsync(
      final String url, final Map<String, dynamic> data,
      {bool encrypt = false, bool isLogin = false}) async {
    Map<String, dynamic> formData = data;
    dynamic dataString = data;
    if (encrypt) {
      dataString = __formatBodyToEncrypt(data);

      // encrypt the body
      final Key key = Key(Utils.asUint8List(_generatedKeyAndIV.item1));
      final IV iv = IV(Utils.asUint8List(_generatedKeyAndIV.item2));
      final String encryptedData = Aes.encryptData(dataString, key, iv);

      // get encrypted signature
      final String signature =
          __getSignature(encryptedData.length, isLogin: isLogin);

      // order matters here! signature needs to go first (or we get empty 403 response)
      formData = {'sign': signature, 'data': encryptedData};
    }

    final resp = await http.post(
      Uri.parse(url),
      headers: _HEADERS,
      body: formData,
    );

    log("<Request ${resp.request!.url.toString()}\r\n\t$dataString\r\n>");

    if (resp.statusCode.toString()[0] != "2") {
      log("Not Okay: ${resp.statusCode} - ${resp.reasonPhrase}");

      final Uint8List encoded = base64Decode(resp.body);

      // decrypt the response using our AES key
      final Key key = Key(Utils.asUint8List(_generatedKeyAndIV.item1));
      final IV iv = IV(Utils.asUint8List(_generatedKeyAndIV.item2));
      final String unencrypted = Aes.decryptData(encoded, key, iv);

      log(unencrypted);

      throw Exception("${resp.statusCode} - ${resp.reasonPhrase}");
    }

    __updateCookie(resp);

    if (encrypt) {
      // parse the json response
      final rawResponseJson = jsonDecode(resp.body);

      // decode base64 string
      final String base64Encoded = rawResponseJson['data'];
      if (base64Encoded.isEmpty) {
        return {};
      }

      final Uint8List encoded = base64Decode(base64Encoded);

      // decrypt the response using our AES key
      final Key key = Key(Utils.asUint8List(_generatedKeyAndIV.item1));
      final IV iv = IV(Utils.asUint8List(_generatedKeyAndIV.item2));
      final String unencrypted = Aes.decryptData(encoded, key, iv);

      log("<Response: $unencrypted>");

      return jsonDecode(unencrypted);
    }

    return jsonDecode(resp.body);
  }

  String __formatBodyToEncrypt(Map<String, dynamic> data) {
    // format form data into a string
    Map<String, dynamic> d = jsonDecode(jsonEncode(data));

    var dataArr = [];
    for (var ent in d.entries) {
      final key = ent.key;
      final value = ent.value is num || ent.value is String || ent.value is bool
          ? ent.value
          : Uri.encodeComponent(jsonEncode(ent.value));
      dataArr.add("$key=$value");
    }

    return dataArr.join('&');
  }

  String __hashPassword(String arg1, String? arg2) {
    final fullString = arg1 + (arg2 ?? "");
    Uint8List stringAsBytes = Utils.asUint8List(fullString);
    String result = md5.convert(stringAsBytes).toString();
    return result;
  }

  String __encryptPassword(String password) {
    final encrypted = Aes.encryptWithPublicKey(
        password, _rsaPasswordPubKeys.item1, _rsaPasswordPubKeys.item2);
    return encrypted;
  }

  Tuple2<String, String> __genAESKey() {
    const keyLength = 16;
    const ivLength = 16;
    const minimum = 100000000;
    const maximum = 1000000000 - 1;

    final random = math.Random();

    final now = DateTime.now();
    final ts = now.millisecondsSinceEpoch.toString();

    String rand1 = (random.nextInt(maximum - minimum) + minimum).toString();
    String rand2 = (random.nextInt(maximum - minimum) + minimum).toString();
    rand1 = ts + rand1;
    rand2 = ts + rand2;

    final String key = rand1.substring(0, keyLength);
    final String iv = rand2.substring(0, ivLength);

    return Tuple2(key, iv);
  }

  String __getSignature(int bodyDataLength, {bool isLogin = false}) {
    final rsaSeqNumber = _rsaAuthPubKeys.item3;

    String signData;
    if (isLogin) {
      final String aesKey = _generatedKeyAndIV.item1;
      final String aesIV = _generatedKeyAndIV.item2;
      final String aesKeyString = "k=$aesKey&i=$aesIV";

      // on login we also send our AES key, which is subsequently used for E2E encrypted communication
      signData =
          "$aesKeyString&h=$_md5HashPassword&s=${rsaSeqNumber + bodyDataLength}";
    } else {
      signData = "h=$_md5HashPassword&s=${rsaSeqNumber + bodyDataLength}";
    }

    String signature = "";
    int pos = 0;

    // encrypt the signature using the RSA auth public key
    while (pos < signData.length) {
      final sub = signData.substring(pos, math.min(signData.length, pos + 53));
      final String enc = Aes.encryptWithPublicKey(
          sub, _rsaAuthPubKeys.item1, _rsaAuthPubKeys.item2);
      signature += enc;
      pos += 53;
    }

    return signature;
  }

  Future<Tuple2<String, String>> __reqRSAPasswordKeysAsync() async {
    final String url = _getUrl('login', 'keys');
    const Map<String, String> data = {'operation': 'read'};

    final Map<String, dynamic> response =
        await __requestAsync(url, data, encrypt: false);
    if (response['success'] == false) {
      throw Exception("Could not fetch Pass Keys");
    }

    final passwordPubKey = response['data']['password'];

    return Tuple2(passwordPubKey[0], passwordPubKey[1]);
  }

  Future<Tuple3<String, String, int>> __reqRSAAuthKeysAsync() async {
    final String url = _getUrl('login', 'auth');
    final Map<String, dynamic> data = {'operation': 'read'};

    final Map<String, dynamic> response =
        await __requestAsync(url, data, encrypt: false);
    final List<dynamic> authPubKey = response['data']['key'];

    return Tuple3(authPubKey[0].toString(), authPubKey[1].toString(),
        response['data']['seq']);
  }

  Future<String> __reqLoginAsync(String encryptedPassword,
      {bool forceLogin = false}) async {
    final String url = _getUrl('login', 'login');
    final Map<String, dynamic> data = {
      'operation': 'login',
      'password': encryptedPassword
    };

    if (forceLogin) {
      data['confirm'] = 'true';
    }

    final Map<String, dynamic> response =
        await __requestAsync(url, data, encrypt: true, isLogin: true);
    return response['data']['stok'];
  }

  Future<dynamic> __reqLogoutAsync() async {
    final url = _getUrl('admin/system', 'logout');
    final data = {'operation': 'write'};

    final Map<String, dynamic> response =
        await __requestAsync(url, data, encrypt: true);
    return response['success'];
  }

  String _getUrl(String endpoint, String form) {
    final String stok = _token ?? '';
    return "http://$_host/cgi-bin/luci/;stok=$stok/$endpoint?form=$form";
  }
}
