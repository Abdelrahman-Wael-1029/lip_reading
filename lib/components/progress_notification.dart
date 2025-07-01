import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum NotificationType {
  success,
  error,
  info,
  warning,
}

class ProgressNotification {
  /// Show a modern toast notification
  static void showToast(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onRetry,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        onRetry: onRetry,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });

    // Haptic feedback
    if (type == NotificationType.success) {
      HapticFeedback.lightImpact();
    } else if (type == NotificationType.error) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Show a success notification
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showToast(
      context,
      message: message,
      type: NotificationType.success,
      duration: duration,
    );
  }

  /// Show an error notification with retry option
  static void showError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    showToast(
      context,
      message: message,
      type: NotificationType.error,
      duration: duration,
      onRetry: onRetry,
    );
  }

  /// Show an info notification
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(
      context,
      message: message,
      type: NotificationType.info,
      duration: duration,
    );
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color backgroundColor;
    Color foregroundColor;
    IconData icon;

    switch (widget.type) {
      case NotificationType.success:
        backgroundColor = colorScheme.tertiary;
        foregroundColor = colorScheme.onTertiary;
        icon = Icons.check_circle;
        break;
      case NotificationType.error:
        backgroundColor = colorScheme.error;
        foregroundColor = colorScheme.onError;
        icon = Icons.error;
        break;
      case NotificationType.warning:
        backgroundColor = const Color(0xFFFF9800); // Orange
        foregroundColor = Colors.white;
        icon = Icons.warning;
        break;
      case NotificationType.info:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        icon = Icons.info;
        break;
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: foregroundColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: textTheme.bodyMedium?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (widget.onRetry != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            _dismiss();
                            widget.onRetry?.call();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: foregroundColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close,
                          color: foregroundColor.withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
