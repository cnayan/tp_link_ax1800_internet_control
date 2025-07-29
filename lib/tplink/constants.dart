import 'device_type.dart';

class WhiteListedDevice {
  final String mac;
  final DeviceType type;
  WhiteListedDevice(this.mac, this.type);
}

class Constants {
  static const String routerIP = '192.168.0.1';
  static const String routerUser = 'admin';
  static const String routerPassword = 'Sunny_81';

  static final List<WhiteListedDevice> unblockableDevices = [
    WhiteListedDevice("AA-F4-F7-E6-FD-FA", DeviceType.mobile),
    WhiteListedDevice("E8-4E-06-4B-1F-5A", DeviceType.pc),
    WhiteListedDevice("E0-D5-5E-2D-B8-74", DeviceType.pc),
  ];
}
