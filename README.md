# TP-Link AX1800 - Internet Control

A Flutter project to control internet access of devices connected to TP-Link AX1800 router.

I have added Android and Windows as platform targets. You can alter them.

# Credentials
Please make sure you set the credentials and IP of router correctly. Code won't build without it.

File: constants.dart

```dart
class Constants {
  static const routerIP = <IP>;
  static const routerUser = <USER>; //admin
  static const routerPassword = <PASSWORD>;

  static final List<WhiteListedDevice> unblockableDevices = [
    WhiteListedDevice("XX-XX-XX-XX-XX-XX", DeviceType.mobile),
    WhiteListedDevice("YY-YY-YY-YY-YY-YY", DeviceType.pc)
  ];
}
```

Also, if you don't want accidental blockage of certain devices (that is in your/admin's possession), place their MAC in the `unblockableDevices` collection.

# Behavior
The trick used to grant/block access of internet to devices is by placing the device in blacklist (to block) or removing it from blacklist (to grant internet access.)
Note that the unblocked device has to reconnect to router to get internet. This is standard behavior of any network device and is out of scope of this project.

# Supported TP Link device models
* AX1800
  * Firmware version: 1.3.5 Build 20211231 rel.63820(5553)
* C2300
  * Firmware version: Unknown

# Thanks
I thank [Electry](https://github.com/Electry) for providing base idea on how to communicate with my router. Apparently, AX1800 and C2300 have same API in their firmware.
His inpiring repo: https://github.com/Electry/TPLink-C2300-APIClient
