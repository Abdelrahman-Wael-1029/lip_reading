import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';

/// Modern AI model selector with smooth animations and improved design
class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key});

  @override
  State<ModelSelector> createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector>
    with TickerProviderStateMixin {
  late AnimationController _loadingAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _slideAnimation;
  bool _isLoadingAnimationActive = false;

  @override
  void initState() {
    super.initState();

    // Loading animation controller - faster for loading indicator
    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Slide animation controller - slower for smooth transitions
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeInOut,
    ));

    // Don't start slide animation immediately - wait for models to load
  }

  @override
  void dispose() {
    _loadingAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  // Model information with descriptions
  final Map<String, Map<String, String>> modelInfo = {
    'mstcn': {
      'name': 'MSTCN',
      'description': 'Multi-Scale Temporal Convolutional Network',
      'detail': 'Fast & efficient',
    },
    'dctcn': {
      'name': 'DCTCN',
      'description': 'Densely-Connected Temporal Convolutional Network',
      'detail': 'Balanced accuracy',
    },
    'conformer': {
      'name': 'Conformer',
      'description': 'Convolution-augmented Transformer',
      'detail': 'Highest accuracy',
    },
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<VideoCubit, VideoState>(
      builder: (context, state) {
        final videoCubit = context.read<VideoCubit>();

        // Handle loading animation for model fetching
        if (videoCubit.models == null || state is ModelLoading) {
          // Start repeating animation for loading
          if (!_isLoadingAnimationActive) {
            _isLoadingAnimationActive = true;
            _loadingAnimationController.repeat();
          }
          return _buildLoadingState(context);
        } else {
          // Stop repeating and reset for normal use
          if (_isLoadingAnimationActive) {
            _isLoadingAnimationActive = false;
            _loadingAnimationController.stop();
            _loadingAnimationController.reset();
          }

          // Always ensure slide animation is properly started
          if (!_slideAnimationController.isAnimating &&
              _slideAnimationController.status != AnimationStatus.completed) {
            _slideAnimationController.reset();
            _slideAnimationController.forward();
          }
        }

        if (videoCubit.models!.isEmpty) {
          return _buildErrorState(context);
        }

        return AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - _slideAnimation.value)),
              child: Opacity(
                opacity: _slideAnimation.value.clamp(0.0, 1.0),
                child: Column(
                  children: [
                    ...videoCubit.models!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final model = entry.value;
                      final isSelected = model == videoCubit.selectedModel;
                      final isProcessing =
                          state is ModelProcessing && isSelected;
                      final info = modelInfo[model.toLowerCase()] ??
                          {
                            'name': model,
                            'description': 'AI Model',
                            'detail': '',
                          };

                      return Column(
                        children: [
                          if (index > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: colorScheme.outline.withValues(alpha: 0.1),
                            ),
                          _buildModelOption(
                            context,
                            model: model,
                            info: info,
                            isSelected: isSelected,
                            isProcessing: isProcessing,
                            onTap: () {
                              if (videoCubit.loading) return;
                              if (!isSelected) {
                                HapticFeedback.selectionClick();
                                videoCubit.selectedModel = model;
                                videoCubit.changeModel(model, context);
                              }
                            },
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    _buildModelDescription(context, videoCubit.selectedModel),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModelOption(
    BuildContext context, {
    required String model,
    required Map<String, String> info,
    required bool isSelected,
    required bool isProcessing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Model icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.onPrimary.withValues(alpha: 0.2)
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getModelIcon(model.toLowerCase()),
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),

                const SizedBox(width: 16),

                // Model information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['name']!,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info['description']!,
                        style: textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colorScheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: isSelected
                        ? null
                        : Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.5),
                            width: 2,
                          ),
                  ),
                  child: isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.check,
                          size: 16,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : Colors.transparent,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDescription(BuildContext context, String selectedModel) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = modelInfo[selectedModel.toLowerCase()];

    if (info == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${info['name']}: ${info['detail']}',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Loading animation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Loading AI models...',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Loading progress indicator
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _loadingAnimationController,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: _loadingAnimationController.value,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Connecting to server...',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModelIcon(String model) {
    switch (model) {
      case 'mstcn':
        return Icons.speed;
      case 'dstcn':
        return Icons.balance;
      case 'conformer':
        return Icons.star;
      default:
        return Icons.psychology;
    }
  }

  Widget _buildErrorState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final videoCubit = context.read<VideoCubit>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Error icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: colorScheme.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load AI models',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Error description
          Text(
            'We\'re having trouble connecting to our servers. This could be a temporary issue.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Retry button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                videoCubit.fetchModels();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Try Again',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Detailed error info button
          GestureDetector(
            onTap: () => _showDetailedErrorInfo(context),
            child: Text(
              'What could be causing this?',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                decoration: TextDecoration.underline,
                decorationColor:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedErrorInfo(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Possible Causes',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error reasons
                _buildErrorReason(
                  context,
                  icon: Icons.cloud_off_rounded,
                  title: 'Server Issues',
                  description:
                      'Our servers might be temporarily unavailable or under maintenance.',
                ),
                _buildErrorReason(
                  context,
                  icon: Icons.wifi_off_rounded,
                  title: 'Network Connection',
                  description:
                      'Please check your internet connection and try again.',
                ),
                _buildErrorReason(
                  context,
                  icon: Icons.security_rounded,
                  title: 'Firewall/Proxy',
                  description:
                      'Corporate firewalls or proxy settings might be blocking the connection.',
                ),
                _buildErrorReason(
                  context,
                  icon: Icons.update_rounded,
                  title: 'Service Update',
                  description:
                      'The AI service might be updating. Please try again in a few minutes.',
                ),

                const SizedBox(height: 16),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorReason(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
