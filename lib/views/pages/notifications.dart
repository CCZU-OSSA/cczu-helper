import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/config.dart';
import 'package:cczu_helper/controllers/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Scheduler? scheduler;
  late ApplicationConfigs configs;
  @override
  void initState() {
    super.initState();
    var bus = ArcheBus();
    scheduler = bus.of();
    configs = bus.of();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("通知设置"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 12,
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_on),
                    title: const Text("启用通知"),
                    subtitle: const Text("Enable Notifications"),
                    value: configs.notificationsEnable.getOr(false),
                    onChanged: (bool value) async {
                      if (value == false) {
                        await Scheduler.cancelAll();
                      } else {
                        await Scheduler.scheduleNext();
                      }

                      setState(() {
                        configs.notificationsEnable.write(value);
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text("课前提醒"),
                    subtitle: const Text("Course Reminder"),
                    trailing:
                        Text("${configs.notificationsReminder.getOr(15)} 分钟"),
                    onTap: () => ComplexDialog.instance
                        .input(
                            context: context,
                            autofocus: true,
                            title: const Text("输入整数"),
                            decoration: const InputDecoration(
                              labelText: "课前提醒(分钟)",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number)
                        .then(
                      (value) {
                        if (value == null) {
                          return;
                        }
                        var reminder = int.tryParse(value);

                        if (reminder == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("\"$value\" 不是一个整数")));
                          return;
                        }

                        setState(() {
                          configs.notificationsReminder.write(reminder);
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: const Text("查看计划中的通知"),
                    subtitle: const Text("Notifications"),
                    onTap: () async {
                      if (scheduler == null) {
                        return;
                      }

                      await scheduler!.getScheduleNotifications().then(
                            (value) => showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: ListView(
                                    children: value
                                        .map(
                                          (e) => Card(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .outlineVariant,
                                            child: ListTile(
                                              title: Text(e.title.toString()),
                                              subtitle: Text(e.body.toString()),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                );
                              },
                            ),
                          );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text("通知权限"),
                    subtitle: const Text("Notification Permission"),
                    onTap: () {
                      var plugin = Scheduler.plugin
                          .resolvePlatformSpecificImplementation<
                              AndroidFlutterLocalNotificationsPlugin>();
                      plugin?.requestNotificationsPermission().then(
                            (notification) => plugin
                                .requestExactAlarmsPermission()
                                .then(
                                  (alarm) => ComplexDialog.instance.text(
                                    context: context,
                                    title: const Text("权限状态"),
                                    content:
                                        Text("通知:$notification，精确通知:$alarm"),
                                  ),
                                ),
                          );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: const Text("测试通知"),
                    subtitle: const Text("Test Notification"),
                    onTap: () {
                      Scheduler.scheduleTest();
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
