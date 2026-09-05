import 'package:flutter_compass/flutter_compass.dart';

abstract class CompassSource {
  Stream<double?> get headings;
}

class FlutterCompassSource implements CompassSource {
  @override
  Stream<double?> get headings =>
      FlutterCompass.events?.map((event) => event.heading) ??
      const Stream.empty();
}
