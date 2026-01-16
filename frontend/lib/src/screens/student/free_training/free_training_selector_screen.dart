import 'package:flutter/material.dart';
import '../../../models/free_training_model.dart';
import '../../../services/free_training_service.dart';
import '../../shared/day_detail_screen.dart';
import '../../../models/plan_model.dart'; // For DayDetailScreen if needed

class FreeTrainingSelectorScreen extends StatefulWidget {
  final bool isAdminMode;
  final Function(FreeTraining)? onTrainingSelected; // For Admin "Edit" or generic selection
  
  const FreeTrainingSelectorScreen({
      super.key, 
      this.isAdminMode = false,
      this.onTrainingSelected,
  });

  @override
  State<FreeTrainingSelectorScreen> createState() => _FreeTrainingSelectorScreenState();
}

class _FreeTrainingSelectorScreenState extends State<FreeTrainingSelectorScreen> {
  final FreeTrainingService _service = FreeTrainingService();
  
  // Selections
  FreeTrainingType? _selectedType;
  TrainingLevel? _selectedLevel;
  BodySector? _selectedSector;
  CardioLevel? _selectedCardioLevel;

  // UI State
  // Steps: 0=Type, 1=Level, 2=Sector, 3=Cardio, 4=Results
  int _currentStep = 0;
  List<FreeTraining>? _results;
  bool _isLoading = false;
  
  // Page Controller for smooth transitions
  final PageController _pageController = PageController();

