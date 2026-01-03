import 'dart:convert';
import 'package:flutter/foundation.dart'; // Pour compute
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/protocol_model.dart';
import '../providers/weight_provider.dart';
import '../services/medicament_resolver.dart';
import '../theme/app_theme.dart'; // Import du Design System

/// Widget racine pour rendre un bloc
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

/// SECTION : Tuile dépliable optimisée
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
    final colors = context.colors;
    // On utilise la couleur Primary du thème global pour structurer les sections
    final headerColor = colors.primary; 
    final headerContentColor = colors.onPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface, // Fond adaptatif (blanc/gris sombre)
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.05), // Ombre très légère
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(10),
              bottom: _isExpanded ? Radius.zero : const Radius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(10),
                  bottom: _isExpanded ? Radius.zero : const Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: headerContentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.block.ordre + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: headerColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.block.titre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: headerContentColor,
                      ),
                    ),
                  ),
                  if (widget.block.temps != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: headerContentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 14, color: headerContentColor),
                          const SizedBox(width: 4),
                          Text(
                            widget.block.temps!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: headerContentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: headerContentColor,
                  ),
                ],
              ),
            ),
          ),
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

/// TEXTE : Simple et efficace
class TexteBlockWidget extends StatelessWidget {
  final TexteBlock block;

  const TexteBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    // Style par défaut venant du thème (gère le noir/blanc auto)
    TextStyle style = context.textTheme.bodyMedium!.copyWith(height: 1.5);

