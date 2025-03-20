import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/components/custom_video_player.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_cubit.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_state.dart';
import 'package:lip_reading/utils/app_assets.dart';
import 'package:lip_reading/utils/app_colors.dart';
import 'package:lip_reading/utils/utils.dart';

class LipReadingScreen extends StatefulWidget {
  const LipReadingScreen({super.key});

  static const String routeName = '/lip-reading';

  @override
  State<LipReadingScreen> createState() => _LipReadingScreenState();
}

class _LipReadingScreenState extends State<LipReadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(
                    AppAssets.background2,
                  ),
                  fit: BoxFit.fill),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(getPadding(context)!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BlocConsumer<LipReadingCubit, LipReadingState>(
                    listener: (context, state) {},
                    builder: (context, state) {
                      if (state is LipReadingVideoError) {
                        return Container(
                          height: 300,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              state.message,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      } else if (state is LipReadingVideoSuccess) {
                        final videoController =
                            context.read<LipReadingCubit>().controller;
                        if (videoController != null) {
                          return Column(
                            spacing: getSizedBox(context)!,
                            children: [
                              CustomVideoPlayer(controller: videoController),
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: AppColors.primaryColor),
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.backgroundColor,
                                ),
                                padding: EdgeInsets.all(getPadding(context)!),
                                child: Text(
                                  'abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo abdo ',
                                  style:
                                      TextStyle(color: AppColors.primaryColor),
                                ),
                              )
                            ],
                          );
                        }
                      }
                      return Column(
                        children: [
                          ScaleTransition(
                            scale: _animation,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: getPadding(context)! * 2,
                                left: getPadding(context)!,
                                right: getPadding(context)!,
                                bottom: getPadding(context)!,
                              ),
                              child: Image.asset(
                                AppAssets.video,
                                width: getSizeImage(context),
                                height: getSizeImage(context),
                              ),
                            ),
                          ),
                          Text(
                            'GET START',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: getLargeFontSize(context),
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.backgroundColor,
                  width: 1,
                ),
              ),
              color: AppColors.secondaryColor,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      context.read<LipReadingCubit>().recordVideo();
                    },
                    icon: const Icon(
                      Icons.mic,
                      color: AppColors.backgroundColor,
                    ),
                  ),
                ),
                Expanded(
                  child: IconButton(
                    onPressed: () {
                      context.read<LipReadingCubit>().pickVideoFromGallery();
                    },
                    icon: const Icon(
                      Icons.photo,
                      color: AppColors.backgroundColor,
                    ),
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
