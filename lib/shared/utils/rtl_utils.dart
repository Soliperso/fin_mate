import 'package:flutter/cupertino.dart';

/// Returns the correct back-arrow icon depending on text direction.
/// In RTL (Arabic), the back arrow points right (chevron_right).
IconData backArrowIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? CupertinoIcons.chevron_right
        : CupertinoIcons.chevron_left;

/// Returns the correct forward-arrow icon depending on text direction.
IconData forwardArrowIcon(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
        ? CupertinoIcons.chevron_left
        : CupertinoIcons.chevron_right;
