import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/utils/category_icon_utils.dart'
    show expenseIconOptions, getCategoryIcon, incomeIconOptions;
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../providers/admin_providers.dart';

class DefaultCategoriesPage extends ConsumerStatefulWidget {
  final bool autoAdd;
  const DefaultCategoriesPage({super.key, this.autoAdd = false});

  @override
  ConsumerState<DefaultCategoriesPage> createState() =>
      _DefaultCategoriesPageState();
}

class _DefaultCategoriesPageState extends ConsumerState<DefaultCategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.autoAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCategorySheet();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _presetColors = [
    '#4DB6AC', '#26A69A', '#00897B', '#00796B',
    '#EF5350', '#E53935', '#C62828', '#FF7043',
    '#42A5F5', '#1E88E5', '#1565C0', '#5C6BC0',
    '#66BB6A', '#43A047', '#2E7D32', '#8D6E63',
    '#AB47BC', '#8E24AA', '#6A1B9A', '#FFA726',
    '#FFCA28', '#FFB300', '#FF8F00', '#78909C',
  ];

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.brandTeal;
    }
  }

  Future<void> _showColorPicker(
      BuildContext ctx, TextEditingController colorController) async {
    await showDialog<void>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pick a color'),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _presetColors.map((hex) {
              final color = _parseColor(hex);
              return GestureDetector(
                onTap: () {
                  colorController.text = hex;
                  Navigator.of(dialogCtx).pop();
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: color,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCategorySheet({
    Map<String, dynamic>? existing,
  }) async {
    final nameController =
        TextEditingController(text: existing?['name'] ?? '');
    final colorController =
        TextEditingController(text: existing?['color'] ?? '#4DB6AC');
    String selectedType = existing?['type'] ?? 'expense';
    String selectedIconKey = existing?['icon'] ?? 'tag';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSizes.pagePadding,
                right: AppSizes.pagePadding,
                top: AppSizes.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSizes.lg,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          existing == null ? 'Add Category' : 'Edit Category',
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        CircularIconButton(
                          icon: CupertinoIcons.xmark,
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.lg),

                    // Type selector (only on Add)
                    if (existing == null) ...[
                      DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const [
                          DropdownMenuItem(
                              value: 'income', child: Text('Income')),
                          DropdownMenuItem(
                              value: 'expense', child: Text('Expense')),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => selectedType = v!),
                      ),
                      const SizedBox(height: AppSizes.md),
                    ],

                    // Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        hintText: 'e.g. Groceries',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Icon picker
                    Text(
                      'Icon',
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: Theme.of(ctx).hintColor,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (selectedType == 'income'
                              ? incomeIconOptions
                              : expenseIconOptions)
                          .map((opt) {
                        final (key, iconData, label) = opt;
                        final isSelected = selectedIconKey == key;
                        final color = _parseColor(colorController.text);
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedIconKey = key),
                          child: Tooltip(
                            message: label,
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: isSelected
                                  ? color.withValues(alpha: 0.25)
                                  : Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              child: Icon(
                                iconData,
                                size: 20,
                                color: isSelected
                                    ? color
                                    : Theme.of(ctx).hintColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Color with preview
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: colorController,
                            decoration: const InputDecoration(
                              labelText: 'Color (hex)',
                              hintText: '#4DB6AC',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Required';
                              }
                              final clean = v.replaceAll('#', '');
                              if (clean.length != 6) return 'Use #RRGGBB';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: colorController,
                          builder: (_, value, __) => GestureDetector(
                            onTap: () => _showColorPicker(ctx, colorController),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: _parseColor(value.text),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xl),

                    ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => saving = true);
                              try {
                                final ds = ref.read(
                                    adminRemoteDataSourceProvider);
                                if (existing == null) {
                                  await ds.addDefaultCategory(
                                    name: nameController.text.trim(),
                                    type: selectedType,
                                    icon: selectedIconKey,
                                    color: colorController.text.trim(),
                                  );
                                } else {
                                  await ds.updateDefaultCategory(
                                    id: existing['id'] as String,
                                    name: nameController.text.trim(),
                                    icon: selectedIconKey,
                                    color: colorController.text.trim(),
                                  );
                                }
                                ref.invalidate(defaultCategoriesProvider);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                              } catch (e) {
                                setSheetState(() => saving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Error: ${e.toString()}')),
                                  );
                                }
                              }
                            },
                      child: saving
                          ? const LoadingIndicator()
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${category['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.systemRed),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(adminRemoteDataSourceProvider)
          .deleteDefaultCategory(category['id'] as String);
      ref.invalidate(defaultCategoriesProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Widget _buildList(
      List<Map<String, dynamic>> categories, String type) {
    final filtered =
        categories.where((c) => c['type'] == type).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.square_grid_2x2,
                  size: 48,
                  color: AppColors.textSecondary.withValues(alpha: 0.4)),
              const SizedBox(height: AppSizes.md),
              Text(
                'No ${type == 'income' ? 'income' : 'expense'} categories',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.pagePadding, vertical: AppSizes.md),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final cat = filtered[i];
            final color = _parseColor(cat['color'] as String? ?? '#4DB6AC');
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 4),
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  getCategoryIcon(
                    cat['name'] as String?,
                    type: cat['type'] as String?,
                    iconKey: cat['icon'] as String?,
                  ),
                  color: color,
                  size: 18,
                ),
              ),
              title: Text(
                cat['name'] as String,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(radius: 6, backgroundColor: color),
                  const SizedBox(width: AppSizes.sm),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pencil,
                        size: 18, color: AppColors.textSecondary),
                    onPressed: () => _showCategorySheet(existing: cat),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.trash,
                        size: 18, color: AppColors.systemRed),
                    onPressed: () => _confirmDelete(cat),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(defaultCategoriesProvider);

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
        title: const Text('Default Categories'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add, color: AppColors.brandTeal),
            onPressed: () => _showCategorySheet(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income'),
            Tab(text: 'Expense'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load categories',
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: AppSizes.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(defaultCategoriesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categories) => TabBarView(
          controller: _tabController,
          children: [
            _buildList(categories, 'income'),
            _buildList(categories, 'expense'),
          ],
        ),
      ),
    );
  }
}
