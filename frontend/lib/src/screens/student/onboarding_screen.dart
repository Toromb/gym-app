import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding_model.dart';
import '../../utils/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  int _currentPage = 0;
  bool _isLoading = false;

  // --- Form Data ---
  // Step 1: Personal
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String? _gender;


  // Step 2: Experience & Activity
  String? _experience;
  String? _activityLevel;

  // Step 3: Goals
  String? _goal;
  final TextEditingController _goalDetailsController = TextEditingController(); // For Sport/Rehab
  String? _desiredFrequency;

  // Step 4: Injuries & Prefs
  final List<String> _injuries = [];
  final TextEditingController _injuryDetailsController = TextEditingController();
  final TextEditingController _preferencesController = TextEditingController(); // Only optional field

  // Step 4: Mobility
  bool? _canLieDown;
  bool? _canKneel;


  // --- Options ---
  final Map<String, String> _goalOptions = {
    'musculation': 'Musculación',
    'health': 'Salud y bienestar general',
    'cardio': 'Solo cardio / Resistencia',
    'mixed': 'Musculación y cardio (Mixto)',
    'mobility': 'Movilidad y zona media',
    'sport': 'Deportivo (Rendimiento)',
    'rehab': 'Rehabilitación',
  };

  final Map<String, String> _experienceOptions = {
    'none': 'Nunca fui a un gimnasio',
    'less_than_year': 'Entrené y dejé hace menos de 1 año',
    'more_than_year': 'Entrené y dejé hace más de 1 año',
    'current': 'Entrené hasta hace poco',
  };

  final Map<String, String> _activityOptions = {
    'sedentary': 'Sedentario (Casi nada)',
    'light': 'Leve (1-2 veces por semana)',
    'moderate': 'Moderada (3-4 veces por semana)',
    'high': 'Alta (5 o más veces por semana)',
  };

  final Map<String, String> _frequencyOptions = {
    'once_per_week': '1 vez por semana',
    'twice_per_week': '2 veces por semana',
    'three_times_per_week': '3 veces por semana',
    'four_or_more': '4 o más veces por semana',
  };

  final List<String> _injuryOptions = [
    'Ninguna', 'Hombro', 'Rodilla', 'Columna lumbar', 'Columna cervical', 'Tobillos', 'Cadera', 'Muñecas/Antebrazos', 'Mareos/Vértigo'
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalDetailsController.dispose();
    _injuryDetailsController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 4) {
        if (_canLieDown == null || _canKneel == null || _injuries.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor respondé todas las preguntas de salud.')));
             return;
        }
        _submit(); 
        return;
    }

    // Validation per page
    if (_currentPage == 1) {
       if (_phoneController.text.isEmpty || _birthDateController.text.isEmpty || 
           _heightController.text.isEmpty || _weightController.text.isEmpty || _gender == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Todos los campos son obligatorios.')));
           return;
       }
    }
    
    if (_currentPage == 2) {
       if (_experience == null || _activityLevel == null) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor completá todos los campos para continuar.')));
           return;
       }
    }

    if (_currentPage == 3) {
        if (_goal == null || _desiredFrequency == null) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccioná tu objetivo y frecuencia.')));
             return;
        }
        if ((_goal == 'sport' || _goal == 'rehab') && _goalDetailsController.text.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor especificá detalles de tu deporte o lesión.')));
             return;
        }
    }

    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentPage++);
  }
  
  void _prevPage() {
      if (_currentPage > 0) {
        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() => _currentPage--);
      }
  }

  Future<void> _submit() async {
      setState(() => _isLoading = true);
      
      try {
          // Construct DTO
          final dto = CreateOnboardingDto(
              goal: _goal!,
              goalDetails: _goalDetailsController.text.isNotEmpty ? _goalDetailsController.text : null,
              experience: _experience!,
              injuries: _injuries,
              injuryDetails: _injuryDetailsController.text.isNotEmpty ? _injuryDetailsController.text : null,
              activityLevel: _activityLevel!,
              desiredFrequency: _desiredFrequency!,
              preferences: _preferencesController.text.isNotEmpty ? _preferencesController.text : null,
              canLieDown: _canLieDown!,
              canKneel: _canKneel!,
              
              
              phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
              birthDate: _birthDateController.text.isNotEmpty ? _birthDateController.text : null, // Assuming YYYY-MM-DD from picker
              height: double.tryParse(_heightController.text.replaceAll(',', '.')),
              weight: double.tryParse(_weightController.text.replaceAll(',', '.')),
              gender: _gender,
          );

          final onboardingService = OnboardingService(ApiClient());
          await onboardingService.submitOnboarding(dto);

          if (!mounted) return;
          
          // Update AuthProvider
          final authProvider = context.read<AuthProvider>();
          await authProvider.refreshUser(); // Refresh user data to get Gender/Weight
          authProvider.setOnboarded(true);

          // Return Home
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          
      } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
          if (mounted) setState(() => _isLoading = false);
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
             // Progress Indicator
             if (_currentPage > 0) 
                LinearProgressIndicator(
                    value: _currentPage / 4, 
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),

             Expanded(
               child: PageView(
                 controller: _pageController,
                 physics: const NeverScrollableScrollPhysics(), // Disable swipe
                 children: [
                    _buildIntroStep(),
                    _buildPersonalStep(),
                    _buildExperienceStep(),
                    _buildGoalsStep(),
                    _buildInjuriesStep(),
                 ],
               ),
             ),
             
             // Navigation Buttons
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   if (_currentPage > 0)
                     TextButton(onPressed: _isLoading ? null : _prevPage, child: const Text('Atrás')),
                   if (_currentPage == 0) const Spacer(),
                   
                   FilledButton(
                     onPressed: _isLoading ? null : _nextPage,
                     child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_currentPage == 4 ? 'Finalizar' : 'Siguiente'),
                   )
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroStep() {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             const Icon(Icons.waving_hand, size: 80, color: Colors.orange), // Friendly icon
             const SizedBox(height: 32),
             Text(
               '¡Hola! Antes de empezar...', 
               style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 16),
             Text(
               'Necesitamos conocerte un poco mejor para personalizar tu experiencia en el gimnasio.',
               style: Theme.of(context).textTheme.bodyLarge,
               textAlign: TextAlign.center,
             ),
             const SizedBox(height: 24),
             const Text(
               'Te haremos unas preguntas breves sobre tus objetivos y experiencia. Solo tomará un minuto.',
               style: TextStyle(color: Colors.grey),
               textAlign: TextAlign.center,
             ),
          ],
        ),
      );
  }

  Widget _buildPersonalStep() {
      // Step 1: Phone, Birth, Weight, Height
      return SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text('Datos Básicos', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono / WhatsApp', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _birthDateController,
                readOnly: true,
                decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento', 
                    prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                    DateTime? picked = await showDatePicker(
                        context: context, 
                        initialDate: DateTime(2000), 
                        firstDate: DateTime(1900), 
                        lastDate: DateTime.now()
                    );
                    if (picked != null) {
                        _birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
                    }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                    Expanded(
                        child: TextField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Altura (cm)', suffixText: 'cm'),
                        )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Peso Inicial (kg)', suffixText: 'kg'),
                        )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                        child: DropdownButtonFormField<String>(
                            value: _gender,
                            decoration: const InputDecoration(labelText: 'Género'),
                            items: const [
                                DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
                                DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
                                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                            ],
                            onChanged: (val) => setState(() => _gender = val),
                        ),
                    ),
                ],
              ),

           ],
         ),
      );
  }

  Widget _buildExperienceStep() {
      // Step 2: Experience & Activity
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text('Experiencia', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                
                const Text('¿Cuál es tu experiencia previa en gimnasios?', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._experienceOptions.entries.map((e) => RadioListTile<String>(
                    title: Text(e.value),
                    value: e.key,
                    groupValue: _experience,
                    onChanged: (val) => setState(() => _experience = val),
                )),
                
                const SizedBox(height: 24),
                const Text('Nivel de actividad física actual', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._activityOptions.entries.map((e) => RadioListTile<String>(
                    title: Text(e.value),
                    value: e.key,
                    groupValue: _activityLevel,
                    onChanged: (val) => setState(() => _activityLevel = val),
                    contentPadding: EdgeInsets.zero,
                )),
             ],
          ),
      );
  }

  Widget _buildGoalsStep() {
      // Step 3: Goals & Frequency
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('Objetivos', style: Theme.of(context).textTheme.headlineSmall),
                 const SizedBox(height: 24),

                 const Text('¿Cuál es tu objetivo principal?', style: TextStyle(fontWeight: FontWeight.bold)),
                 ..._goalOptions.entries.map((e) => RadioListTile<String>(
                    title: Text(e.value),
                    value: e.key,
                    groupValue: _goal,
                    onChanged: (val) => setState(() => _goal = val),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                 )),
                 
                 if (_goal == 'sport' || _goal == 'rehab')
                     Padding(
                       padding: const EdgeInsets.only(left: 16, top: 0, bottom: 16),
                       child: TextField(
                         controller: _goalDetailsController,
                         decoration: InputDecoration(
                             labelText: _goal == 'sport' ? '¿Qué deporte?' : '¿Qué lesión?',
                             border: const OutlineInputBorder()
                         ),
                       ),
                     ),

                 const SizedBox(height: 24),
                 const Text('¿Con qué frecuencia planeas entrenar?', style: TextStyle(fontWeight: FontWeight.bold)),
                 Wrap(
                    spacing: 8,
                    children: _frequencyOptions.entries.map((e) {
                        final selected = _desiredFrequency == e.key;
                        return ChoiceChip(
                            label: Text(e.value),
                            selected: selected,
                            onSelected: (val) => setState(() => _desiredFrequency = val ? e.key : null),
                        );
                    }).toList(),
                 ),
              ],
          ),
      );
  }

  Widget _buildInjuriesStep() {
      // Step 4
      return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('Salud y Preferencias', style: Theme.of(context).textTheme.headlineSmall),
                 const SizedBox(height: 24),
                 
                 const Text('¿Tenés lesiones o molestias?', style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _injuryOptions.map((injury) {
                        final isSelected = _injuries.contains(injury);
                        return FilterChip(
                            label: Text(injury),
                            selected: isSelected,
                            onSelected: (val) {
                                setState(() {
                                    if (injury == 'Ninguna') {
                                        _injuries.clear();
                                        if (val) _injuries.add('Ninguna');
                                    } else {
                                        _injuries.remove('Ninguna'); 
                                        if (val) _injuries.add(injury);
                                        else _injuries.remove(injury);
                                    }
                                });
                            },
                        );
                    }).toList(),
                 ),
                 
                 if (_injuries.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     TextField(
                         controller: _injuryDetailsController,
                         decoration: const InputDecoration(
                             labelText: 'Detalles (opcional)',
                             hintText: 'Lado afectado, dolor actual...',
                             border: OutlineInputBorder()
                         ),
                         maxLines: 2,
                     ),
                 ],
                 
                  const SizedBox(height: 24),
                 const Text('¿Puede recostarse y levantarse por sus propios medios?', style: TextStyle(fontWeight: FontWeight.bold)),
                 Row(
                     children: [
                         Expanded(child: RadioListTile<bool>(title: const Text('Sí'), value: true, groupValue: _canLieDown, onChanged: (v) => setState(() => _canLieDown = v))),
                         Expanded(child: RadioListTile<bool>(title: const Text('No'), value: false, groupValue: _canLieDown, onChanged: (v) => setState(() => _canLieDown = v))),
                     ],
                 ),

                 const Text('¿Puede arrodillarse y levantarse por sus propios medios?', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                     children: [
                         Expanded(child: RadioListTile<bool>(title: const Text('Sí'), value: true, groupValue: _canKneel, onChanged: (v) => setState(() => _canKneel = v))),
                         Expanded(child: RadioListTile<bool>(title: const Text('No'), value: false, groupValue: _canKneel, onChanged: (v) => setState(() => _canKneel = v))),
                     ],
                 ),
                 
                 const SizedBox(height: 32),
                 const Text('¿Algo más que debamos saber?', style: TextStyle(fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 TextField(
                     controller: _preferencesController,
                     decoration: const InputDecoration(
                         hintText: 'Ej: Ejercicios prohibidos, miedos, preferencias...',
                         border: OutlineInputBorder()
                     ),
                     maxLines: 3,
                 ),
              ],
          ),
      );
  }
}
