import 'package:lip_reading/model/progress_model.dart';

abstract class ProgressState {}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {
  final ProgressModel progress;

  ProgressLoading(this.progress);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressLoading && other.progress == progress;
  }

  @override
  int get hashCode => progress.hashCode;
}

class ProgressCompleted extends ProgressState {
  final ProgressModel progress;
  final Map<String, dynamic> result;

  ProgressCompleted(this.progress, this.result);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressCompleted &&
        other.progress == progress &&
        other.result == result;
  }

  @override
  int get hashCode => progress.hashCode ^ result.hashCode;
}

class ProgressFailed extends ProgressState {
  final ProgressModel progress;
  final String errorMessage;

  ProgressFailed(this.progress, this.errorMessage);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressFailed &&
        other.progress == progress &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => progress.hashCode ^ errorMessage.hashCode;
}

class ProgressCancelled extends ProgressState {
  final ProgressModel progress;

  ProgressCancelled(this.progress);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressCancelled && other.progress == progress;
  }

  @override
  int get hashCode => progress.hashCode;
}
