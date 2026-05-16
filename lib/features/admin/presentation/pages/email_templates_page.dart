import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/admin_providers.dart';

(IconData, Color) _templateMeta(String key) {
  switch (key) {
    case 'welcome':
      return (CupertinoIcons.person_crop_circle, AppColors.brandTeal);
    case 'password_reset':
      return (CupertinoIcons.lock, AppColors.systemOrange);
    case 'budget_alert':
      return (CupertinoIcons.exclamationmark_circle, AppColors.systemRed);
    case 'goal_achieved':
      return (CupertinoIcons.checkmark_circle, AppColors.systemBlue);
    case 'recurring_reminder':
      return (CupertinoIcons.repeat, AppColors.tealBlue);
    default:
      return (CupertinoIcons.envelope, AppColors.textSecondary);
  }
}

class EmailTemplatesPage extends ConsumerStatefulWidget {
  const EmailTemplatesPage({super.key});

  @override
  ConsumerState<EmailTemplatesPage> createState() => _EmailTemplatesPageState();
}

class _EmailTemplatesPageState extends ConsumerState<EmailTemplatesPage> {
  // Optimistic toggle state: template id → enabled
  final Map<String, bool> _pending = {};

  Future<void> _toggle(Map<String, dynamic> template, bool newValue) async {
    final id = template['id'] as String;
    setState(() => _pending[id] = newValue);
    try {
      await ref.read(adminRemoteDataSourceProvider).updateEmailTemplate(
            id: id,
            subject: template['subject'] as String,
            body: template['body'] as String,
            isEnabled: newValue,
          );
      ref.invalidate(emailTemplatesProvider);
    } catch (_) {
      if (mounted) {
        setState(() => _pending.remove(id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update template. Please try again.')),
        );
      }
    }
  }

  Future<void> _showEditor(Map<String, dynamic> template) async {
    final subjectCtrl =
        TextEditingController(text: template['subject'] as String);
    final bodyCtrl = TextEditingController(text: template['body'] as String);
    final formKey = GlobalKey<FormState>();

    final variables = ((template['variables'] as List<dynamic>?) ?? [])
        .cast<Map<String, dynamic>>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (ctx) => _EditorSheet(
        template: template,
        subjectCtrl: subjectCtrl,
        bodyCtrl: bodyCtrl,
        formKey: formKey,
        variables: variables,
        currentEnabled: _pending[template['id'] as String] ??
            template['is_enabled'] as bool,
        onSave: (subject, body) async {
          await ref.read(adminRemoteDataSourceProvider).updateEmailTemplate(
                id: template['id'] as String,
                subject: subject,
                body: body,
                isEnabled: _pending[template['id'] as String] ??
                    template['is_enabled'] as bool,
              );
          ref.invalidate(emailTemplatesProvider);
        },
      ),
    );

    subjectCtrl.dispose();
    bodyCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final templatesAsync = ref.watch(emailTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
        title: const Text('Email Templates'),
      ),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load templates',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(emailTemplatesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.envelope,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'No email templates found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          final cardColor = isDark
              ? AppColors.secondarySystemBackgroundDark
              : AppColors.systemBackground;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: AppSizes.sm + 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandTeal.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.info_circle,
                          size: 15, color: AppColors.brandTeal),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          'Tap a template to edit its subject and body. Use {{variable}} for dynamic content.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.brandTeal,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // Templates card
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (int i = 0; i < templates.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _TemplateTile(
                          template: templates[i],
                          isDark: isDark,
                          isEnabled: _pending[templates[i]['id'] as String] ??
                              templates[i]['is_enabled'] as bool,
                          onToggle: (v) => _toggle(templates[i], v),
                          onTap: () => _showEditor(templates[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final Map<String, dynamic> template;
  final bool isDark;
  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  const _TemplateTile({
    required this.template,
    required this.isDark,
    required this.isEnabled,
    required this.onToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final key = template['key'] as String;
    final (icon, color) = _templateMeta(key);
    final updatedAt = template['updated_at'] as String?;
    String? formattedDate;
    if (updatedAt != null) {
      try {
        formattedDate = DateFormat(AppDateFormats.mediumDate)
            .format(DateTime.parse(updatedAt).toLocal());
      } catch (_) {}
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
        child: Row(
          children: [
            // Icon container
            Container(
              width: AppSizes.iconContainer,
              height: AppSizes.iconContainer,
              decoration: BoxDecoration(
                color: (isEnabled ? color : AppColors.textSecondary)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              child: Icon(
                icon,
                size: AppSizes.iconSm,
                color: isEnabled ? color : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSizes.md),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['name'] as String,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: isEnabled
                              ? null
                              : AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template['description'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                        ),
                  ),
                  if (formattedDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Updated $formattedDate',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.tertiaryLabelDark
                                : AppColors.systemGray3,
                            fontSize: 10,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            // Toggle + chevron
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.75,
                  child: Switch(
                    value: isEnabled,
                    onChanged: onToggle,
                    activeThumbColor: AppColors.brandTeal,
                    activeTrackColor: AppColors.brandTeal.withValues(alpha: 0.5),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: isDark
                      ? AppColors.tertiaryLabelDark
                      : AppColors.systemGray3,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorSheet extends StatefulWidget {
  final Map<String, dynamic> template;
  final TextEditingController subjectCtrl;
  final TextEditingController bodyCtrl;
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> variables;
  final bool currentEnabled;
  final Future<void> Function(String subject, String body) onSave;

  const _EditorSheet({
    required this.template,
    required this.subjectCtrl,
    required this.bodyCtrl,
    required this.formKey,
    required this.variables,
    required this.currentEnabled,
    required this.onSave,
  });

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  bool _saving = false;
  final FocusNode _subjectFocus = FocusNode();
  final FocusNode _bodyFocus = FocusNode();

  @override
  void dispose() {
    _subjectFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _insertVariable(String varKey) {
    final tag = '{{$varKey}}';
    final bodyHasFocus = _bodyFocus.hasFocus;
    final ctrl = bodyHasFocus ? widget.bodyCtrl : widget.subjectCtrl;
    final selection = ctrl.selection;
    final text = ctrl.text;
    if (selection.isValid) {
      final newText = text.replaceRange(
          selection.start, selection.end, tag);
      ctrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.start + tag.length),
      );
    } else {
      ctrl.text = text + tag;
      ctrl.selection =
          TextSelection.collapsed(offset: ctrl.text.length);
    }
  }

  Future<void> _save() async {
    if (!widget.formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        widget.subjectCtrl.text.trim(),
        widget.bodyCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = widget.template['key'] as String;
    final (icon, iconColor) = _templateMeta(key);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.pagePadding,
        right: AppSizes.pagePadding,
        top: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    widget.template['name'] as String,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                CircularIconButton(
                  icon: CupertinoIcons.xmark,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              widget.template['description'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Subject
            TextFormField(
              controller: widget.subjectCtrl,
              focusNode: _subjectFocus,
              decoration: const InputDecoration(labelText: 'Subject'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSizes.md),

            // Body
            TextFormField(
              controller: widget.bodyCtrl,
              focusNode: _bodyFocus,
              decoration: const InputDecoration(
                labelText: 'Body',
                alignLabelWithHint: true,
              ),
              maxLines: 7,
              minLines: 5,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            // Variables
            if (widget.variables.isNotEmpty) ...[
              const SizedBox(height: AppSizes.md),
              Row(
                children: [
                  Text(
                    'INSERT VARIABLE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Tooltip(
                    message:
                        'Tap a chip to insert it at the cursor in the focused field',
                    child: Icon(CupertinoIcons.info_circle,
                        size: 13,
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xs),
              Wrap(
                spacing: AppSizes.xs,
                runSpacing: AppSizes.xs,
                children: widget.variables.map((v) {
                  final varKey = v['key'] as String;
                  return Tooltip(
                    message: v['description'] as String? ?? varKey,
                    child: ActionChip(
                      label: Text(
                        '{{$varKey}}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.labelDark
                              : AppColors.label,
                        ),
                      ),
                      onPressed: () => _insertVariable(varKey),
                      side: BorderSide(
                        color: isDark
                            ? AppColors.separatorDark
                            : AppColors.separator,
                      ),
                      backgroundColor: isDark
                          ? AppColors.tertiarySystemBackgroundDark
                          : AppColors.systemBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: AppSizes.xl),

            // Copy raw button + Save
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: widget.bodyCtrl.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Body copied to clipboard')),
                    );
                  },
                  icon: const Icon(CupertinoIcons.doc_on_doc, size: 14),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const LoadingIndicator()
                        : const Text('Save Template'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
