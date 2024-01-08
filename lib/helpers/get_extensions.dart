import 'package:get/get.dart';

extension GetExtensions on GetInterface {
  /// Replaces an instance of a class in dependency management
  /// with a [dep] instance.
  /// - [tag] optional, if you use a [tag] to register the Instance.
  void replaceForced<P>(P dep, {String? tag}) {
    final info = GetInstance().getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: true);
    put(dep, tag: tag, permanent: permanent);
  }
}
