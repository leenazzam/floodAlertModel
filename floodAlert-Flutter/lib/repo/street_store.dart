import 'package:flutter/foundation.dart';
import '../models/street_model.dart';

class StreetStore {
  StreetStore._();
  static final StreetStore instance = StreetStore._();

  final ValueNotifier<List<Street>> streetsAll = ValueNotifier<List<Street>>(
    [],
  );

  void setStreets(List<Street> all) {
    streetsAll.value = all;
  }

  void setUpdatedStreets(List<Street> all) {
    streetsAll.value = all;
  }
}
