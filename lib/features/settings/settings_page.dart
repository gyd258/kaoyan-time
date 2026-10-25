import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/backup.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'subject_manage_page.dart';
import 'task_manage_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final days = state.examDaysLeft;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Text('设置',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor(context))),
                const Spacer(),
                Text('1.0.0', style: TextStyle(fontSize: 12, color: subColor(context))),
              ],
            ),
          ),
          _group(context, '备考', [
            _row(
              context,
              icon: '考',
              title: '考试日期',
              value: state.examDate == null || state.examDate!.isEmpty
                  ? '未设置'
                  : state.examDate,
              onTap: () => _pickExamDate(context, state),
            ),
            _row(
              context,
              icon: '余',
              title: '剩余天数',
              value: days == null ? '—' : '$days 天',
            ),
          ]),
          _group(context, '科目与任务', [
            _row(
              context,
              icon: '科',
              title: '科目管理',
              value: '${state.subjects.length} 个',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SubjectManagePage()),
              ),
            ),
            _row(
              context,
              icon: '任',
              title: '任务管理',
              value: '${state.allTasks.length} 个',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskManagePage()),
              ),
            ),
          ]),
          _group(context, '数据', [
            _row(
              context,
              icon: '表',
              title: '导出 CSV',
              value: 'Excel 可开',
              onTap: () => _exportCsv(context, state),
            ),
            _row(
              context,
              icon: '备',
              title: '导出 JSON 备份',
              onTap: () => _exportJson(context, state),
            ),
            _row(
              context,
              icon: '入',
              title: '导入 JSON 备份',
              onTap: () => _importJson(context, state),
            ),
            _row(
              context,
              icon: '清',
              title: '清空全部数据',
              danger: true,
              onTap: () => _clearAll(context, state),
            ),
          ]),
          _group(context, '外观', [
            _row(context, icon: '色', title: '主题', value: '跟随系统'),
          ]),
          const SizedBox(height: 18),
          Center(
            child: Text(
              '数据仅保存在本机，清理应用数据前请先导出备份',
              style: TextStyle(fontSize: 10, color: subColor(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(title, style: TextStyle(fontSize: 11, color: subColor(context))),
          ),
          Container(
            decoration: BoxDecoration(
              color: cardBg(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  Container(
                    decoration: BoxDecoration(
                      border: i == rows.length - 1
                          ? null
                          : Border(bottom: BorderSide(color: lineColor(context))),
                    ),
                    child: rows[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String icon,
    required String title,
    String? value,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: danger ? AppColors.red.withValues(alpha: 0.12) : mintBg(context),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                icon,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: danger ? AppColors.red : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: danger ? AppColors.red : textColor(context),
              ),
            ),
            const Spacer(),
            if (value != null)
              Text(value, style: TextStyle(fontSize: 12, color: subColor(context))),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.chevron_right, size: 16, color: subColor(context)),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickExamDate(BuildContext context, AppState state) async {
    final now = DateTime.now();
    final initial =
        state.examDate != null && state.examDate!.isNotEmpty ? parseDay(state.examDate!) : DateTime(now.year, 12, 20);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035, 12, 31),
      helpText: '选择考试日期',
    );
    if (picked != null) await state.setExamDate(picked);
  }

  Future<void> _exportCsv(BuildContext context, AppState state) async {
    try {
      final csv = await state.exportCsv();
      final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存 CSV',
        fileName: 'yanshi_entries_${timestampName(DateTime.now())}.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
      if (path != null && context.mounted) showToast(context, '已导出 CSV');
    } catch (e) {
      if (context.mounted) showToast(context, '导出失败：$e');
    }
  }

  Future<void> _exportJson(BuildContext context, AppState state) async {
    try {
      final json = await state.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(json));
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存备份',
        fileName: 'yanshi_backup_${timestampName(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );
      if (path != null && context.mounted) showToast(context, '已导出备份');
    } catch (e) {
      if (context.mounted) showToast(context, '导出失败：$e');
    }
  }

  Future<void> _importJson(BuildContext context, AppState state) async {
    final ok = await confirmAction(
      context,
      title: '导入备份？',
      message: '导入会覆盖当前全部数据。建议先导出一次备份。',
      confirmText: '继续导入',
      danger: true,
    );
    if (!ok) return;
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final bytes = res.files.single.bytes;
      if (bytes == null) {
        if (context.mounted) showToast(context, '读取文件失败');
        return;
      }
      await state.importJson(utf8.decode(bytes));
      if (context.mounted) showToast(context, '导入完成');
    } on FormatException catch (e) {
      if (context.mounted) showToast(context, e.message);
    } catch (e) {
      if (context.mounted) showToast(context, '导入失败：$e');
    }
  }

  Future<void> _clearAll(BuildContext context, AppState state) async {
    final ok = await confirmAction(
      context,
      title: '清空全部数据？',
      message: '科目、任务、时间记录、笔记和设置都会删除，且无法恢复。',
      confirmText: '全部清空',
      danger: true,
    );
    if (!ok) return;
    await state.clearAll();
    if (context.mounted) showToast(context, '已清空');
  }
}
