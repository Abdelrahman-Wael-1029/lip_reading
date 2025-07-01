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
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      buildWhen: (previous, current) => (current is! VideoPlaying &&
          current is! HistoryLoading &&
          current is! HistoryFetchedSuccess &&
          current is! HistoryError),
      builder: (context, state) {
        final videoCubit = context.read<VideoCubit>();
        if (videoCubit.models == null) {
          return _buildLoadingState(context);
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
                opacity: _slideAnimation.value,
                child: Column(
                  children: [
                    ...videoCubit.models!.asMap().entries.map((entry) {
                      final index = entry.key;
                      final model = entry.value;
                      final isSelected = model == videoCubit.selectedModel;
                      final info = modelInfo[model.toLowerCase()] ??
                          {
                            'name': model,
                            'description': 'Ai Model',
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
                        : colorScheme.surfaceVariant.withValues(alpha: 0.5),
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
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color:
                        isSelected ? colorScheme.onPrimary : Colors.transparent,
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading AI models...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Error loading AI models. Please try again later.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
