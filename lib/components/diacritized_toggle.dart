import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';

/// Modern segmented control for diacritized text toggle
/// Provides clear visual feedback and smooth animations
class DiacritizedToggle extends StatelessWidget {
  const DiacritizedToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<VideoCubit, VideoState>(
      buildWhen: (previous, current) => (current is! VideoPlaying &&
          current is! HistoryLoading &&
          current is! HistoryFetchedSuccess &&
          current is! HistoryError),
      builder: (context, state) {
        final videoCubit = context.read<VideoCubit>();
        final isProcessing = state is ModelProcessing;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Style',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegment(
                      context,
                      label: 'Plain',
                      subtitle: 'Without diacritics',
                      icon: Icons.text_fields,
                      isSelected: !videoCubit.isDiacritized,
                      isProcessing: isProcessing && !videoCubit.isDiacritized,
                      onTap: () {
                        if (videoCubit.loading) return;

                        if (videoCubit.isDiacritized) {
                          HapticFeedback.selectionClick();
                          videoCubit.toggleDiacritized(false);
                          videoCubit.changeTextStyle(context);
                        }
                      },
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _buildSegment(
                      context,
                      label: 'Diacritized',
                      subtitle: 'With harakat',
                      icon: Icons.text_snippet,
                      isSelected: videoCubit.isDiacritized,
                      isProcessing: isProcessing && videoCubit.isDiacritized,
                      onTap: () {
                        if (videoCubit.loading) return;
                        if (!videoCubit.isDiacritized) {
                          HapticFeedback.selectionClick();
                          videoCubit.toggleDiacritized(true);
                          videoCubit.changeTextStyle(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              videoCubit.isDiacritized
                  ? 'Arabic text will include diacritical marks (harakat)'
                  : 'Arabic text will be displayed without diacritical marks',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSegment(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isProcessing,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: isProcessing
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
