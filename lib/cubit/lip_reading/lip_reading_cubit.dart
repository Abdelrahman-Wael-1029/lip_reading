import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/cubit/lip_reading/lip_reading_state.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';

class LipReadingCubit extends Cubit<LipReadingState> {
  LipReadingCubit() : super(LipReadingInitial());
  void pickVideoFromGallery(BuildContext context) async {
    emit(LipReadingVideoLoading());
    await context.read<VideoCubit>().pickVideoFromGallery();
    emit(LipReadingVideoSuccess());
  }

  void recordVideo(BuildContext context) async {
    emit(LipReadingVideoLoading());
    await context.read<VideoCubit>().recordVideo();
    emit(LipReadingVideoSuccess());
  }
}
