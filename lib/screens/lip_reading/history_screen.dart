import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_text_from_field.dart';
import 'package:lip_reading/cubit/auth/auth_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/cubit/video_cubit/video_state.dart';
import 'package:lip_reading/model/video_model.dart';
import 'package:lip_reading/screens/auth/login_screen.dart';
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<VideoCubit>().cleanupController();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  LoginScreen.routeName,
                  (route) => false,
                );
                context.read<AuthCubit>().logout();
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onSearch(String query, List<VideoModel> videos) {
    setState(() {
      filteredVideos = videos
          .where((video) =>
              video.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<VideoCubit>().fetchVideos();
    _onSearch(searchController.text, context.read<VideoCubit>().videos);
  }

  String formatDate(DateTime date) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: state is HistoryLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (state is HistoryError)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Error loading history',
                          style: TextStyle(
                            color: isDarkMode
                                ? AppColors.errorDark
                                : AppColors.errorLight,
                          ),
                        ),
                      ),
                    ),
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
          final bool success =
              await context.read<VideoCubit>().initializeNetworkVideo(video);
          if (context.mounted && success) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading video',
                    style: TextStyle(color: AppColors.white)),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const SizedBox(width: 16),
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
                          formatDate(video.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
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
                      ? AppColors.backgroundDark.withOpacity(0.5)
                      : AppColors.backgroundLight.withOpacity(0.5),
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