  Future<void> _search() async {
       setState(() => _isLoading = true);
      try {
          final results = await _service.getFreeTrainings(
              type: _selectedType != null ? _toBackendFormat(_selectedType!) : null,
              level: _selectedLevel != null ? _toBackendFormat(_selectedLevel!) : null,
              sector: _selectedSector != null ? _toBackendFormat(_selectedSector!) : null,
              cardioLevel: _selectedCardioLevel != null ? _toBackendFormat(_selectedCardioLevel!) : null,
          );
          setState(() {
             _results = results;
             _currentStep = 4; // Jump to Results
          });
          _pageController.animateToPage(4, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      } catch (e) {
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  void _nextPage() {
    int next = _currentStep + 1;
    
    // Logic to skip steps based on Type
    if (_currentStep == 1) { // Coming from Level
        if (_selectedType == FreeTrainingType.cardio) {
            // Cardio: Skip Sector (2) & CardioLevel (3) -> Search & Results (4)
            _search();
            return;
        }
        if (_selectedType == FreeTrainingType.musculacion || _selectedType == FreeTrainingType.funcional) {
             // Musc/Func: Go to Sector (2).
             next = 2;
        }
        if (_selectedType == FreeTrainingType.musculacionCardio) {
             // Hybrid: Go to Sector (2).
             next = 2;
        }
    } else if (_currentStep == 2) { // Coming from Sector
        if (_selectedType == FreeTrainingType.musculacion || _selectedType == FreeTrainingType.funcional) {
             // Musc/Func: Skip Cardio (3) -> Search & Results (4)
             _search();
             return;
        }
        if (_selectedType == FreeTrainingType.musculacionCardio) {
             // Hybrid: Go to Cardio (3).
             next = 3;
        }
    } else if (_currentStep == 3) { // Coming from Cardio
        // Hybrid finished -> Search & Results (4)
        _search();
        return;
    }

    _goToPage(next);
  }

  void _prevPage() {
    int prev = _currentStep - 1;

    // Logic to skip back
    if (_currentStep == 4) { // From Results
        // Re-calculate where we came from
         if (_selectedType == FreeTrainingType.cardio) prev = 1;
         else if (_selectedType == FreeTrainingType.musculacion || _selectedType == FreeTrainingType.funcional) prev = 2;
         else if (_selectedType == FreeTrainingType.musculacionCardio) prev = 3;
    } else if (_currentStep == 3) { // From Cardio
         // Only Hybrid hits this, goes back to Sector (2)
         prev = 2;
    } else if (_currentStep == 2) { // From Sector
         // Hybrid/Musc/Func hit this, go back to Level (1)
         prev = 1;
    }

    if (prev >= 0) {
      _goToPage(prev);
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPage(int page) {
      setState(() => _currentStep = page);
      _pageController.animateToPage(page, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
  
  void _reset() {
      setState(() {
          _selectedType = null;
          _selectedLevel = null;
          _selectedSector = null;
          _selectedCardioLevel = null;
          _currentStep = 0;
          _results = null;
      });
      _pageController.jumpToPage(0);
  }

  String _toBackendFormat(Enum e) {
      if (e is CardioLevel) {
          return 'CARDIO_${e.name.toUpperCase()}';
      }
      
      final name = e.name;
      final buffer = StringBuffer();
      for (int i = 0; i < name.length; i++) {
          final char = name[i];
          if (char == char.toUpperCase() && i > 0) {
              buffer.write('_');
          }
          buffer.write(char.toUpperCase());
      }
      return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Dynamic Title
    String title = '';
    switch(_currentStep) {
        case 0: title = 'TIPO DE ENTRENAMIENTO'; break;
        case 1: title = 'DIFICULTAD'; break;
        case 2: title = 'ZONA CORPORAL'; break;
        case 3: title = 'INTENSIDAD CARDIO'; break;
        case 4: title = 'RESULTADOS'; break;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Custom App Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _prevPage,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                       SizedBox(width: 48, child: _currentStep > 0 ? IconButton(icon: const Icon(Icons.refresh), onPressed: _reset) : null),
                    ],
                  ),
                ),
                
                // Progress Bar (Approximation 0..4)
                LinearProgressIndicator(
                  value: (_currentStep + 1) / 5.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                ),
      
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(), // Disable swipe to enforce flow
                    children: [
                      _buildTypeStep(theme),
                      _buildLevelStep(theme),
                      _buildSectorStep(theme), // Split Step
                      _buildCardioStep(theme), // Split Step
                      _buildResultsStep(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Removed _getStepTitle helper as logic is inline now

  // --- STEP 1: TYPE ---
  Widget _buildTypeStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '¿Qué querés entrenar hoy?',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildSelectionCard(
          theme,
          title: 'MUSCULACIÓN',
          icon: Icons.fitness_center,
          color: Colors.blue.shade700,
          isSelected: _selectedType == FreeTrainingType.musculacion,
          onTap: () {
            setState(() => _selectedType = FreeTrainingType.musculacion);
            _nextPage();
          },
        ),
        const SizedBox(height: 16),
        _buildSelectionCard(
          theme,
          title: 'CARDIO',
          icon: Icons.directions_run,
          color: Colors.orange.shade700,
          isSelected: _selectedType == FreeTrainingType.cardio,
          onTap: () {
            setState(() => _selectedType = FreeTrainingType.cardio);
            _nextPage();
          },
        ),
        const SizedBox(height: 16),
        _buildSelectionCard(
          theme,
          title: 'FUNCIONAL',
          icon: Icons.sports_gymnastics,
          color: Colors.green.shade700,
          isSelected: _selectedType == FreeTrainingType.funcional,
          onTap: () {
            setState(() => _selectedType = FreeTrainingType.funcional);
            _nextPage();
          },
        ),
         const SizedBox(height: 16),
        _buildSelectionCard(
          theme,
          title: 'MUSCULACIÓN Y CARDIO',
          icon: Icons.monitor_heart,
          color: Colors.purple.shade700,
          isSelected: _selectedType == FreeTrainingType.musculacionCardio,
          onTap: () {
            setState(() => _selectedType = FreeTrainingType.musculacionCardio);
            _nextPage();
          },
        ),
      ],
    );
  }

  // --- STEP 2: LEVEL ---
  Widget _buildLevelStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
         Text(
          'Elegí la intensidad',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ...TrainingLevel.values.map((level) {
          Color color;
          IconData icon;
          String sub;
          
          switch(level) {
            case TrainingLevel.inicial: 
              color = Colors.teal; 
              icon = Icons.battery_1_bar; 
              break;
            case TrainingLevel.medio: 
              color = Colors.amber.shade800; 
              icon = Icons.battery_3_bar; 
              break;
            case TrainingLevel.avanzado: 
              color = Colors.red.shade700; 
              icon = Icons.battery_full; 
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSelectionCard(
              theme,
              title: level.name.toUpperCase(),
              icon: icon,
              color: color,
              isSelected: _selectedLevel == level,
              onTap: () {
                 setState(() => _selectedLevel = level);
                 _nextPage();
              },
            ),
          );
        }),
      ],
    );
  }

  // --- STEP 2: BODY SECTOR ---
  Widget _buildSectorStep(ThemeData theme) {
      if (_isLoading) return const Center(child: CircularProgressIndicator());
      
      return ListView(
          padding: const EdgeInsets.all(24),
          children: [
             Text(
              'Zona Corporal',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...BodySector.values.map((s) {
                   final isSelected = _selectedSector == s;
                   // Updated Icons per request
                   Color color;
                   IconData icon;
                   switch(s) {
                       case BodySector.piernas: color = Colors.deepOrange; icon = Icons.directions_walk; break;
                       case BodySector.zonaMedia: color = Colors.pink; icon = Icons.accessibility_new; break; // Abs/Core
                       case BodySector.hombros: color = Colors.indigo; icon = Icons.emoji_people; break; // Shoulders
                       case BodySector.espalda: color = Colors.blue; icon = Icons.rowing; break; // Back -> Rowing is good
                       case BodySector.pecho: color = Colors.red; icon = Icons.shield; break; // Chest -> Shield (Protection/Torso)
                       case BodySector.fullBody: color = Colors.teal; icon = Icons.boy_rounded; break; // Full body
                   }

                   return Padding(
                     padding: const EdgeInsets.only(bottom: 12),
                     child: _buildSelectionCard(
                        theme, 
                        title: s.name.toUpperCase().replaceAll('ZONAMEDIA', 'ZONA MEDIA'),
                        icon: icon,
                        color: color,
                        isSelected: isSelected,
                        onTap: () {
                            setState(() => _selectedSector = s);
                            _nextPage();
                        }
                     ),
                   );
                }).toList(),
          ]
      );
  }

  // --- STEP 3: CARDIO INTENSITY ---
  Widget _buildCardioStep(ThemeData theme) {
      if (_isLoading) return const Center(child: CircularProgressIndicator());

      return ListView(
          padding: const EdgeInsets.all(24),
          children: [
             Text(
              'Intensidad Cardio',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ...CardioLevel.values.map((c) {
                     final isSelected = _selectedCardioLevel == c;
                     Color color;
                     IconData icon;
                     switch(c) {
                         case CardioLevel.inicial: color = Colors.teal; icon = Icons.directions_walk; break;
                         case CardioLevel.medio: color = Colors.amber.shade800; icon = Icons.directions_run; break;
                         case CardioLevel.avanzado: color = Colors.red.shade700; icon = Icons.directions_bike; break;
                     }
                     
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 12),
                       child: _buildSelectionCard(
                           theme,
                           title: c.name.toUpperCase(),
                           icon: icon, 
                           color: color,
                           isSelected: isSelected,
                           onTap: () {
                               setState(() => _selectedCardioLevel = c);
                               _nextPage();
                           }
                       ),
                     );
                }).toList(),
          ]
      );
  }

  // Helper _getSectorIcon removed as it's now inline/unused loop
  // Helper _buildGridOption removed as we reuse _buildSelectionCard

  // --- STEP 4: RESULTS ---
  Widget _buildResultsStep(ThemeData theme) {
      if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
      }
      
      if (_results == null || _results!.isEmpty) {
          return Center(
             child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.search_off, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text('No encontramos rutinas', style: theme.textTheme.titleLarge),
                   const SizedBox(height: 8),
                   const Text('Probá cambiando los filtros.'),
                   const SizedBox(height: 24),
                   FilledButton.tonal(onPressed: _reset, child: const Text('NUEVA BÚSQUEDA'))
                ],
             ),
          );
      }

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
             Text(
              'Resultados',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
             Text(
              '${_results!.length} rutinas encontradas',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ..._results!.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                     if (widget.isAdminMode) {
                        // In Admin mode, tapping could mean "Edit" or we rely on the specific action buttons.
                        // Let's assume Tap = Edit
                        if (widget.onTrainingSelected != null) {
                            widget.onTrainingSelected!(t);
                        }
                     } else {
                        // Student Mode: Start Training
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => DayDetailScreen(
                                readOnly: false,
                                freeTrainingId: t.id,
                                planId: null, 
                                weekNumber: null,
                                day: null, 
                            )
                        ));
                     }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                               padding: const EdgeInsets.all(8),
                               decoration: BoxDecoration(
                                 color: theme.colorScheme.primaryContainer,
                                 borderRadius: BorderRadius.circular(8)
                               ),
                               child: Icon(Icons.fitness_center, color: theme.colorScheme.onPrimaryContainer),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('${t.level.name.toUpperCase()} • ${t.type.name.toUpperCase()}', style: theme.textTheme.bodySmall),
                                ],
                              ),
                            ),
                            if (widget.isAdminMode)
                                IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                                title: const Text('¿Eliminar entrenamiento?'),
                                                content: Text('Se eliminará "${t.name}" permanentemente.'),
                                                actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                                                ],
                                            )
                                        );

                                        if (confirm == true) {
                                            try {
                                                // We can call service directly or callback. 
                                                // Service is easier here but simpler to keep logic isolated? 
                                                // Using service directly.
                                                await _service.deleteFreeTraining(t.id); // Need to implement delete in service!
                                                // Refresh
                                                _search(); 
                                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminado')));
                                            } catch (e) {
                                                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                            }
                                        }
                                    },
                                )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: theme.colorScheme.outlineVariant),
                        const SizedBox(height: 12),
                        Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                               Text('${t.exercises.length} Ejercicios', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                               Text(widget.isAdminMode ? 'EDITAR >' : 'VER RUTINA >', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                           ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            )),
        ],
      );
  }

  Widget _buildSelectionCard(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(16),
         color: isSelected ? color : theme.cardColor,
         border: Border.all(
             color: isSelected ? Colors.transparent : theme.dividerColor.withOpacity(0.1),
             width: 2
         ),
         boxShadow: [
             if (isSelected) 
               BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0,4))
             else
               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0,2))
         ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                    shape: BoxShape.circle
                  ),
                  child: Icon(icon, color: isSelected ? Colors.white : color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : theme.textTheme.titleMedium?.color
                        )
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                         Text(
                          subtitle, 
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected ? Colors.white.withOpacity(0.8) : theme.textTheme.bodySmall?.color
                          )
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.white)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
