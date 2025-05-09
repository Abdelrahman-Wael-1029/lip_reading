abstract class VideoState {}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class VideoSuccess extends VideoState {}

class VideoError extends VideoState {
  final String errorMessage;
  VideoError(this.errorMessage);
}
