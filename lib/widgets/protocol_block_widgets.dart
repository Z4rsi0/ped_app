import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/protocol_model.dart';
import '../providers/weight_provider.dart';
import '../services/medicament_resolver.dart';

/// Widget pour rendre un bloc de protocole
class ProtocolBlockWidget extends StatelessWidget {
  final ProtocolBlock block;

  const ProtocolBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case BlockType.section:
        return SectionBlockWidget(block: block as SectionBlock);
      case BlockType.texte:
        return TexteBlockWidget(block: block as TexteBlock);
      case BlockType.tableau:
        return TableauBlockWidget(block: block as TableauBlock);
      case BlockType.image:
        return ImageBlockWidget(block: block as ImageBlock);
      case BlockType.medicament:
        return MedicamentBlockWidget(block: block as MedicamentBlock);
      case BlockType.formulaire:
        return FormulaireBlockWidget(block: block as FormulaireBlock);
      case BlockType.alerte:
        return AlerteBlockWidget(block: block as AlerteBlock);
    }
  }
}

/// Widget Section - Tuile collapsible
class SectionBlockWidget extends StatefulWidget {
  final SectionBlock block;

  const SectionBlockWidget({super.key, required this.block});

  @override
  State<SectionBlockWidget> createState() => _SectionBlockWidgetState();
}

class _SectionBlockWidgetState extends State<SectionBlockWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.block.initialementOuvert;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.block.ordre + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.block.titre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.block.temps != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer,
                              size: 14, color: Colors.blue.shade600),
                          const SizedBox(width: 4),
                          Text(
                            widget.block.temps!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          // Contenu
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.block.contenu
                    .map((b) => ProtocolBlockWidget(block: b))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget Texte - Texte avec formatage
class TexteBlockWidget extends StatelessWidget {
  final TexteBlock block;

  const TexteBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    TextStyle style = const TextStyle(fontSize: 15, height: 1.5);

    if (block.format != null) {
      style = style.copyWith(
        fontWeight: block.format!.gras ? FontWeight.bold : null,
        fontStyle: block.format!.italique ? FontStyle.italic : null,
        decoration: block.format!.souligne ? TextDecoration.underline : null,
        color: block.format!.couleur != null
            ? _parseColor(block.format!.couleur!)
            : null,
        fontSize: block.format!.taillePolicePx,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SelectableText(
        block.contenu,
        style: style,
      ),
    );
  }

  Color? _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      }
      // Couleurs nommées
      switch (colorStr.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'orange':
          return Colors.orange;
        case 'purple':
          return Colors.purple;
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }
}

/// Widget Tableau - Tableau de données
class TableauBlockWidget extends StatelessWidget {
  final TableauBlock block;

