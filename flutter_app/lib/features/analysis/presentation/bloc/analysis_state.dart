part of 'analysis_bloc.dart';

abstract class AnalysisState extends Equatable {
  const AnalysisState();

  @override
  List<Object> get props => [];
}

class AnalysisInitial extends AnalysisState {}

class AnalysisLoading extends AnalysisState {}

class AnalysisSuccess extends AnalysisState {
  final String _result;
  final String _description;

  const AnalysisSuccess(this._result, this._description);

  String get result => _result;
  String get description => _description;

  @override
  List<Object> get props => [_result, _description];
}

class AnalysisError extends AnalysisState {
  final String message;

  const AnalysisError(this.message);

  @override
  List<Object> get props => [message];
}
