abstract class UseCase<TResult, Params> {
  Future<TResult> call(Params params);
}
