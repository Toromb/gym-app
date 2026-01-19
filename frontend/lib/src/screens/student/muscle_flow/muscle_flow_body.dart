import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../../models/stats_model.dart';
import 'muscle_flow_utils.dart';
import 'package:xml/xml.dart';

class MuscleFlowBody extends StatefulWidget {
  final List<MuscleLoad> loads;

  const MuscleFlowBody({super.key, required this.loads});

  @override
  State<MuscleFlowBody> createState() => _MuscleFlowBodyState();
}

class _MuscleFlowBodyState extends State<MuscleFlowBody> {
  bool _isFront = true;
  String? _svgStringFront;
  String? _svgStringBack;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSvgs();
  }

  Future<void> _loadSvgs() async {
    try {
      final f = await rootBundle.loadString('assets/body_front.svg');
      final b = await rootBundle.loadString('assets/body_back.svg');
      if (mounted) {
        setState(() {
          _svgStringFront = f;
          _svgStringBack = b;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading SVGs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  String _processSvg(String rawSvg) {
    if (rawSvg.isEmpty) return rawSvg;
    try {
      if (!rawSvg.trim().startsWith('<')) {
        return rawSvg;
      }
      final document = XmlDocument.parse(rawSvg);

      for (var load in widget.loads) {
        final svgId = MuscleFlowUtils.mapMuscleToSvgId(load.muscleName);
        final colorHex = _colorToHex(MuscleFlowUtils.getColor(load.load));

        // Find elements with the matching ID
        final elements = document.findAllElements('*').where((element) => element.getAttribute('id') == svgId);
        
        if (elements.isEmpty) continue;
        
        for (var element in elements) {
          // Force apply to all descendant paths (or rect/circle/etc if needed)
          // This bypasses inheritance issues by painting the leaves directly.
          final paths = element.descendants.whereType<XmlElement>().where((node) => 
              node.name.local == 'path' || 
              node.name.local == 'rect' || 
              node.name.local == 'circle' || 
              node.name.local == 'ellipse' || 
              node.name.local == 'polygon' ||
              node.name.local == 'polyline'
          ).toList();

          if (paths.isEmpty && (element.name.local == 'path')) {
             paths.add(element);
          }

          if (paths.isEmpty) {
             // Fallback: Just set it on the element (e.g. it is a path itself, or empty group)
             element.setAttribute('fill', colorHex);
             element.removeAttribute('style');
          } else {
             for (var path in paths) {
                path.setAttribute('fill', colorHex);
                path.removeAttribute('style'); // Nuke conflicting styles
             }
          }
        }
      }
      return document.toXmlString();
    } catch (e) {
      debugPrint('Error processing SVG: $e');
      return rawSvg; // Fallback to raw string to ensure visibility
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    final rawSvg = _isFront ? _svgStringFront : _svgStringBack;

    // Safety check for null rawSvg
    if (rawSvg == null) {
       return const SizedBox(height: 300, child: Center(child: Text('Error: SVG not loaded')));
    }

    // Process safely
    final processedSvg = _processSvg(rawSvg);

    return Column(
      children: [
        // Toggle
        ToggleButtons(
          isSelected: [_isFront, !_isFront],
          onPressed: (idx) {
            setState(() {
              _isFront = idx == 0;
            });
          },
          borderRadius: BorderRadius.circular(20),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 80),
          children: const [
            Text('Frente'),
            Text('Espalda'),
          ],
        ),
        const SizedBox(height: 16),
        
        // Heatmap Render
        Center(
          child: SizedBox(
            height: 280, // Smaller Fixed height
            child: SvgPicture.string(
              processedSvg, 
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

