import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../providers/stats_provider.dart';
import '../../models/stats_model.dart';

class MuscleFlowScreen extends StatefulWidget {
  final String? studentId; // If provided, read-only view for professor

  const MuscleFlowScreen({super.key, this.studentId});

  @override
  State<MuscleFlowScreen> createState() => _MuscleFlowScreenState();
}

class _MuscleFlowScreenState extends State<MuscleFlowScreen> {
  bool _isFront = true;
  bool _isLoading = true;
  List<MuscleLoad> _loads = [];
  String? _svgStringFront;
  String? _svgStringBack;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Load SVGs
    try {
      _svgStringFront = await rootBundle.loadString('assets/body_front.svg');
      _svgStringBack = await rootBundle.loadString('assets/body_back.svg');
    } catch (e) {
      debugPrint('Error loading SVGs: $e');
    }

    // 2. Fetch Data
    if (mounted) {
      final provider = context.read<StatsProvider>();
      if (widget.studentId != null) {
        // Prof View
        _loads = await provider.fetchStudentMuscleLoads(widget.studentId!);
      } else {
        // Student View
        await provider.fetchMyMuscleLoads();
        _loads = provider.myLoads;
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getColor(double load) {
    if (load <= 20) return Colors.greenAccent[400]!; // RECOVERED
    if (load <= 50) return Colors.yellow[600]!; // ACTIVE
    if (load <= 80) return Colors.orange[800]!; // FATIGUED
    return Colors.redAccent[700]!; // OVERLOADED
  }
  
  String _getStatus(double load) {
    if (load <= 20) return 'Recuperado';
    if (load <= 50) return 'Activo';
    if (load <= 80) return 'Fatigado';
    return 'Sobrecarga';
  }

  String _processSvg(String rawSvg) {
    String processed = rawSvg;
    
    // Map backend muscle ID/Names to SVG IDs.
    // Assuming backend returns standard names (English or normalized keys).
    // Or we use a Map if names differ.
    // My created SVG has IDs: chest, abs, obliques, shoulders, biceps, forearms, quads, adductors, calves
    // My created Backend Seeds: Chest, Abs, Obliques, Shoulders, Biceps, Triceps, Forearms, Quads, Hamstrings, Glutes, Calves, Traps, Lats, Lower Back, Adductors, Abductors, Neck, Cardio.
    
    // I need a map: Backend Name -> SVG ID
    final map = {
      'Pecho': 'chest',
      'Abdominales': 'abs',
      'Oblicuos': 'obliques',
      'Deltoides Anterior': 'shoulders', // Front Deltoid
      'Deltoides Posterior': 'shoulders', // Rear Deltoid
      'Bíceps': 'biceps',
      'Tríceps': 'triceps',
      'Antebrazos': 'forearms',
      'Cuádriceps': 'quads',
      'Isquiotibiales': 'hamstrings',
      'Glúteos': 'glutes',
      'Gemelos': 'calves',
      'Trapecios': 'traps', 
      'Trapecio Inferior': 'traps',
      'Dorsales': 'lats',
      'Lumbares': 'lower_back',
      'Aductores': 'adductors',
    };

    for (var load in _loads) {
      final svgId = map[load.muscleName] ?? load.muscleName.toLowerCase();
      final color = _getColor(load.load);
      final colorHex = '#${color.value.toRadixString(16).substring(2)}'; // ARGB -> RRGGBB (substring 2 if Alpha is FF)

      // Regex replace fill
      // Search: id="svgId" ... fill="..."
      // Or simpler: id="svgId" followed by anything until fill="..." replace fill
      // Robust way: Use string replacement specific for my SVG structure where fill="#eee" matches.
      
      // Pattern: id="chest" d="..." fill="#eee"
      // Replace with: id="chest" d="..." fill="color"
      
      // Since order of attributes varies, simple regex:
      // (id="svgId"[^>]*?)fill="[^"]*"
      
      final pattern = RegExp('id="$svgId"([^>]*?)fill="[^"]*"');
      if (pattern.hasMatch(processed)) {
        processed = processed.replaceAllMapped(pattern, (match) {
          return 'id="$svgId"${match.group(1)}fill="$colorHex"';
        });
      }
    }
    return processed;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Sort loads by load desc
    final sortedLoads = List<MuscleLoad>.from(_loads)..sort((a, b) => b.load.compareTo(a.load));

    final svgContent = _isFront ? _svgStringFront : _svgStringBack;
    final processedSvg = svgContent != null ? _processSvg(svgContent) : null;

    return Scaffold(
      appBar: widget.studentId == null ? null : AppBar(title: const Text('Estado Muscular')), // Only show AppBar if pushed solo (Professor)
      body: Column(
        children: [
          // Header (if embedded)
          if (widget.studentId == null)
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text('Estado Muscular', style: Theme.of(context).textTheme.headlineSmall),
             ),
             
          // Toggle
          ToggleButtons(
            isSelected: [_isFront, !_isFront],
            onPressed: (idx) {
              setState(() {
                _isFront = idx == 0;
              });
            },
            borderRadius: BorderRadius.circular(20),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Frente')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text('Espalda')),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Heatmap
          Expanded(
            flex: 2,
            child: processedSvg == null 
              ? const Center(child: Text('SVG Not Found'))
              : SvgPicture.string(processedSvg),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // List
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedLoads.length,
              itemBuilder: (ctx, i) {
                final item = sortedLoads[i];
                return Card(
                  elevation: 0, 
                  color: Colors.transparent,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.muscleName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                             Text('${item.load.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                             const SizedBox(width: 8),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                               decoration: BoxDecoration(
                                 color: _getColor(item.load).withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(12),
                                 border: Border.all(color: _getColor(item.load), width: 1),
                               ),
                               child: Text(_getStatus(item.load), style: TextStyle(
                                 color: _getColor(item.load).withOpacity(1), // Opaque text
                                 fontSize: 12, 
                                 fontWeight: FontWeight.bold
                               )),
                             ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
