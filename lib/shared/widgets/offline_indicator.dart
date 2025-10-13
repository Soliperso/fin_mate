import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

/// Widget that shows an indicator when the device is offline
class OfflineIndicator extends StatefulWidget {
  final Widget child;

  const OfflineIndicator({super.key, required this.child});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _checkConnectivity();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((result) {
      final isOffline = result.contains(ConnectivityResult.none);
      if (isOffline != _isOffline) {
        setState(() {
          _isOffline = isOffline;
        });
        if (_isOffline) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final isOffline = result.contains(ConnectivityResult.none);
    if (mounted && isOffline != _isOffline) {
      setState(() {
        _isOffline = isOffline;
      });
      if (_isOffline) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        SlideTransition(
          position: _slideAnimation,
          child: _buildOfflineBanner(context),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Material(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.warning,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  'No internet connection',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              TextButton(
                onPressed: _checkConnectivity,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: 4,
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple banner that can be placed at the top of a page
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ConnectivityResult>>(
      future: Connectivity().checkConnectivity(),
      builder: (context, snapshot) {
        final isOffline =
            snapshot.hasData && snapshot.data!.contains(ConnectivityResult.none);

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          color: AppColors.warning,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                'Offline mode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}
