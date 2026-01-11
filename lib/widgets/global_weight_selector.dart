import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';

// Version "Full" pour l'AppBar quand il y a de la place
class GlobalWeightSelector extends StatelessWidget {
  const GlobalWeightSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, _) {
        final w = weightProvider.weight;
        return TextButton.icon(
          onPressed: () => _showWeightDialog(context, weightProvider),
          icon: const Icon(Icons.monitor_weight),
          label: Text(w != null ? '${weightProvider.formattedWeight} kg' : 'Poids'),
        );
      },
    );
  }
}

// Version Compacte (Icône seulement ou texte court) pour les petits écrans/titres chargés
class GlobalWeightSelectorCompact extends StatelessWidget {
  const GlobalWeightSelectorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, _) {
        final w = weightProvider.weight;
        return IconButton(
          onPressed: () => _showWeightDialog(context, weightProvider),
          icon: Badge(
            isLabelVisible: w != null,
            label: Text(w != null ? '${weightProvider.formattedWeight}kg' : ''),
            child: const Icon(Icons.monitor_weight),
          ),
        );
      },
    );
  }
}

// Logique commune du dialogue
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
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: tempWeight,
                min: 0.4,
                max: 50.0,
                divisions: 496,
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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  _QuickBtn('-1', () => setDialogState(() => tempWeight = (tempWeight - 1).clamp(0.4, 50.0))),
                  _QuickBtn('-0.1', () => setDialogState(() => tempWeight = (((tempWeight - 0.1) * 10).round() / 10).clamp(0.4, 50.0))),
                  _QuickBtn('+0.1', () => setDialogState(() => tempWeight = (((tempWeight + 0.1) * 10).round() / 10).clamp(0.4, 50.0))),
                  _QuickBtn('+1', () => setDialogState(() => tempWeight = (tempWeight + 1).clamp(0.4, 50.0))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () { provider.clearWeight(); Navigator.pop(context); }, child: const Text('Effacer')),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            FilledButton(onPressed: () { provider.setWeight(tempWeight); Navigator.pop(context); }, child: const Text('Valider')),
          ],
        );
      },
    ),
  );
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(40, 36)),
      child: Text(label),
    );
  }
}