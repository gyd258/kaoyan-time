import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _finish(AppState state) async {
    final ok = await confirmAction(
      context,
      title: '结束并保存？',
      message: '将按已计时长生成一条记录。',
      confirmText: '结束',
    );
    if (!ok) return;
    await state.finishTimer();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.timer;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('计时中',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor(context))),
        iconTheme: IconThemeData(color: textColor(context)),
      ),
      body: t == null
          ? const Center(child: EmptyState(text: '当前没有进行中的计时'))
          : Builder(
              builder: (context) {
                final subject = state.subjectById(t.subjectId ?? -1);
                final task = state.taskById(t.taskId);
                final name = [
                  if (subject != null) subject.name,
                  if (task != null) task.name,
                ].join(' · ');
                final elapsed = t.elapsedMs();
                final progress = (elapsed % 3600000) / 3600000;

                return Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 250,
                            height: 250,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor:
                                  isDark(context) ? const Color(0xFF1F2A24) : const Color(0xFFE6F2EA),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                fmtTimer(elapsed),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                  color: textColor(context),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                name.isEmpty ? '未选择科目' : name,
                                style: TextStyle(fontSize: 13, color: subColor(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () =>
                                    t.running ? state.pauseTimer() : state.resumeTimer(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor(context),
                                  side: BorderSide(color: lineColor(context)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(t.running ? '暂停' : '继续',
                                    style: const TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 48,
                              child: FilledButton(
                                onPressed: () => _finish(state),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('结束并保存',
                                    style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '锁屏或切到别的应用也会继续计时',
                      style: TextStyle(fontSize: 11, color: subColor(context)),
                    ),
                    const Spacer(flex: 2),
                  ],
                );
              },
            ),
    );
  }
}
