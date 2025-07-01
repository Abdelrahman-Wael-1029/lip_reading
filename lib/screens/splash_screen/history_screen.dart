import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/navigation_cubit/navigation_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/utils/app_colors.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  static const String routeName = '/history';

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  TextEditingController searchController = TextEditingController();
  List<VideoModel> filteredVideos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<VideoCubit>().fetchVideos(),
    );
  }

  void _onSearch(String query, List<VideoModel> videos) {
    setState(() {
      filteredVideos = videos
          .where((video) =>
              video.title.toLowerCase().trim().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _onRefresh() async {
    if (mounted) await context.read<VideoCubit>().fetchVideos();
    if (mounted) {
      _onSearch(searchController.text, context.read<VideoCubit>().videos);
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final videoCubit = context.watch<VideoCubit>();
    final state = videoCubit.state;
    final videos = videoCubit.videos;
    final displayVideos =
        searchController.text.isEmpty ? videos : filteredVideos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.logout),
        //     onPressed: () => _showLogoutDialog(context),
        //   ),
        // ],
      ),
      body: state is HistoryLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (videos.isNotEmpty) ...[
                    customTextFormField(
                      context: context,
                      controller: searchController,
                      hintText: "Search videos",
                      onChanged: (query) => _onSearch(query, videos),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (displayVideos.isEmpty && videos.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 8),
                          const Text('No result found'),
                        ],
                      ),
                    )
                  else if (videos.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No history found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your lip reading results will appear here',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    ...displayVideos.map((video) => _buildVideoHistoryItem(
                          context,
                          video,
                          isDarkMode,
                        )),
                ],
              ),
            ),
    );
  }

  void _showDeleteDialog(BuildContext context, VideoModel video) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.rightSlide,
      title: 'Are you sure',
      desc: 'Do you want to delete this video?',
      btnOkOnPress: () =>
          context.read<VideoCubit>().deleteVideo(context, video.id),
      btnOkColor: Theme.of(context).colorScheme.error,
      btnCancelOnPress: () {},
      btnCancelColor: Theme.of(context).colorScheme.primary,
    ).show();
  }

  Widget _buildVideoHistoryItem(
    BuildContext context,
    VideoModel video,
    bool isDarkMode,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          if (context.read<VideoCubit>().loading) return;
          bool success =
              await context.read<VideoCubit>().initializeNetworkVideo(video);
          if (success) {
            context.read<NavigationCubit>().setTab(0);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 16,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_library,
                      size: 32,
                      color: isDarkMode
                          ? AppColors.accentDark
                          : AppColors.accentLight,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title.isNotEmpty
                              ? video.title
                              : 'Untitled Video',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatDate(video.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(children: [
                    Text(video.model),
                    Text(
                      video.diacritized == true ? 'Diacritized' : 'Plain',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                    ),
                  ]),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color:
                        isDarkMode ? AppColors.errorDark : AppColors.errorLight,
                    onPressed: () => _showDeleteDialog(context, video),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Result:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? AppColors.backgroundDark.withValues(alpha: 0.5)
                      : AppColors.backgroundLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode
                        ? AppColors.dividerDark
                        : AppColors.dividerLight,
                    width: 1,
                  ),
                ),
                child: Text(
                  video.result.isNotEmpty
                      ? video.result
                      : 'No result available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
