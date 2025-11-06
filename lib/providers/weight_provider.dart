import 'package:flutter/material.dart';

class WeightProvider extends ChangeNotifier {
  double _weight = 10.0;

  double get weight => _weight;

  void setWeight(double newWeight) {
    if (newWeight > 0 && newWeight <= 50) {
      _weight = newWeight;
      notifyListeners();
    }
  }

  double weightToSliderValue(double weight) {
    if (weight <= 10) {
      return weight / 0.25;
    } else {
      return 40 + (weight - 10);
    }
  }

  double sliderValueToWeight(double sliderValue) {
    if (sliderValue <= 40) {
      return sliderValue * 0.25;
    } else {
      return 10 + (sliderValue - 40);
    }
  }
}