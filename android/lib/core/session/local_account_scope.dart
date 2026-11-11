import 'package:flutter/widgets.dart';

/// Namespaces new local data without deleting or claiming pre-authentication data.
class LocalAccountScope extends InheritedWidget {
  const LocalAccountScope({super.key, required this.uid, required super.child});
  final String uid;
  static String? read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<LocalAccountScope>()?.uid;
  @override
  bool updateShouldNotify(LocalAccountScope oldWidget) => uid != oldWidget.uid;
}
