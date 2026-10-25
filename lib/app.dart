import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/notes/notes_page.dart';
import 'features/settings/settings_page.dart';
import 'features/summary/summary_page.dart';
import 'features/today/today_page.dart';
import 'state/app_state.dart';
import 'theme.dart';

class YanShiApp extends StatelessWidget {
  final AppState state;

  const YanShiApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        title: '研时',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: const RootShell(),
      ),
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    (label: '今日', icon: Icons.schedule_outlined, active: Icons.schedule),
    (label: '汇总', icon: Icons.bar_chart_outlined, active: Icons.bar_chart),
    (label: '笔记', icon: Icons.description_outlined, active: Icons.description),
    (label: '设置', icon: Icons.tune_outlined, active: Icons.tune),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayPage(),
          SummaryPage(),
          NotesPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg(context),
          border: Border(top: BorderSide(color: lineColor(context))),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _index == i ? _tabs[i].active : _tabs[i].icon,
                          size: 21,
                          color: _index == i
                              ? Theme.of(context).colorScheme.primary
                              : subColor(context),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _tabs[i].label,
                          style: TextStyle(
                            fontSize: 10,
                            color: _index == i
                                ? Theme.of(context).colorScheme.primary
                                : subColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
