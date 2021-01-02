import 'package:meta/meta.dart';

class Measure {
  final String name;
  final double conversion;
  const Measure({
    @required this.name,
    @required this.conversion,
  })  : assert(name != null),
        assert(conversion != null);
  Measure.fromJson(Map jsonMap)
      : assert(jsonMap['name'] != null),
        assert(jsonMap['conversion'] != null),
        name = jsonMap['name'],
        conversion = jsonMap['conversion'].toDouble();
}