  const TableauBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.titre != null && block.titre!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
              ),
              child: Text(
                block.titre!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
              columns: block.colonnes
                  .map((col) => DataColumn(
                        label: Text(
                          col,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
              rows: block.lignes
                  .map((row) => DataRow(
                        cells: row
                            .map((cell) => DataCell(Text(cell)))
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Image - Image base64 ou URL
class ImageBlockWidget extends StatelessWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (block.estBase64) {
      try {
        final bytes = base64Decode(block.source);
        imageWidget = Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.contain,
        );
      } catch (e) {
        imageWidget = Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey.shade200,
          child: const Text('Erreur de chargement de l\'image'),
        );
      }
    } else {
      imageWidget = Image.network(
        block.source,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade200,
            child: const Text('Erreur de chargement de l\'image'),
          );
        },
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: block.largeurPourcent != null
                ? MediaQuery.of(context).size.width *
                    (block.largeurPourcent! / 100)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageWidget,
            ),
          ),
          if (block.legende != null && block.legende!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                block.legende!,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget Médicament - Référence avec calcul de dose
class MedicamentBlockWidget extends StatelessWidget {
  final MedicamentBlock block;

  const MedicamentBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        final resolver = MedicamentResolver();
        PosologieResolue? posologie;
        String? errorMessage;
        
        final poids = weightProvider.weight ?? 10.0;

        try {
          posologie = resolver.resolveMedicament(
            nomMedicament: block.nomMedicament,
            indication: block.indication,
            voie: block.voie,
            poids: poids,
          );
        } catch (e) {
          errorMessage = e.toString();
        }

        if (errorMessage != null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        block.nomMedicament,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      Text(
                        'Erreur: $errorMessage',
                        style:
                            TextStyle(color: Colors.red.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        if (posologie == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade300, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade600,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.medication,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          posologie.nomMedicament,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                        Text(
                          posologie.voie,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calculate,
                            size: 16, color: Colors.purple.shade600),
                        const SizedBox(width: 6),
                        Text(
                          'Dose:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      posologie.dose,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              if (posologie.preparation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  posologie.preparation,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
              if (block.commentaire != null && block.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  block.commentaire!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Widget Formulaire - Score clinique interactif
class FormulaireBlockWidget extends StatefulWidget {
  final FormulaireBlock block;

  const FormulaireBlockWidget({super.key, required this.block});

  @override
  State<FormulaireBlockWidget> createState() => _FormulaireBlockWidgetState();
}

class _FormulaireBlockWidgetState extends State<FormulaireBlockWidget> {
  final Map<String, num> _valeurs = {};

  @override
  void initState() {
    super.initState();
    // Initialiser les valeurs par défaut
    for (final champ in widget.block.champs) {
      if (champ.defaut != null) {
        _valeurs[champ.id] = champ.defaut!;
      } else if (champ.type == ChampType.checkbox) {
        _valeurs[champ.id] = 0;
      } else if (champ.type == ChampType.nombre) {
        _valeurs[champ.id] = champ.min ?? 0;
      } else if (champ.options != null && champ.options!.isNotEmpty) {
        _valeurs[champ.id] = champ.options!.first.valeur;
      }
    }
  }

  num _calculerScore() {
    num total = 0;
    for (final champ in widget.block.champs) {
      final valeur = _valeurs[champ.id] ?? 0;
      if (champ.type == ChampType.checkbox && valeur == 1) {
        total += champ.points ?? 1;
      } else {
        total += valeur;
      }
    }
    return total;
  }

  FormulaireInterpretation? _getInterpretation(num score) {
    if (widget.block.interpretations == null) return null;
    for (final interp in widget.block.interpretations!) {
      if (score >= interp.min && score <= interp.max) {
        return interp;
      }
    }
    return null;
  }

  Color _getNiveauColor(String? niveau) {
    switch (niveau) {
      case 'faible':
        return Colors.green;
      case 'modere':
        return Colors.orange;
      case 'eleve':
        return Colors.deepOrange;
      case 'critique':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculerScore();
    final interpretation = _getInterpretation(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.block.titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.block.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.block.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.teal.shade100,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Champs
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: widget.block.champs
                  .map((champ) => _buildChamp(champ))
                  .toList(),
            ),
          ),
          // Score et interprétation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: interpretation != null
                  ? _getNiveauColor(interpretation.niveau).withAlpha(25)
                  : Colors.grey.shade100,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Score: ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      score.toStringAsFixed(
                          score.truncateToDouble() == score ? 0 : 1),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: interpretation != null
                            ? _getNiveauColor(interpretation.niveau)
                            : Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
                if (interpretation != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getNiveauColor(interpretation.niveau),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      interpretation.texte,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamp(FormulaireChamp champ) {
    switch (champ.type) {
      case ChampType.nombre:
        return _buildNombreChamp(champ);
      case ChampType.selection:
        return _buildSelectionChamp(champ);
      case ChampType.checkbox:
        return _buildCheckboxChamp(champ);
      case ChampType.radio:
        return _buildRadioChamp(champ);
    }
  }

  Widget _buildNombreChamp(FormulaireChamp champ) {
    final valeur = _valeurs[champ.id] ?? champ.min ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(champ.label),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    final newVal = (valeur - 1).clamp(
                      champ.min ?? double.negativeInfinity,
                      champ.max ?? double.infinity,
                    );
                    setState(() {
                      _valeurs[champ.id] = newVal;
                    });
                  },
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: Text(
                    valeur
                        .toStringAsFixed(valeur.truncateToDouble() == valeur ? 0 : 1),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    final newVal = (valeur + 1).clamp(
                      champ.min ?? double.negativeInfinity,
                      champ.max ?? double.infinity,
                    );
                    setState(() {
                      _valeurs[champ.id] = newVal;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionChamp(FormulaireChamp champ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            champ.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<num>(
            value: _valeurs[champ.id],
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: champ.options
                ?.map((opt) => DropdownMenuItem(
                      value: opt.valeur,
                      child: Text(opt.label),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _valeurs[champ.id] = val;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxChamp(FormulaireChamp champ) {
    final isChecked = (_valeurs[champ.id] ?? 0) == 1;
    return CheckboxListTile(
      title: Text(champ.label),
      subtitle: champ.points != null
          ? Text('${champ.points} point(s)')
          : null,
      value: isChecked,
      onChanged: (val) {
        setState(() {
          _valeurs[champ.id] = val == true ? 1 : 0;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRadioChamp(FormulaireChamp champ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            champ.label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ...?champ.options?.map((opt) => RadioListTile<num>(
                title: Text(opt.label),
                value: opt.valeur,
                groupValue: _valeurs[champ.id],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _valeurs[champ.id] = val;
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              )),
        ],
      ),
    );
  }
}

/// Widget Alerte - Bloc d'attention/warning
class AlerteBlockWidget extends StatelessWidget {
  final AlerteBlock block;

  const AlerteBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    switch (block.niveau) {
      case AlerteNiveau.info:
        backgroundColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade300;
        textColor = Colors.blue.shade900;
        icon = Icons.info_outline;
        break;
      case AlerteNiveau.attention:
        backgroundColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade300;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber;
        break;
      case AlerteNiveau.danger:
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red.shade300;
        textColor = Colors.red.shade900;
        icon = Icons.error_outline;
        break;
      case AlerteNiveau.critique:
        backgroundColor = Colors.red.shade100;
        borderColor = Colors.red.shade700;
        textColor = Colors.red.shade900;
        icon = Icons.dangerous;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              block.contenu,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}