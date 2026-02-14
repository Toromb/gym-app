import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'TuGymFlow – Términos y Condiciones',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Última actualización: Febrero 2026',
                  style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'TuGymFlow es una plataforma digital orientada a gimnasios y entrenadores registrados. Al utilizar la aplicación, aceptás los siguientes términos:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),

                const _TermSection(
                  title: '1. Uso del servicio',
                  content: 'La plataforma está destinada exclusivamente a gimnasios, entrenadores y alumnos vinculados mediante invitación. No se permite el uso fuera de esta estructura.',
                ),
                const _TermSection(
                  title: '2. Registro y acceso',
                  content: 'El acceso a la aplicación se realiza mediante invitación generada por un gimnasio activo. Los usuarios son responsables de la veracidad de los datos proporcionados.',
                ),
                const _TermSection(
                  title: '3. Responsabilidad del contenido',
                  content: 'TuGymFlow actúa como herramienta de gestión y organización. No brinda asesoramiento médico ni garantiza resultados físicos específicos.',
                ),
                const _TermSection(
                  title: '4. Seguridad',
                  content: 'Cada usuario es responsable de mantener la confidencialidad de sus credenciales de acceso.',
                ),
                const _TermSection(
                  title: '5. Modificaciones',
                  content: 'TuGymFlow podrá actualizar funcionalidades o términos cuando sea necesario para mejorar el servicio.',
                ),
                
                const SizedBox(height: 16),
                const Text(
                  '6. Contacto',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para consultas relacionadas con estos términos:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'cristianvagni87@gmail.com',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver'),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TermSection extends StatelessWidget {
  final String title;
  final String content;

  const _TermSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
        ],
      ),
    );
  }
}
