import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  Set<String> selectedStatuses = {};
  bool expandGenres = false;

  void setStatus(String status) {
    selectedStatuses = {status};
    expandGenres = false;
    notifyListeners();
  }

  void openGenres() {
    selectedStatuses.clear();
    expandGenres = true;
    notifyListeners();
  }

  void clear() {
    selectedStatuses.clear();
    expandGenres = false;
    notifyListeners();
  }
}