// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:tp_link_firewall_client/tplink/constants.dart';
import '../tplink/models/black_listed.dart';
import '../tplink/models/device.dart';
import '../tplink/device_type.dart';
import '../tplink/tp_link.dart';

class MainPage extends StatefulWidget {
  final String title;

  const MainPage({Key? key, required this.title}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Device> _devices = [];
  late TpLink _router;
  bool _fetchingDevices = false;

  _MainPageState() {
    _router = TpLink(Constants.routerIP);
    Future.delayed(const Duration(seconds: 1))
        .then((_) => _refreshDevicesAsync());
  }

  Future _refreshDevicesAsync() async {
    if (_fetchingDevices) {
      return;
    }

    _fetchingDevices = true;
    setState(() {
      _devices.clear();
      _fetchingDevices = true;
    });

    try {
      await _router.connectAsync(
          Constants.routerUser, Constants.routerPassword);
      final List<dynamic> list = await _router.getSmartNetworkAsync();
      if (list.isNotEmpty) {
        setState(() {
          for (final element in list) {
            _devices.add(Device.fromJson(element));
          }
        });

        final List<dynamic> blackListed = await _router.getBlackListAsync();
        for (int i = 0; i < blackListed.length; i++) {
          final blocked = blackListed[i];
          var bd = BlackListed.fromJson(blocked);
          final Device? bdDevice = _devices
              .cast<Device?>()
              .firstWhere((x) => bd.mac == x?.mac, orElse: () => null);
          if (bdDevice != null) {
            bdDevice
              ..isBlocked = true
              ..blockedIndex = i;
          } else {
            _devices.add(Device(bd.mac!, bd.ip!, bd.name ?? "?")
              ..isBlocked = true
              ..blockedIndex = i
              ..deviceType = bd.deviceType);
          }
        }

        _devices.sort((a, b) => a.name.compareTo(b.name));
      }

      await _router.logoutAsync();
      setState(() {
        _fetchingDevices = false;
      });
    } catch (err) {
      setState(() {
        _devices.clear();
        _fetchingDevices = false;
      });

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Exception: $err"),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future tapHandlerAsync(Device device) async {
    if (!device.canBlock || device.isBusy) {
      return;
    }

    device.isBusy = true;
    setState(() {
      device.isBusy = true;
    });

    await _router.connectAsync(Constants.routerUser, Constants.routerPassword);
    var data = [];
    try {
      if (device.isBlocked) {
        data = await _router.unblockAsync(device.blockedIndex!);
      } else if (device.canBlock) {
        data = await _router.blockAsync(device);
      }

      if (data.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        _refreshDevicesAsync();
      }
    } catch (err) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Error"),
              content: Text("Exception: $err"),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }

    await _router.logoutAsync();

    setState(() {
      device.isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
          child: Stack(
        children: [
          Visibility(
            visible: _fetchingDevices,
            child: const SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 10,
              ),
            ),
          ),
          Visibility(
            visible: !_fetchingDevices,
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                // return ListTile(title: Text(_devices[index].hostname));
                return Card(
                  child: InkWell(
                    splashColor: Colors.blue.withAlpha(30),
                    onTap: () {
                      tapHandlerAsync(_devices[index]);
                    },
                    child: SizedBox(
                      height: 100,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              _devices[index].name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "  (${_devices[index].ip})",
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "MAC: ${_devices[index].mac}",
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Band: ${_devices[index].band}",
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        leading: Icon(
                          _devices[index].deviceType == DeviceType.mobile
                              ? Icons.stay_primary_portrait
                              : _devices[index].deviceType == DeviceType.pc
                                  ? Icons.laptop
                                  : Icons.devices,
                          color: Colors.white,
                        ),
                        trailing: CircularProgressIndicator(
                          value: _devices[index].isBusy ? null : 0,
                          color: Colors.white,
                        ),
                        tileColor: _devices[index].canBlock
                            ? _devices[index].isBlocked
                                ? const Color.fromARGB(255, 182, 5, 2)
                                : Colors.green.shade700
                            : Colors.grey,
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )),
      floatingActionButton: SizedBox(
        height: 80,
        width: 80,
        child: FloatingActionButton(
          onPressed: _refreshDevicesAsync,
          tooltip: 'Refresh',
          child: const Icon(
            Icons.refresh,
            size: 48,
          ),
        ),
      ),
    );
  }
}