    if (block.format != null) {
      style = style.copyWith(
        fontWeight: block.format!.gras ? FontWeight.bold : null,
        fontStyle: block.format!.italique ? FontStyle.italic : null,
        decoration: block.format!.souligne ? TextDecoration.underline : null,
        color: block.format!.couleur != null
            ? _parseColor(block.format!.couleur!)
            : null, // Si null, garde la couleur par défaut du thème
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
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// TABLEAU
class TableauBlockWidget extends StatelessWidget {
  final TableauBlock block;

  const TableauBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.titre != null && block.titre!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // Surface légèrement colorée pour le titre
                color: colors.surfaceContainerHighest,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Text(
                block.titre!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              // Header avec couleur adaptative
              headingRowColor: WidgetStateProperty.all(colors.surfaceContainerHigh),
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

/// IMAGE : Optimisé avec compute pour le Base64
class ImageBlockWidget extends StatefulWidget {
  final ImageBlock block;

  const ImageBlockWidget({super.key, required this.block});

  @override
  State<ImageBlockWidget> createState() => _ImageBlockWidgetState();
}

class _ImageBlockWidgetState extends State<ImageBlockWidget> {
  Future<Uint8List>? _imageFuture;

  @override
  void initState() {
    super.initState();
    if (widget.block.estBase64) {
      _imageFuture = compute(base64Decode, widget.block.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.block.estBase64) {
      content = FutureBuilder<Uint8List>(
        future: _imageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            return Image.memory(snapshot.data!, fit: BoxFit.contain);
          } else if (snapshot.hasError) {
            return SizedBox(
              height: 100,
              child: Center(child: Text('Erreur image', style: TextStyle(color: context.colors.error))),
            );
          }
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        },
      );
    } else {
      content = Image.network(
        widget.block.source,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Container(
          padding: const EdgeInsets.all(16),
          color: context.colors.surfaceContainerHighest,
          child: Column(
            children: [
              Icon(Icons.broken_image, color: context.colors.outline),
              const Text('Image introuvable', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SizedBox(
            width: widget.block.largeurPourcent != null
                ? MediaQuery.of(context).size.width * (widget.block.largeurPourcent! / 100)
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: content,
            ),
          ),
          if (widget.block.legende != null && widget.block.legende!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.block.legende!,
                style: context.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

/// MEDICAMENT : Sécurisé et Robuste
class MedicamentBlockWidget extends StatelessWidget {
  final MedicamentBlock block;

  const MedicamentBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    // Sémantique: Alerte (pour erreur) & Calculus (pour affichage dose)
    final alerteColors = context.medicalColors;
    final calculusColors = context.medicalColors;

    return Consumer<WeightProvider>(
      builder: (context, weightProvider, child) {
        final resolver = MedicamentResolver();
        final poids = weightProvider.weight ?? 10.0;
        
        PosologieResolue? posologie;
        String? error;

        try {
          posologie = resolver.resolveMedicament(
            nomMedicament: block.nomMedicament,
            indication: block.indication,
            voie: block.voie,
            poids: poids,
          );
        } catch (e) {
          error = e.toString().replaceAll('Exception:', '').trim();
        }

        // Affichage ERREUR
        if (error != null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: alerteColors.alerteContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: alerteColors.alertePrimary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: alerteColors.alertePrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${block.nomMedicament}: $error',
                    style: TextStyle(color: alerteColors.alerteOnContainer, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        if (posologie == null) return const SizedBox.shrink();

        // Affichage DOSE (Sémantique Calculus/Violet)
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: calculusColors.calculusContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: calculusColors.calculusPrimary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et Voie
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: calculusColors.calculusPrimary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.medication, color: calculusColors.calculusOnContainer, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          posologie.nomMedicament,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: calculusColors.calculusOnContainer, // Contraste fort sur le container
                          ),
                        ),
                        if (posologie.voie.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.surface, // Fond blanc/noir
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: calculusColors.calculusPrimary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              posologie.voie,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: calculusColors.calculusPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dose Calculée (Zone Blanche/Noire pour lisibilité max)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: calculusColors.calculusPrimary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calculate, size: 20, color: calculusColors.calculusPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        posologie.dose,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: calculusColors.calculusPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (posologie.preparation.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.science, size: 16, color: context.colors.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        posologie.preparation,
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (block.commentaire != null && block.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'ℹ️ ${block.commentaire}',
                  style: TextStyle(fontSize: 12, color: calculusColors.calculusOnContainer.withValues(alpha: 0.8)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// FORMULAIRE
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

  @override
  Widget build(BuildContext context) {
    final score = _calculerScore();
    final interpretation = _getInterpretation(score);
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment, color: colors.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.block.titre,
                    style: TextStyle(
                        color: colors.onPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          // Champs
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: widget.block.champs.map((c) => _buildChamp(c)).toList(),
            ),
          ),
          // Résultat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: interpretation != null 
                  ? _getNiveauColor(interpretation.niveau).withValues(alpha: 0.1)
                  : colors.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Score Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$score", 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: interpretation != null ? _getNiveauColor(interpretation.niveau) : colors.onSurface,
                      ),
                    ),
                    if (interpretation != null)
                      Text(interpretation.texte, style: TextStyle(
                        color: _getNiveauColor(interpretation.niveau),
                        fontWeight: FontWeight.w600,
                      )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  FormulaireInterpretation? _getInterpretation(num score) {
    if (widget.block.interpretations == null) return null;
    for (final interp in widget.block.interpretations!) {
      if (score >= interp.min && score <= interp.max) return interp;
    }
    return null;
  }

  // Mappage couleur pour les scores (Utilise les couleurs sémantiques)
  Color _getNiveauColor(String? niveau) {
    switch (niveau) {
      case 'faible': return context.medicalColors.annuairePrimary; // Vert
      case 'modere': return context.medicalColors.protocolPrimary; // Orange
      case 'eleve': return context.medicalColors.alertePrimary; // Rouge
      case 'critique': return context.colors.error; // Rouge vif
      default: return context.colors.primary;
    }
  }
  
  Widget _buildChamp(FormulaireChamp champ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _buildChampContent(champ),
    );
  }
  
  Widget _buildChampContent(FormulaireChamp champ) {
     switch (champ.type) {
      case ChampType.nombre: return _buildNombreUI(champ);
      case ChampType.selection: return _buildSelectUI(champ);
      case ChampType.checkbox: return _buildCheckUI(champ);
      case ChampType.radio: return _buildRadioUI(champ);
    }
  }
  
  Widget _buildNombreUI(FormulaireChamp c) {
    final val = _valeurs[c.id] ?? 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(c.label)),
        Row(
          children: [
            IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _valeurs[c.id] = val - 1)),
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              alignment: Alignment.center,
              child: Text(val.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _valeurs[c.id] = val + 1)),
          ],
        )
      ],
    );
  }
  
  Widget _buildCheckUI(FormulaireChamp c) {
    return CheckboxListTile(
      title: Text(c.label),
      value: _valeurs[c.id] == 1,
      onChanged: (v) => setState(() => _valeurs[c.id] = v == true ? 1 : 0),
    );
  }
  
  // Implémentation basique des Dropdowns pour le support complet
  Widget _buildSelectUI(FormulaireChamp c) {
    if (c.options == null) return const SizedBox();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(c.label)),
        DropdownButton<num>(
          value: _valeurs[c.id],
          items: c.options!.map((o) => DropdownMenuItem(value: o.valeur, child: Text(o.label))).toList(),
          onChanged: (v) => setState(() => _valeurs[c.id] = v ?? 0),
        ),
      ],
    );
  }
  
  Widget _buildRadioUI(FormulaireChamp c) {
     if (c.options == null) return const SizedBox();
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(c.label, style: const TextStyle(fontWeight: FontWeight.bold)),
         ...c.options!.map((o) => RadioListTile<num>(
           title: Text(o.label),
           value: o.valeur,
           groupValue: _valeurs[c.id],
           onChanged: (v) => setState(() => _valeurs[c.id] = v ?? 0),
           dense: true,
         )),
       ],
     );
  }
}

/// ALERTE : Mappage sémantique
class AlerteBlockWidget extends StatelessWidget {
  final AlerteBlock block;

  const AlerteBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    Color bg, border, text;
    IconData icon;
    final medColors = context.medicalColors;

    switch (block.niveau) {
      case AlerteNiveau.info:
        bg = context.colors.surfaceContainer; 
        border = context.colors.primary; 
        text = context.colors.onSurface; 
        icon = Icons.info;
        break;
      case AlerteNiveau.attention:
        bg = medColors.protocolContainer; 
        border = medColors.protocolPrimary; 
        text = medColors.protocolOnContainer; 
        icon = Icons.warning;
        break;
      case AlerteNiveau.danger:
        bg = medColors.alerteContainer; 
        border = medColors.alertePrimary; 
        text = medColors.alerteOnContainer; 
        icon = Icons.error;
        break;
      case AlerteNiveau.critique:
        bg = context.colors.errorContainer; 
        border = context.colors.error; 
        text = context.colors.onErrorContainer; 
        icon = Icons.dangerous;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border(left: BorderSide(color: border, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: border),
          const SizedBox(width: 12),
          Expanded(child: Text(block.contenu, style: TextStyle(color: text, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}