abstract class VideoState {}

class VideoInitial extends VideoState {}

class VideoLoading extends VideoState {}

class ModelLoading extends VideoState {}

class ModelProcessing extends VideoState {}

// for name and result
class VideoSuccess extends VideoState {}

// for other success states
class VideoPlaying extends VideoState {}

class VideoError extends VideoState {
  final String errorMessage;
  VideoError(this.errorMessage);
}

class HistoryLoading extends VideoState {}

class HistoryFetchedSuccess extends VideoState {}

class DeleteHistoryItemSuccess extends VideoState {}

class HistoryError extends VideoState {
  final String errorMessage;
  HistoryError(this.errorMessage);
}
