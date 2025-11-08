import 'package:flutter/material.dart';

class WeightProvider extends ChangeNotifier {
  double _weight = 10.0;

  // Constantes de plage
  static const double minWeight = 0.4;  // 400g
  static const double transition = 10.0;  // Transition à 10 kg
  static const double maxWeight = 50.0;  // Maximum 50 kg
  
  // Pas de progression
  static const double stepSmall = 0.1;  // 100g entre 0.4 et 10 kg
  static const double stepLarge = 1.0;  // 1 kg entre 10 et 50 kg
  
  // Nombre de positions sur le slider
  static const int positionsSmall = 96;  // (10 - 0.4) / 0.1 = 96
  static const int positionsLarge = 40;  // (50 - 10) / 1 = 40
  static const int totalPositions = 136; // 96 + 40

  double get weight => _weight;

  void setWeight(double newWeight) {
    if (newWeight >= minWeight && newWeight <= maxWeight) {
      _weight = newWeight;
      notifyListeners();
    }
  }

  /// Convertit un poids en valeur de slider (0-136)
  double weightToSliderValue(double weight) {
    if (weight < minWeight) return 0;
    if (weight > maxWeight) return totalPositions.toDouble();
    
    if (weight <= transition) {
      // Zone 0.4 - 10 kg : pas de 100g
      return (weight - minWeight) / stepSmall;
    } else {
      // Zone 10 - 50 kg : pas de 1 kg
      return positionsSmall + (weight - transition) / stepLarge;
    }
  }

  /// Convertit une valeur de slider (0-136) en poids
  double sliderValueToWeight(double sliderValue) {
    if (sliderValue <= 0) return minWeight;
    if (sliderValue >= totalPositions) return maxWeight;
    
    if (sliderValue <= positionsSmall) {
      // Zone 0.4 - 10 kg
      double weight = minWeight + (sliderValue * stepSmall);
      // Arrondir à 100g près
      return (weight * 10).roundToDouble() / 10;
    } else {
      // Zone 10 - 50 kg
      double weight = transition + ((sliderValue - positionsSmall) * stepLarge);
      // Arrondir au kg près
      return weight.roundToDouble();
    }
  }
}