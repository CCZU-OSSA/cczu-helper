import 'dart:async';

import 'package:arche/arche.dart';
import 'package:arche/extensions/dialogs.dart';
import 'package:cczu_helper/controllers/accounts.dart';
import 'package:cczu_helper/src/bindings/signals/signals.dart';
import 'package:cczu_helper/views/widgets/scrollable.dart';
import 'package:flutter/material.dart';

class WeChatEvaluationPage extends StatefulWidget {
  const WeChatEvaluationPage({super.key});

  @override
  State<WeChatEvaluationPage> createState() => _WeChatEvaluationPageState();
}

class _WeChatEvaluationPageState extends State<WeChatEvaluationPage> {
  // final TextEditingController _termController = TextEditingController();
  String? _selectedTerm;
  List<String>? _terms;
  final GlobalKey<PopupMenuButtonState> _termPopMenuKey = GlobalKey();

  final TextEditingController _commentController = TextEditingController();

  // 默认评分
  int _overallScore = 100;
  final List<int> _subScores = [100, 80, 100, 80, 100, 80];
  final List<String> _subScoreLabels = [
    "教师德育",
    "教学方法",
    "课堂氛围",
    "授课内容",
    "交流互动",
    "课后作业",
  ];

  SimplifiedEvaluatableClass? _selectedClass;
  List<SimplifiedEvaluatableClass> _availableClasses = [];

  bool _isLoading = false;
  StreamSubscription? _classesSubscription;
  StreamSubscription? _evaluationSubscription;

  @override
  void initState() {
    super.initState();
    _classesSubscription =
        WeChatEvaluatableClassOutput.rustSignalStream.listen((signal) {
      if (!mounted) return;
      final message = signal.message;
      setState(() {
        _isLoading = false;
        if (message.ok) {
          _availableClasses = message.classes;
          if (_availableClasses.isNotEmpty) {
            _selectedClass = _availableClasses.first;
          } else {
            _selectedClass = null;
          }
        } else {
          _availableClasses = [];
          _selectedClass = null;
          if (message.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("查询失败: ${message.error}")));
          }
        }
      });
    });

    _evaluationSubscription =
        WeChatEvaluationOutput.rustSignalStream.listen((signal) {
      if (!mounted) return;
      final message = signal.message;
      if (message.ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("评教成功")));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("评教失败: ${message.error}")));
      }
    });
  }

  @override
  void dispose() {
    _classesSubscription?.cancel();
    _evaluationSubscription?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _fetchClasses() {
    final hasAccount =
        ArcheBus.bus.of<MultiAccoutData>().hasCurrentEduAccount();
    if (!hasAccount) {
      ComplexDialog.instance.withContext(context: context).text(
            title: const Text("错误"),
            content: const Text("未找到有效的教育网账户"),
          );
      return;
    }
    final account = ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount();

    if (_selectedTerm == null || _selectedTerm!.isEmpty) {
      ComplexDialog.instance.withContext(context: context).text(
            title: const Text("提示"),
            content: const Text("请选择学期"),
          );
      return;
    }

    setState(() {
      _isLoading = true;
      _availableClasses = [];
      _selectedClass = null;
    });
    debugPrint("Fetching evaluatable classes for term $_selectedTerm $account");
    WeChatEvaluatableClassInput(
      account: account,
      term: _selectedTerm!,
    ).sendSignalToRust();
  }

  void _submitEvaluation({SimplifiedEvaluatableClass? targetClass}) {
    if (!ArcheBus.bus.of<MultiAccoutData>().hasCurrentEduAccount()) return;
    final account = ArcheBus.bus.of<MultiAccoutData>().getCurrentEduAccount();

    final cls = targetClass ?? _selectedClass;
    if (cls == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请选择课程")),
      );
      return;
    }

    WeChatEvaluationInput(
      account: account,
      term: _selectedTerm!,
      evaluatableClass: cls,
      overallScore: _overallScore,
      scores: _subScores,
      comments:
          _commentController.text.isEmpty ? "老师讲课很好" : _commentController.text,
    ).sendSignalToRust();
  }

  void _evaluateAll() async {
    if (_availableClasses.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("一键评教"),
        content: Text(
            "确定要对所有 ${_availableClasses.length} 门课程进行默认好评吗？\n(总评100分，分项100分，默认评语)"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("取消")),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("确定")),
        ],
      ),
    );

    if (confirm != true) return;

    for (var cls in _availableClasses) {
      _submitEvaluation(targetClass: cls);
      // 稍微延迟一下避免并发过高（可选）
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("已发送所有评教请求")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("评教"),
        actions: [
          if (_availableClasses.isNotEmpty)
            IconButton(
              tooltip: "一键评教所有",
              icon: const Icon(Icons.done_all),
              onPressed: _evaluateAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // 顶部操作区
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      _termPopMenuKey.currentState?.showButtonMenu();
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "学期",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_selectedTerm ?? "请选择学期"),
                          PopupMenuButton<String>(
                            key: _termPopMenuKey,
                            icon: const Icon(Icons.arrow_drop_down),
                            onSelected: (value) {
                              setState(() {
                                _selectedTerm = value;
                              });
                              _fetchClasses();
                            },
                            itemBuilder: (context) {
                              if (_terms == null || _terms!.isEmpty) {
                                WeChatTermsOutput.rustSignalStream
                                    .listen((data) {
                                  _terms = data.message.terms;
                                  _termPopMenuKey.currentState
                                      ?.showButtonMenu();
                                });

                                WeChatTermsInput().sendSignalToRust();
                                _terms = [];
                              }

                              return _terms!
                                  .map((t) =>
                                      PopupMenuItem(value: t, child: Text(t)))
                                  .toList();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 信号监听与内容显示
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_availableClasses.isEmpty) {
                  return const Center(child: Text("暂无课程或请先查询"));
                }

                return PaddingScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 课程选择
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child:
                            DropdownButtonFormField<SimplifiedEvaluatableClass>(
                          initialValue: _selectedClass,
                          decoration: const InputDecoration(
                            labelText: "选择课程",
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: _availableClasses.map((e) {
                            return DropdownMenuItem(
                              value: e,
                              child: Text("${e.courseName} - ${e.teacherName}"),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedClass = value;
                            });
                          },
                        ),
                      ),

                      const Divider(height: 32),

                      // 评分区域
                      if (_selectedClass != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("当前评价: ${_selectedClass!.courseName}",
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        ListTile(
                          title: const Text("总评成绩"),
                          trailing: Text("$_overallScore 分"),
                          subtitle: Slider(
                            value: _overallScore.toDouble(),
                            min: 40,
                            max: 100,
                            divisions: 3,
                            label: _overallScore.toString(),
                            onChanged: (v) =>
                                setState(() => _overallScore = v.toInt()),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Text("分项评价"),
                        ),
                        ...List.generate(_subScores.length, (index) {
                          return ListTile(
                            title: Text(_subScoreLabels[index]),
                            trailing: Text("${_subScores[index]} 分"),
                            subtitle: Slider(
                              value: _subScores[index].toDouble(),
                              min: 40,
                              max: 100,
                              divisions: 3,
                              label: _subScores[index].toString(),
                              onChanged: (v) =>
                                  setState(() => _subScores[index] = v.toInt()),
                            ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _commentController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: "评语",
                              hintText: "请输入评语，默认为'老师讲课很好'",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () => _submitEvaluation(),
                              child: const Text("提交评价"),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
