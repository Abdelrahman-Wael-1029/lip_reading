abstract class LipReadingState {
  const LipReadingState();
}

class LipReadingInitial extends LipReadingState {}

class LipReadingVideoLoading extends LipReadingState {}
class LipReadingVideoSuccess extends LipReadingState {}

class LipReadingVideoError extends LipReadingState {
  final String message;

  const LipReadingVideoError(this.message);
}

