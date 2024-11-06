typedef JsonObj = Map<String, dynamic>;

/// Returns a list of [T] built with [factory]
/// from a list of json **objects**.
List<T> fromJsonList<T>(
  List<dynamic>? jsonList,
  T Function(JsonObj) factory,
) {
  return (jsonList ?? []).map((e) => factory(e)).toList();
}

/// Returns a list of [T]
/// from a list of json **values**.
List<T> fromJsonValueList<T>(List<dynamic>? jsonList) {
  return (jsonList ?? []).cast<T>().toList();
}
