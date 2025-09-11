import 'dart:async';
import 'dart:convert';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/navigator.dart';
import 'package:cczu_helper/controllers/snackbar.dart';
import 'package:cczu_helper/src/bindings/bindings.dart';
import 'package:flutter/material.dart';
import 'package:rinf/rinf.dart';

class ElectricBillPage extends StatefulWidget {
  const ElectricBillPage({super.key});

  @override
  State<StatefulWidget> createState() => ElectricBillPageState();
}

class ElectricBillPageState extends State<ElectricBillPage> {
  @override
  Widget build(BuildContext context) {
    final configs = ArcheBus().of<ApplicationConfigs>();
    final rooms = configs.subscribeElectricBillRooms.tryGet() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("查电费"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          pushMaterialRoute(
                  builder: (context) => const ElectricBillManagerPage())
              .then((_) => setState(() {}));
        },
        child: Icon(Icons.add),
      ),
      body: ListView(
        children: [
          ...rooms.map((room) {
            return ElectricBillListTile(
                room: room,
                refresh: () {
                  setState(() {});
                });
          })
        ],
      ),
    );
  }
}

class ElectricBillManagerPage extends StatefulWidget {
  const ElectricBillManagerPage({super.key});

  @override
  State<StatefulWidget> createState() => ElectricBillManagerPageState();
}

class ElectricBillManagerPageState extends State<ElectricBillManagerPage> {
  Building? selectedBuilding;
  String? selectedAreaId;
  String? selectedArea;
  String? selectedRoom;
  late final PageController _pageController;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
    ElectricBillBuildingsQueryInput().sendSignalToRust();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ArcheBus().of<ApplicationConfigs>();

    return StreamBuilder(
      stream: ElectricBillBuildingsQueryOutput.rustSignalStream,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: const Text("添加寝室"),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ElectricBillBuildingsQueryInput().sendSignalToRust();
                },
              ),
            ],
          ),
          body: data == null
              ? Center(child: CircularProgressIndicator())
              : data.message.error != null
                  ? Center(
                      child: Text(data.message.error.toString()),
                    )
                  : PageView(
                      controller: _pageController,
                      children: [
                        ListView(
                          children: [
                            ...data.message.buildings.map(
                              (e) {
                                return ExpansionTile(
                                  shape: Border(),
                                  title: Text(e.area,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  children: e.buildings.map((building) {
                                    return ListTile(
                                        title: Text(building.building),
                                        onTap: () {
                                          setState(() {
                                            selectedBuilding = building;
                                            selectedArea = e.area;
                                            selectedAreaId = e.areaid;
                                          });
                                          _pageController.nextPage(
                                              duration:
                                                  Duration(milliseconds: 300),
                                              curve: Curves.easeInOut);
                                        });
                                  }).toList(),
                                );
                              },
                            )
                          ],
                        ),
                        ListView(
                          children: [
                            ListTile(
                              title: Text("宿舍楼"),
                              subtitle: Text(
                                  "${selectedBuilding?.building} ($selectedArea)"),
                              onTap: () {
                                _pageController.previousPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                              },
                            ),
                            ListTile(
                              title: Text("寝室号"),
                              subtitle: Text(
                                  "寝室号可能为 宿舍楼-寝室号 (如 1-101)，也可能为纯寝室号 (如 101)，根据宿舍楼而定"),
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                  horizontal: 12, vertical: 4),
                              child: TextField(
                                maxLines: 1,
                                onChanged: (value) {
                                  selectedRoom = value;
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "请输入寝室号",
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: FilledButton(
                                onPressed: () {
                                  if (selectedBuilding == null ||
                                      selectedAreaId == null ||
                                      selectedArea == null ||
                                      selectedRoom == null ||
                                      selectedRoom!.isEmpty) {
                                    showSnackBar(
                                      context: context,
                                      content: Text("请完整填写信息"),
                                    );
                                    return;
                                  }
                                  final rooms = configs
                                          .subscribeElectricBillRooms
                                          .tryGet() ??
                                      [];

                                  rooms.add(SubscribeElectricBillRoom(
                                      building: selectedBuilding!.building,
                                      buildingId: selectedBuilding!.buildingid,
                                      area: selectedArea!,
                                      areaId: selectedAreaId!,
                                      room: selectedRoom!));
                                  configs.subscribeElectricBillRooms
                                      .write(rooms);
                                  Navigator.pop(context);
                                },
                                child: Text("添加"),
                              ),
                            )
                          ],
                        )
                      ],
                    ),
        );
      },
    );
  }
}

class SubscribeElectricBillRoom {
  final String building;
  final String buildingId;
  final String area;
  final String areaId;
  final String room;

  SubscribeElectricBillRoom({
    required this.building,
    required this.area,
    required this.areaId,
    required this.room,
    required this.buildingId,
  });

  String toJson() {
    return jsonEncode({
      "building": building,
      "buildingId": buildingId,
      "area": area,
      "areaId": areaId,
      "room": room,
    });
  }

  static SubscribeElectricBillRoom fromJson(String raw) {
    final data = jsonDecode(raw);

    return SubscribeElectricBillRoom(
        building: data["building"],
        area: data["area"],
        areaId: data["areaId"],
        room: data["room"],
        buildingId: data["buildingId"]);
  }
}

class ElectricBillListTile extends StatefulWidget {
  final SubscribeElectricBillRoom room;
  final VoidCallback refresh;
  const ElectricBillListTile(
      {super.key, required this.room, required this.refresh});

  @override
  State<StatefulWidget> createState() => ElectricBillListTileState();
}

class ElectricBillListTileState extends State<ElectricBillListTile> {
  late final StreamSubscription<RustSignalPack<ElectricBillRoomQueryOutput>>
      onceSubscription;

  String? data;
  String? error;

  @override
  void initState() {
    super.initState();
    final room = widget.room;
    final uniqueId = "${room.buildingId}-${room.room}-${room.areaId}";
    onceSubscription = ElectricBillRoomQueryOutput.rustSignalStream
        .where((event) => event.message.uniqueid == uniqueId)
        .listen((event) {
      final data = event;
      if (data.message.ok) {
        setState(() {
          this.data = data.message.remain;
          error = null;
        });
      } else {
        setState(() {
          this.data = null;
          error = data.message.error ?? "未知错误";
        });
      }
    });
    ElectricBillRoomQueryInput(
            buildingid: room.buildingId,
            building: room.building,
            areaid: room.areaId,
            area: room.area,
            room: room.room,
            uniqueid: uniqueId)
        .sendSignalToRust();
  }

  @override
  void dispose() {
    onceSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configs = ArcheBus().of<ApplicationConfigs>();
    final room = widget.room;

    return ListTile(
        title: Text("${room.room} (${room.area} ${room.building})"),
        subtitle:
            data != null ? Text(data.toString()) : LinearProgressIndicator(),
        onLongPress: () {
          ComplexDialog.instance
              .confirm(
                  context: context,
                  title: const Text("删除寝室?"),
                  content: Text("确认删除 ${room.building} ${room.room} ?"))
              .then((confirmed) {
            if (confirmed) {
              final rooms = configs.subscribeElectricBillRooms.tryGet() ?? [];

              rooms.removeWhere((element) =>
                  element.buildingId == room.buildingId &&
                  element.room == room.room);
              configs.subscribeElectricBillRooms.write(rooms);
              widget.refresh();
            }
          });
        });
  }
}
