import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/receipt_ocr_service.dart';
import '../../domain/entities/receipt_data.dart';

enum _ScanState { idle, scanning, review }

class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

class _ScanReceiptPageState extends State<ScanReceiptPage>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  final _ocrService = ReceiptOcrService();

  _ScanState _state = _ScanState.idle;
  File? _imageFile;
  ReceiptData? _result;
  double _progress = 0.0;
  String? _errorMessage;
  bool _aiParsed = false;

  // Editable controllers for review screen
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _subtotalCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _tipCtrl = TextEditingController();
  DateTime? _reviewDate;

  late AnimationController _scanLineController;
  late Animation<double> _scanLineAnimation;

  static const _scanGreen = Color(0xFF00FF9F);

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanLineAnimation = CurvedAnimation(
      parent: _scanLineController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _ocrService.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _subtotalCtrl.dispose();
    _taxCtrl.dispose();
    _tipCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;
      setState(() {
        _imageFile = File(picked.path);
        _state = _ScanState.scanning;
        _progress = 0.0;
        _errorMessage = null;
      });
      await _runOcr();
    } catch (_) {
      setState(() {
        _errorMessage = 'Could not access camera or gallery.';
        _state = _ScanState.idle;
      });
    }
  }

  Future<void> _runOcr() async {
    _simulateProgress();
    try {
      // Enforce a minimum visible scanning duration so the animation is seen
      final results = await Future.wait([
        _ocrService.processReceipt(_imageFile!.path),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);
      if (!mounted) return;
      final data = results[0] as Map<String, dynamic>;
      setState(() {
        _aiParsed = (data['aiParsed'] as bool?) ?? false;
        _result = ReceiptData(
          fullText: data['text'] as String,
          amount: data['amount'] as double,
          subtotal: (data['subtotal'] as double?) ?? 0.0,
          tax: (data['tax'] as double?) ?? 0.0,
          tip: (data['tip'] as double?) ?? 0.0,
          merchant: data['merchant'] as String,
          date: data['date'] as DateTime,
          items: List<String>.from(data['items'] as List),
        );
        // Populate editable controllers
        _merchantCtrl.text = _result!.merchant;
        _amountCtrl.text = _result!.amount > 0
            ? _result!.amount.toStringAsFixed(2)
            : '';
        _subtotalCtrl.text = _result!.subtotal > 0
            ? _result!.subtotal.toStringAsFixed(2)
            : '';
        _taxCtrl.text =
            _result!.tax > 0 ? _result!.tax.toStringAsFixed(2) : '';
        _tipCtrl.text =
            _result!.tip > 0 ? _result!.tip.toStringAsFixed(2) : '';
        _reviewDate = _result!.date;
        _progress = 1.0;
        _state = _ScanState.review;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not read this receipt. Try a clearer photo.';
        _state = _ScanState.idle;
      });
    }
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || _state != _ScanState.scanning) return false;
      setState(() => _progress = (_progress + 0.04).clamp(0.0, 0.92));
      return _state == _ScanState.scanning && _progress < 0.92;
    });
  }

  void _confirm() {
    final confirmed = ReceiptData(
      fullText: _result!.fullText,
      merchant: _merchantCtrl.text.trim().isNotEmpty
          ? _merchantCtrl.text.trim()
          : _result!.merchant,
      amount: double.tryParse(_amountCtrl.text) ?? _result!.amount,
      subtotal: double.tryParse(_subtotalCtrl.text) ?? _result!.subtotal,
      tax: double.tryParse(_taxCtrl.text) ?? _result!.tax,
      tip: double.tryParse(_tipCtrl.text) ?? _result!.tip,
      date: _reviewDate ?? _result!.date,
      items: _result!.items,
    );
    context.pop(confirmed);
  }

  void _rescan() => setState(() {
        _state = _ScanState.idle;
        _imageFile = null;
        _result = null;
        _progress = 0.0;
        _errorMessage = null;
        _aiParsed = false;
        _merchantCtrl.clear();
        _amountCtrl.clear();
        _subtotalCtrl.clear();
        _taxCtrl.clear();
        _tipCtrl.clear();
        _reviewDate = null;
      });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reviewDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandTeal,
            surface: Color(0xFF1A1A1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _reviewDate = picked);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: switch (_state) {
        _ScanState.idle => _buildIdleView(),
        _ScanState.scanning => _buildScanningView(),
        _ScanState.review => _buildReviewView(),
      },
    );
  }

  // ── Idle ──────────────────────────────────────────────────────

  Widget _buildIdleView() {
    return SafeArea(
      child: Column(
        children: [
          _topBar('Scan Receipt'),
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              shape: BoxShape.circle,
              border: Border.all(
                  color: _scanGreen.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(CupertinoIcons.doc_text,
                size: 46, color: _scanGreen),
          ),
          const SizedBox(height: AppSizes.lg),
          const Text(
            'Scan a Receipt',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Take a photo or choose from your\ngallery to extract transaction data.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSizes.lg),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: AppColors.systemRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                    color: AppColors.systemRed.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.exclamationmark_circle,
                      color: AppColors.systemRed, size: 18),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: AppColors.systemRed, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Column(
              children: [
                _primaryButton(
                  icon: CupertinoIcons.camera_fill,
                  label: 'Take Photo',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(height: AppSizes.md),
                _secondaryButton(
                  icon: CupertinoIcons.photo,
                  label: 'Choose from Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }

  // ── Scanning ──────────────────────────────────────────────────

  Widget _buildScanningView() {
    return SafeArea(
      child: Column(
        children: [
          _topBar('Processing Receipt'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stackHeight = constraints.maxHeight;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_imageFile!, fit: BoxFit.contain),
                        Container(color: Colors.black.withValues(alpha: 0.15)),
                        _cornerGuides(),
                        AnimatedBuilder(
                          animation: _scanLineAnimation,
                          builder: (context, _) => Positioned(
                            top: _scanLineAnimation.value * (stackHeight - 24),
                            left: 0,
                            right: 0,
                            child: _scanLine(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, 0, AppSizes.lg, AppSizes.lg),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'OCR Scanning…',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(_progress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: _scanGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation(_scanGreen),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  'Extracting merchant, amount, and date…',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Review ────────────────────────────────────────────────────

  Widget _buildReviewView() {
    final result = _result!;
    return SafeArea(
      child: Column(
        children: [
          _topBar('Review Receipt'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusCard),
                    child: Image.file(
                      _imageFile!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  // AI / regex badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md, vertical: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.brandTeal.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusFull),
                      border: Border.all(
                          color: AppColors.brandTeal.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _aiParsed
                              ? CupertinoIcons.sparkles
                              : CupertinoIcons.checkmark_circle_fill,
                          color: AppColors.brandTeal,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _aiParsed
                              ? 'AI parsed — tap any field to edit'
                              : 'Receipt scanned — tap any field to edit',
                          style: const TextStyle(
                            color: AppColors.brandTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _editableCard(),
                  const SizedBox(height: AppSizes.md),
                  _itemsCard(result.items, result.fullText),
                  const SizedBox(height: AppSizes.lg),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, 0, AppSizes.lg, AppSizes.xxl),
            child: Column(
              children: [
                _primaryButton(
                  icon: CupertinoIcons.checkmark,
                  label: 'Use This Data',
                  onTap: _confirm,
                ),
                const SizedBox(height: AppSizes.md),
                _secondaryButton(
                  icon: CupertinoIcons.arrow_counterclockwise,
                  label: 'Scan Again',
                  onTap: _rescan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared widgets ────────────────────────────────────────────

  Widget _topBar(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.sm, AppSizes.sm, AppSizes.md, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(CupertinoIcons.xmark,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSizes.xs),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanLine() {
    return SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft glow beam
          Container(
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  _scanGreen.withValues(alpha: 0.08),
                  _scanGreen.withValues(alpha: 0.18),
                  _scanGreen.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Sharp line with glow
          Container(
            height: 2.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _scanGreen.withValues(alpha: 0.5),
                  _scanGreen,
                  _scanGreen.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _scanGreen.withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: _scanGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cornerGuides() {
    const len = 28.0;
    const thick = 2.5;
    const pad = 20.0;
    return Stack(
      children: [
        Positioned(
            top: pad,
            left: pad,
            child: _bracket(len, thick, top: true, left: true)),
        Positioned(
            top: pad,
            right: pad,
            child: _bracket(len, thick, top: true, left: false)),
        Positioned(
            bottom: pad,
            left: pad,
            child: _bracket(len, thick, top: false, left: true)),
        Positioned(
            bottom: pad,
            right: pad,
            child: _bracket(len, thick, top: false, left: false)),
      ],
    );
  }

  Widget _bracket(double len, double thick,
          {required bool top, required bool left}) =>
      SizedBox(
        width: len,
        height: len,
        child: CustomPaint(
          painter: _CornerPainter(
              thickness: thick, isTop: top, isLeft: left),
        ),
      );

  Widget _editableCard() {
    final rows = <Widget>[];

    rows.add(_editableRow(
      icon: CupertinoIcons.bag,
      label: 'Merchant',
      controller: _merchantCtrl,
      isFirst: true,
    ));

    if (_result!.subtotal > 0 || _subtotalCtrl.text.isNotEmpty) {
      rows.add(_divider());
      rows.add(_editableRow(
        icon: CupertinoIcons.list_bullet,
        label: 'Subtotal',
        controller: _subtotalCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: '\$',
      ));
    }

    if (_result!.tax > 0 || _taxCtrl.text.isNotEmpty) {
      rows.add(_divider());
      rows.add(_editableRow(
        icon: CupertinoIcons.percent,
        label: 'Tax',
        controller: _taxCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: '\$',
      ));
    }

    if (_result!.tip > 0 || _tipCtrl.text.isNotEmpty) {
      rows.add(_divider());
      rows.add(_editableRow(
        icon: CupertinoIcons.heart,
        label: 'Tip',
        controller: _tipCtrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        prefix: '\$',
      ));
    }

    rows.add(_divider());
    rows.add(_editableRow(
      icon: CupertinoIcons.money_dollar_circle,
      label: 'Total',
      controller: _amountCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefix: '\$',
      bold: true,
      valueColor: AppColors.systemRed,
    ));

    rows.add(_divider());
    // Date row — tappable, not a text field
    rows.add(GestureDetector(
      onTap: _pickDate,
      child: _dataRow(
        icon: CupertinoIcons.calendar,
        label: 'Date',
        value: _formatDate(_reviewDate ?? DateTime.now()),
        isLast: true,
        trailing: const Icon(CupertinoIcons.pencil,
            size: 14, color: AppColors.brandTeal),
      ),
    ));

    return _card(child: Column(children: rows));
  }

  Widget _editableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? prefix,
    bool isFirst = false,
    bool isLast = false,
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        isFirst ? AppSizes.md : AppSizes.sm + 2,
        AppSizes.md,
        isLast ? AppSizes.md : AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.labelDark, size: 17),
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (prefix != null)
                  Text(
                    prefix,
                    style: TextStyle(
                      color: (valueColor ?? Colors.white)
                          .withValues(alpha: 0.7),
                      fontSize: bold ? 15 : 14,
                      fontWeight:
                          bold ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                Flexible(
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: bold ? 15 : 14,
                      fontWeight:
                          bold ? FontWeight.w700 : FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '—',
                      hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(List<String> items, String rawText) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Parsed items ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.md, AppSizes.md, AppSizes.md, AppSizes.sm),
            child: Text(
              'ITEMS',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.md, 0, AppSizes.md, AppSizes.sm),
              child: Text(
                'No items detected — see raw text below.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
              ),
            )
          else
            ...items.asMap().entries.map((e) => Column(
                  children: [
                    if (e.key > 0) _divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm + 2),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              CupertinoIcons.doc_text,
                              color: AppColors.labelDark,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),
          // ── Raw OCR text (always visible for debugging) ───────
          _divider(),
          Theme(
            data: ThemeData(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: 0),
              title: Text(
                'RAW OCR TEXT',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              iconColor: Colors.white.withValues(alpha: 0.3),
              collapsedIconColor: Colors.white.withValues(alpha: 0.3),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSizes.md, 0, AppSizes.md, AppSizes.md),
                  child: SelectableText(
                    rawText.isEmpty ? '(nothing extracted)' : rawText,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(AppSizes.radiusCard),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: child,
      );

  Widget _dataRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool isFirst = false,
    bool isLast = false,
    bool bold = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        isFirst ? AppSizes.md : AppSizes.sm + 2,
        AppSizes.md,
        isLast ? AppSizes.md : AppSizes.sm + 2,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.labelDark, size: 17),
          ),
          const SizedBox(width: AppSizes.md),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: bold ? 14 : 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: bold ? 15 : 14,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSizes.xs),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: AppSizes.md + 18 + AppSizes.md,
      );

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightLg,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  Widget _secondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightLg,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );

  String _formatDate(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Corner bracket CustomPainter ─────────────────────────────

class _CornerPainter extends CustomPainter {
  final double thickness;
  final bool isTop;
  final bool isLeft;

  const _CornerPainter({
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  static const _color = Color(0xFF00FF9F);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    if (isTop && isLeft) {
      canvas.drawLine(const Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(0, h), paint);
    } else if (isTop && !isLeft) {
      canvas.drawLine(Offset(w, 0), const Offset(0, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    } else if (!isTop && isLeft) {
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
      canvas.drawLine(Offset(0, h), const Offset(0, 0), paint);
    } else {
      canvas.drawLine(Offset(w, h), Offset(0, h), paint);
      canvas.drawLine(Offset(w, h), Offset(w, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.thickness != thickness ||
      old.isTop != isTop ||
      old.isLeft != isLeft;
}
