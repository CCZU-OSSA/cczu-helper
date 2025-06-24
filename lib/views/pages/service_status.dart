import 'dart:async';
import 'dart:collection';

import 'package:cczu_helper/src/bindings/bindings.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';

class ServiceStatusPage extends StatefulWidget {
  const ServiceStatusPage({super.key});

  @override
  State<StatefulWidget> createState() => ServiceStatusPageState();
}

class ServiceStatusPageState extends State<ServiceStatusPage> {
  final Map<String, String> _data = HashMap();
  late StreamSubscription<RustSignalPack<ServiceStatusOutput>> _subscription;
  @override
  void initState() {
    _subscription = ServiceStatusOutput.rustSignalStream.listen((signal) {
      if (mounted) {
        setState(() {
          _data.clear();
          _data.addAll(signal.message.data);
        });
      }
    });

    ServiceStatusInput().sendSignalToRust();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _data.keys.toList();
    keys.sort();
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Text("服务状态"),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  _data.clear();
                });
                ServiceStatusInput().sendSignalToRust();
              },
              icon: Icon(Icons.refresh))
        ],
      ),
      body: Padding(
        key: ValueKey(_data.isEmpty),
        padding: EdgeInsetsGeometry.all(8),
        child: _data.isEmpty
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: keys.map((key) {
                  final val = _data[key].toString();
                  return Card.outlined(
                    child: ListTile(
                      title: Text(key),
                      subtitle: Text(val),
                      trailing: val.startsWith("2")
                          ? Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            )
                          : Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
