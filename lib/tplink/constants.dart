import 'device_type.dart';

class WhiteListedDevice {
  final String mac;
  final DeviceType type;
  WhiteListedDevice(this.mac, this.type);
}

class Constants {
  static const routerIP = <IP>;
  static const routerUser = <USER>; //admin
  static const routerPassword = <PASSWORD>;

  static final List<WhiteListedDevice> unblockableDevices = [
    WhiteListedDevice("XX-XX-XX-XX-XX-XX", DeviceType.mobile),
    WhiteListedDevice("YY-YY-YY-YY-YY-YY", DeviceType.pc),
  ];
}
