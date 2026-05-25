sealed class SensorValue<T> {
  const SensorValue();
}

class SensorNotQueried<T> extends SensorValue<T> {
  const SensorNotQueried();
}

class SensorLoading<T> extends SensorValue<T> {
  const SensorLoading();
}

class SensorData<T> extends SensorValue<T> {
  final T value;
  final bool refreshing;
  const SensorData({required this.value, this.refreshing = false});
}

class SensorError<T> extends SensorValue<T> {
  final String message;
  const SensorError({required this.message});
}
