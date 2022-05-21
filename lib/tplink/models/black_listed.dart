import '../device_type.dart';

class BlackListed {
  late DeviceType deviceType;
  String? name;
  bool anonymous = true;
  String? connType;
  String? host;
  String? key;
  String? mac;
  String? type;
  String? ip;

  BlackListed({
    this.name,
    this.connType,
    this.host,
    this.key,
    this.mac,
    this.type,
    this.ip,
  });

  BlackListed.fromJson(Map<String, dynamic> json) {
    anonymous = json['.anonymous'];
    connType = json['conn_type'];
    deviceType = json['deviceType'] == "phone"
        ? DeviceType.mobile
        : json['deviceType'] == "pc"
            ? DeviceType.pc
            : DeviceType.unknown;
    host = json['host'];
    key = json['key'];
    name = json['name'];
    mac = json['mac'];
    type = json['.type'];
    ip = json['ipaddr'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['.name'] = name;
    data['.anonymous'] = anonymous;
    data['conn_type'] = connType;
    data['deviceType'] = deviceType;
    data['host'] = host;
    data['key'] = key;
    data['name'] = name;
    data['mac'] = mac;
    data['.type'] = type;
    data['ipaddr'] = ip;
    return data;
  }
}
