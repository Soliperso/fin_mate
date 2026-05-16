import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_date_formats.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../shared/widgets/circular_icon_button.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/entities/admin_user_entity.dart';
import '../providers/admin_providers.dart';

class UserDetailPage extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  // ── Helpers ──────────────────────────────────────────────────────────────

  void _copyEmail(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQuickActions(
      BuildContext context, WidgetRef ref, AdminUserEntity user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.systemGray3,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading:
                _quickActionIcon(CupertinoIcons.lock_fill, AppColors.brandTeal),
            title: const Text('Reset Password',
                style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(ctx);
              _handleResetPassword(context, ref, user);
            },
          ),
          ListTile(
            leading: _quickActionIcon(
              user.isActive
                  ? CupertinoIcons.xmark_circle_fill
                  : CupertinoIcons.checkmark_circle_fill,
              user.isActive ? AppColors.systemRed : AppColors.systemGreen,
            ),
            title: Text(
              user.isActive ? 'Disable Account' : 'Enable Account',
              style: TextStyle(
                color:
                    user.isActive ? AppColors.systemRed : AppColors.systemGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(ctx);
              if (user.isActive) {
                _handleDisableAccount(context, ref, user);
              } else {
                _handleEnableAccount(context, ref, user);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _quickActionIcon(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userDetailsProvider(widget.userId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: userAsync.maybeWhen(
          data: (user) => Text(user.displayName),
          orElse: () => const Text('User Details'),
        ),
        leading: Center(
          child: CircularIconButton(
            icon: CupertinoIcons.chevron_left,
            onTap: () => context.pop(),
          ),
        ),
      ),
      body: userAsync.when(
        data: (user) => _buildBody(context, isDark, user, ref),
        loading: () => _buildSkeleton(context, isDark),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Failed to load user',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(userDetailsProvider(widget.userId)),
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise,
                      size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTeal,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, bool isDark, AdminUserEntity user, WidgetRef ref) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final auditAsync = ref.watch(userAuditLogProvider(user.id));
    const accentColor = AppColors.brandTeal;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                // Gradient banner with overlapping avatar
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 90,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor,
                            accentColor.withValues(alpha: 0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -48,
                      child: GestureDetector(
                        onLongPress: () =>
                            _showQuickActions(context, ref, user),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cardColor,
                              ),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor:
                                    accentColor.withValues(alpha: 0.2),
                                backgroundImage: user.avatarUrl != null &&
                                        user.avatarUrl!.isNotEmpty
                                    ? NetworkImage(user.avatarUrl!)
                                    : null,
                                child: user.avatarUrl == null ||
                                        user.avatarUrl!.isEmpty
                                    ? Text(
                                        user.initials,
                                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: accentColor,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            if (!user.isActive)
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSizes.xs),
                                  decoration: BoxDecoration(
                                    color: AppColors.systemRed,
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: cardColor, width: 2),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.lock_fill,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _showQuickActions(context, ref, user),
                        child: Container(
                          padding: const EdgeInsets.all(AppSizes.xs),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            CupertinoIcons.ellipsis,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 62), // avatar radius 48 + 14 gap
                Text(
                  user.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? AppColors.labelDark : AppColors.label,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                // Tappable email — copies to clipboard
                GestureDetector(
                  onTap: () => _copyEmail(context, user.email),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          user.email,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? AppColors.secondaryLabelDark
                                        : AppColors.secondaryLabel,
                                    fontWeight: FontWeight.w500,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        CupertinoIcons.doc_on_doc,
                        size: 11,
                        color: isDark
                            ? AppColors.tertiaryLabelDark
                            : AppColors.systemGray3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _badge(
                      context,
                      label: user.isAdmin ? 'Admin' : 'User',
                      color: user.isAdmin
                          ? AppColors.brandTeal
                          : AppColors.tealBlue,
                      icon: user.isAdmin
                          ? CupertinoIcons.shield
                          : CupertinoIcons.person,
                    ),
                    _badge(
                      context,
                      label: user.isActive ? 'Active' : 'Inactive',
                      color: user.isActive
                          ? AppColors.systemGreen
                          : AppColors.systemRed,
                      icon: user.isActive
                          ? CupertinoIcons.checkmark_circle_fill
                          : CupertinoIcons.xmark_circle_fill,
                    ),
                    _badge(
                      context,
                      label: 'Verified',
                      color: AppColors.systemGreen,
                      icon: CupertinoIcons.checkmark_seal_fill,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Financial Overview ───────────────────────────────────────────
          _buildSectionHeader(context, 'Financial Overview',
              icon: CupertinoIcons.money_dollar),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(
                color: isDark
                    ? AppColors.separatorDark.withValues(alpha: 0.4)
                    : AppColors.separator.withValues(alpha: 0.25),
                width: 0.7,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: AppColors.brandTeal,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Net Worth',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.secondaryLabel,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.netWorth),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        color: user.netWorth < 0
                            ? AppColors.systemRed
                            : user.netWorth > 0
                                ? AppColors.systemGreen
                                : AppColors.brandTeal,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Financial health bar — income vs expense proportion
          _buildHealthBar(context, isDark, user),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_up_circle_fill,
                  iconColor: AppColors.systemGreen,
                  label: 'Total Income',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalIncome),
                  valueColor: AppColors.systemGreen,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _statCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.arrow_down_circle_fill,
                  iconColor: AppColors.systemRed,
                  label: 'Total Expenses',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalExpense),
                  valueColor: AppColors.systemRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          _buildCashFlowCard(context, isDark, user),
          const SizedBox(height: 24),

          // ── Account Details ──────────────────────────────────────────────
          _buildSectionHeader(context, 'Account Details',
              icon: CupertinoIcons.person_fill),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
              border: Border.all(
                color: isDark
                    ? AppColors.separatorDark.withValues(alpha: 0.5)
                    : AppColors.separator.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: [
                _infoRow(context, isDark,
                    icon: CupertinoIcons.calendar,
                    iconColor: AppColors.tealBlue,
                    label: 'Joined',
                    value: DateFormat(AppDateFormats.mediumDate).format(user.createdAt)),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.doc_text,
                    iconColor: AppColors.brandTeal,
                    label: 'Transactions',
                    value: user.transactionCount.toString()),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.clock_fill,
                    iconColor: AppColors.brandTeal,
                    label: 'Last Active',
                    value: _formatLastActive(user.lastActive)),
                _divider(context),
                _infoRow(context, isDark,
                    icon: CupertinoIcons.hourglass,
                    iconColor: AppColors.tealBlue,
                    label: 'Member Since',
                    value: _formatJoinDate(user.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent Activity ──────────────────────────────────────────────
          _buildSectionHeader(context, 'Recent Activity',
              icon: CupertinoIcons.clock),
          const SizedBox(height: 12),
          _buildActivityTimeline(context, isDark, cardColor, auditAsync),
          const SizedBox(height: 24),

          // ── Usage Insights ────────────────────────────────────────────────
          _buildSectionHeader(context, 'Usage Insights',
              icon: CupertinoIcons.chart_bar),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.doc_text_fill,
                  iconColor: AppColors.brandTeal,
                  label: 'Avg Monthly Spend',
                  value: NumberFormat.compactCurrency(symbol: '\$')
                      .format(user.totalExpense / _monthsSince(user.createdAt)),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _insightCard(
                  context,
                  isDark: isDark,
                  icon: CupertinoIcons.percent,
                  iconColor: AppColors.systemGreen,
                  label: 'Savings Rate',
                  value: _calculateSavingsRate(user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Admin Actions ────────────────────────────────────────────────
          _buildSectionHeader(context, 'Admin Actions',
              icon: CupertinoIcons.shield_fill),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  icon: CupertinoIcons.lock,
                  label: 'Reset Password',
                  color: AppColors.brandTeal,
                  onTap: () => _handleResetPassword(context, ref, user),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _actionButton(
                  context,
                  icon: CupertinoIcons.doc_text,
                  label: 'View Audit Log',
                  color: AppColors.brandTeal,
                  onTap: () => _handleViewAuditLog(context, ref, user),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Section widgets ───────────────────────────────────────────────────────

  Widget _buildHealthBar(
      BuildContext context, bool isDark, AdminUserEntity user) {
    final total = user.totalIncome + user.totalExpense;
    final incomeRatio = total > 0 ? (user.totalIncome / total) : 0.5;
    final incomeFlex = (incomeRatio * 100).round().clamp(1, 99);
    final expenseFlex = (100 - incomeFlex).clamp(1, 99);
    final fmt = NumberFormat.compactCurrency(symbol: '\$');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 5,
            child: Row(
              children: [
                Expanded(
                  flex: incomeFlex,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.systemGreen, AppColors.systemMint],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: expenseFlex,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.systemRed, AppColors.systemOrange],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.systemGreen,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Income ${fmt.format(user.totalIncome)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
            const Spacer(),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.systemRed,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Expenses ${fmt.format(user.totalExpense)}',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashFlowCard(
      BuildContext context, bool isDark, AdminUserEntity user) {
    final cashFlow = user.totalIncome - user.totalExpense;
    final isPositive = cashFlow >= 0;
    final color = isPositive ? AppColors.systemGreen : AppColors.systemRed;
    final fmt = NumberFormat.compactCurrency(symbol: '\$');
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isPositive
                  ? CupertinoIcons.arrow_up_right
                  : CupertinoIcons.arrow_down_right,
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Net Cash Flow',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${fmt.format(cashFlow)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(
    BuildContext context,
    bool isDark,
    Color cardColor,
    AsyncValue<List<Map<String, dynamic>>> auditAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.5)
              : AppColors.separator.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: auditAsync.when(
        loading: () => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        LoadingSkeleton(
                          width: 10,
                          height: 10,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        if (i < 2)
                          Container(
                            width: 2,
                            height: 28,
                            margin: const EdgeInsets.only(top: 4),
                            color: isDark
                                ? AppColors.separatorDark
                                : AppColors.separator,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LoadingSkeleton(
                            height: 12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          LoadingSkeleton(
                            width: 90,
                            height: 10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
          child: Row(
            children: [
              const Icon(CupertinoIcons.exclamationmark_circle,
                  size: 16, color: AppColors.systemRed),
              const SizedBox(width: 8),
              Text(
                'Could not load activity',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                    ),
              ),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 16,
                    color: isDark
                        ? AppColors.tertiaryLabelDark
                        : AppColors.systemGray3,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No activity recorded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.secondaryLabelDark
                              : AppColors.secondaryLabel,
                        ),
                  ),
                ],
              ),
            );
          }
          final grouped = _groupByDay(entries);
          final dayLabels = grouped.keys.toList();
          return Column(
            children: [
              for (int gi = 0; gi < dayLabels.length; gi++) ...[
                if (gi > 0)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark
                        ? AppColors.separatorDark.withValues(alpha: 0.4)
                        : AppColors.separator.withValues(alpha: 0.3),
                  ),
                _ActivityDayGroup(
                  label: dayLabels[gi],
                  entries: grouped[dayLabels[gi]]!,
                  isFirst: gi == 0,
                  isDark: isDark,
                  rowBuilder: (entry, isLast) =>
                      _timelineRow(context, isDark, entry, isLast: isLast),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Map<String, List<Map<String, dynamic>>> _groupByDay(
      List<Map<String, dynamic>> entries) {
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in entries) {
      final rawDate = entry['created_at'] as String?;
      if (rawDate == null) continue;
      DateTime dt;
      try {
        dt = DateTime.parse(rawDate).toLocal();
      } catch (_) {
        continue;
      }
      final day = DateUtils.dateOnly(dt);
      final String label;
      if (day == today) {
        label = 'Today';
      } else if (day == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat(AppDateFormats.mediumDate).format(dt);
      }
      result.putIfAbsent(label, () => []).add(entry);
    }
    return result;
  }

  static String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Never';
    final local = lastActive.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(local);
    final timeStr = DateFormat(AppDateFormats.timeOnly).format(local);
    if (day == today) return 'Today, $timeStr';
    if (day == today.subtract(const Duration(days: 1)))
      return 'Yesterday, $timeStr';
    final diff = today.difference(day).inDays;
    if (diff < 7) return '$diff days ago';
    return DateFormat(AppDateFormats.mediumDate).format(local);
  }

  static String _formatJoinDate(DateTime createdAt) =>
      DateFormat(AppDateFormats.mediumDate).format(createdAt.toLocal());

  static double _monthsSince(DateTime date) {
    final now = DateTime.now();
    final months = (now.year - date.year) * 12 + (now.month - date.month);
    return months < 1 ? 1.0 : months.toDouble();
  }

  static String _formatAction(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _timelineRow(
    BuildContext context,
    bool isDark,
    Map<String, dynamic> entry, {
    bool isLast = false,
    String? subtitle,
  }) {
    final raw = entry['action'] as String? ?? 'unknown_action';
    final action = _formatAction(raw);
    final rawDate = entry['created_at'] as String?;
    String formattedDate = '';
    String formattedTime = '';
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate).toLocal();
        formattedDate = DateFormat(AppDateFormats.mediumDate).format(dt);
        formattedTime = DateFormat(AppDateFormats.timeOnly).format(dt);
      } catch (_) {
        formattedDate = rawDate;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator: dot + connector line
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brandTeal,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.only(top: AppSizes.xs),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandTeal.withValues(alpha: 0.25),
                          AppColors.brandTeal.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 4 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          action,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.labelDark
                                        : AppColors.label,
                                  ),
                        ),
                      ),
                      if (formattedTime.isNotEmpty)
                        Text(
                          formattedTime,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.brandTeal,
                          ),
                        ),
                    ],
                  ),
                  if (formattedDate.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isDark
                                ? AppColors.secondaryLabelDark
                                : AppColors.secondaryLabel,
                          ),
                    ),
                  ],
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark
                                ? AppColors.tertiaryLabelDark
                                : AppColors.systemGray3,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared sub-widgets ───────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context, String title,
      {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.brandTeal,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.brandTeal),
          const SizedBox(width: AppSizes.xs),
        ],
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.labelDark : AppColors.label,
                ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md,
          horizontal: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        ),
        child: isFullWidth
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                  ),
                ],
              ),
      ),
    );
  }

  String _calculateSavingsRate(AdminUserEntity user) {
    if (user.totalIncome == 0) return '0%';
    final rate =
        ((user.totalIncome - user.totalExpense) / user.totalIncome * 100)
            .toStringAsFixed(1);
    return '$rate%';
  }

  // ── Action handlers (unchanged) ──────────────────────────────────────────

  Future<void> _handleResetPassword(
      BuildContext context, WidgetRef ref, AdminUserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send a password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.brandTeal),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Sending password reset email…'),
          duration: Duration(seconds: 1)),
    );
    try {
      await ref.read(resetUserPasswordProvider(user.email).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${user.email}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleViewAuditLog(
      BuildContext context, WidgetRef ref, AdminUserEntity user) async {
    final auditAsync = ref.read(userAuditLogProvider(user.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return auditAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text('Could not load audit log',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel,
                    )),
              ),
              data: (entries) {
                final grouped = _groupByDay(entries);
                final dayLabels = grouped.keys.toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: AppSizes.sm, bottom: AppSizes.sm),
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.separatorDark
                              : AppColors.separator,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.xs, AppSizes.md, AppSizes.sm),
                      child: Row(
                        children: [
                          Text(
                            'Audit Log',
                            style:
                                Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                      color: isDark
                                          ? AppColors.labelDark
                                          : AppColors.label,
                                    ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entries.length} events',
                            style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: isDark
                          ? AppColors.separatorDark.withValues(alpha: 0.5)
                          : AppColors.separator.withValues(alpha: 0.4),
                    ),
                    // Grouped list
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                'No activity recorded',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.secondaryLabelDark
                                      : AppColors.secondaryLabel,
                                ),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollController,
                              itemCount: dayLabels.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 0.5,
                                color: isDark
                                    ? AppColors.separatorDark
                                        .withValues(alpha: 0.4)
                                    : AppColors.separator
                                        .withValues(alpha: 0.3),
                              ),
                              itemBuilder: (ctx, gi) {
                                final label = dayLabels[gi];
                                final dayEntries = grouped[label]!;
                                return _ActivityDayGroup(
                                  label: label,
                                  entries: dayEntries,
                                  isFirst: gi == 0,
                                  isDark: isDark,
                                  rowBuilder: (entry, isLast) {
                                    final screen =
                                        entry['screen_name'] as String?;
                                    final formattedScreen =
                                        screen != null && screen.isNotEmpty
                                            ? _formatAction(screen)
                                            : null;
                                    return _timelineRow(
                                      ctx,
                                      isDark,
                                      entry,
                                      isLast: isLast,
                                      subtitle: formattedScreen,
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleDisableAccount(
      BuildContext context, WidgetRef ref, AdminUserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Account'),
        content: Text(
            'Are you sure you want to disable ${user.displayName}\'s account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.systemRed),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Disabling account…'), duration: Duration(seconds: 1)),
    );
    try {
      await ref.read(disableUserAccountProvider(user.id).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName}\'s account has been disabled'),
          duration: const Duration(seconds: 3),
        ),
      );
      // ignore: unused_result
      ref.refresh(userDetailsProvider(user.id));
      ref.invalidate(usersListProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleEnableAccount(
      BuildContext context, WidgetRef ref, AdminUserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Account'),
        content: Text(
            'Are you sure you want to enable ${user.displayName}\'s account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.systemGreen),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Enabling account…'), duration: Duration(seconds: 1)),
    );
    try {
      await ref.read(enableUserAccountProvider(user.id).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.displayName}\'s account has been enabled'),
          duration: const Duration(seconds: 3),
        ),
      );
      // ignore: unused_result
      ref.refresh(userDetailsProvider(user.id));
      ref.invalidate(usersListProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Reusable row/card widgets ────────────────────────────────────────────

  Widget _badge(BuildContext context,
      {required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.5, color: color),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, bool isDark,
      {required IconData icon,
      required Color iconColor,
      required String label,
      required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.labelDark : AppColors.label,
                  letterSpacing: -0.3,
                ),
          ),
        ],
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(
      height: 0,
      thickness: 0.5,
      indent: AppSizes.md + 32 + AppSizes.md,
      endIndent: AppSizes.md,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _statCard(BuildContext context,
      {required bool isDark,
      required IconData icon,
      required Color iconColor,
      required String label,
      required String value,
      Color? valueColor,
      Gradient? gradient}) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    final hasGradient = gradient != null;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: hasGradient ? null : cardColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: hasGradient
            ? null
            : Border.all(
                color: isDark
                    ? AppColors.separatorDark.withValues(alpha: 0.4)
                    : AppColors.separator.withValues(alpha: 0.25),
                width: 0.7,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: hasGradient
                  ? Colors.white.withValues(alpha: 0.22)
                  : iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              icon,
              color: hasGradient ? Colors.white : iconColor,
              size: 16.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasGradient
                      ? Colors.white.withValues(alpha: 0.80)
                      : (isDark
                          ? AppColors.secondaryLabelDark
                          : AppColors.secondaryLabel),
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: hasGradient
                      ? Colors.white
                      : (valueColor ??
                          (isDark ? AppColors.labelDark : AppColors.label)),
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _insightCard(BuildContext context,
      {required bool isDark,
      required IconData icon,
      required Color iconColor,
      required String label,
      required String value}) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        border: Border.all(
          color: isDark
              ? AppColors.separatorDark.withValues(alpha: 0.4)
              : AppColors.separator.withValues(alpha: 0.25),
          width: 0.7,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.secondaryLabelDark
                      : AppColors.secondaryLabel,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: iconColor,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Loading skeleton ─────────────────────────────────────────────────────

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    final cardColor = isDark
        ? AppColors.secondarySystemBackgroundDark
        : AppColors.systemBackground;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.lg),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard),
            ),
            child: Column(
              children: [
                LoadingSkeleton(
                    width: 84,
                    height: 84,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull)),
                const SizedBox(height: AppSizes.md),
                LoadingSkeleton(
                    width: 135,
                    height: 14,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 6),
                LoadingSkeleton(
                    width: 180,
                    height: 10,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 6),
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                    const SizedBox(width: 6),
                    LoadingSkeleton(
                        width: 60,
                        height: 21,
                        borderRadius: BorderRadius.circular(10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          LoadingSkeleton(
              width: 90, height: 11, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          LoadingSkeleton(
              height: 95,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: AppSizes.sm),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: 24),
          LoadingSkeleton(
              width: 90, height: 11, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          LoadingSkeleton(
              height: 135,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
          const SizedBox(height: 24),
          LoadingSkeleton(
              width: 90, height: 11, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 95,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: 24),
          LoadingSkeleton(
              width: 90, height: 11, borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: LoadingSkeleton(
                    height: 81,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
            const SizedBox(width: AppSizes.sm),
            Expanded(
                child: LoadingSkeleton(
                    height: 81,
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard))),
          ]),
          const SizedBox(height: AppSizes.sm),
          LoadingSkeleton(
              height: 42,
              borderRadius: BorderRadius.circular(AppSizes.radiusCard)),
        ],
      ),
    );
  }
}

class _ActivityDayGroup extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> entries;
  final bool isFirst;
  final bool isDark;
  final Widget Function(Map<String, dynamic> entry, bool isLast) rowBuilder;

  const _ActivityDayGroup({
    required this.label,
    required this.entries,
    required this.isFirst,
    required this.isDark,
    required this.rowBuilder,
  });

  @override
  State<_ActivityDayGroup> createState() => _ActivityDayGroupState();
}

class _ActivityDayGroupState extends State<_ActivityDayGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final count = widget.entries.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.secondaryLabelDark
                            : AppColors.secondaryLabel,
                      ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _expanded ? 0.0 : 1.0,
                  child: Text(
                    '$count ${count == 1 ? 'event' : 'events'}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.brandTeal,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    CupertinoIcons.chevron_right,
                    size: 12,
                    color: isDark
                        ? AppColors.secondaryLabelDark
                        : AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState:
              _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              children: [
                for (int i = 0; i < widget.entries.length; i++)
                  widget.rowBuilder(
                    widget.entries[i],
                    i == widget.entries.length - 1,
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
