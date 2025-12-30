import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';

/// Widget compact pour sélectionner le poids (utilisé dans les AppBar des écrans de détail)
class GlobalWeightSelectorCompact extends StatelessWidget {
  const GlobalWeightSelectorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, _) {
        final weight = weightProvider.weight;
        final displayWeight = weight != null
            ? weightProvider.formattedWeight
            : null;
            
        return TextButton.icon(
          onPressed: () => _showWeightDialog(context, weightProvider),
          icon: const Icon(Icons.monitor_weight, size: 18),
          label: Text(
            displayWeight != null ? '$displayWeight kg' : 'Poids',
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
    );
  }

  void _showWeightDialog(BuildContext context, WeightProvider provider) {
    double tempWeight = provider.weight ?? 10.0;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Sélection du poids'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tempWeight.toStringAsFixed(tempWeight < 10 ? 1 : 0)} kg',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: tempWeight,
                  min: 0.4,
                  max: 100.0,
                  divisions: 996,
                  onChanged: (value) {
                    setDialogState(() {
                      if (value < 10) {
                        tempWeight = (value * 10).round() / 10;
                      } else {
                        tempWeight = value.roundToDouble();
                      }
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _QuickWeightButton(
                      label: '-1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = (tempWeight - 1).clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '-0.1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = ((tempWeight - 0.1) * 10).round() / 10;
                          tempWeight = tempWeight.clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '+0.1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = ((tempWeight + 0.1) * 10).round() / 10;
                          tempWeight = tempWeight.clamp(0.4, 100.0);
                        });
                      },
                    ),
                    _QuickWeightButton(
                      label: '+1',
                      onPressed: () {
                        setDialogState(() {
                          tempWeight = (tempWeight + 1).clamp(0.4, 100.0);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.clearWeight();
                  Navigator.of(context).pop();
                },
                child: const Text('Effacer'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  provider.setWeight(tempWeight);
                  Navigator.of(context).pop();
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickWeightButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _QuickWeightButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label),
    );
  }
}