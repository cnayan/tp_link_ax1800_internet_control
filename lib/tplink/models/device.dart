import 'package:tp_link_firewall_client/tplink/constants.dart';

import '../device_type.dart';

class Device {
  late String mac;
  late String ip;
  late String name;

  int? blockedIndex;
  DeviceType deviceType = DeviceType.unknown;
  bool isBusy = false;
  bool canBlock = true;

  int? index;
  String? key;

  int? trafficUsage;
  int? remainTime;
  int? uploadSpeed;
  num? onlineTime;
  int? downloadSpeed;
  bool? enablePriority;
  int? txrate;
  int? rxrate;
  int? timePeriod;
  String? band;
  int? signal;
  bool isBlocked = false;

  Device(
    this.mac,
    this.ip,
    this.name, {
    this.index,
    this.key,
    this.trafficUsage,
    this.remainTime,
    this.uploadSpeed,
    this.onlineTime,
    this.downloadSpeed,
    this.enablePriority,
    this.txrate,
    this.rxrate,
    this.timePeriod,
    this.band,
    this.signal,
  });

  Device.fromJson(Map<String, dynamic> json) {
    index = json['index'];
    ip = json['ip'];
    mac = json['mac'];
    name = json['deviceName'];

    trafficUsage = json['trafficUsage'];
    deviceType = json['deviceType'] == "phone"
        ? DeviceType.mobile
        : json['deviceType'] == "pc"
            ? DeviceType.pc
            : DeviceType.unknown;
    remainTime = json['remainTime'];
    key = json['key'];
    band = json['deviceTag'];
    // uploadSpeed = json['uploadSpeed'];
    // onlineTime = json['onlineTime'];
    // downloadSpeed = json['downloadSpeed'];
    // enablePriority = json['enablePriority'];
    // txrate = json['txrate'];
    // rxrate = json['rxrate'];
    // timePeriod = json['timePeriod'];
    // signal = json['signal'];

    final WhiteListedDevice? d = Constants.unblockableDevices.cast<WhiteListedDevice?>().firstWhere((x) => x?.mac == mac.toUpperCase(), orElse: () => null);
    if (d != null) {
      canBlock = false;
      deviceType = d.type; //DeviceType.mobile;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    // data['index'] = index;
    // data['trafficUsage'] = trafficUsage;
    // data['deviceType'] = deviceType.toString();
    // data['remainTime'] = remainTime;
    // data['deviceName'] = name;
    // data['key'] = key;
    // data['uploadSpeed'] = uploadSpeed;
    // data['onlineTime'] = onlineTime;
    // data['mac'] = mac;
    // data['downloadSpeed'] = downloadSpeed;
    // data['enablePriority'] = enablePriority;
    // data['txrate'] = txrate;
    // data['ip'] = ip;
    // data['rxrate'] = rxrate;
    // data['timePeriod'] = timePeriod;
    // data['deviceTag'] = band;
    // data['signal'] = signal;
    return data;
  }
}
