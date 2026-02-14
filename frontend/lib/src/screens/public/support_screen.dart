import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soporte'),
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
                  'TuGymFlow – Soporte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Main Text
                const Text(
                  'Si necesitás asistencia técnica o tenés consultas sobre la plataforma TuGymFlow, podés contactarnos a:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                
                // Email
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Email de soporte:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'cristianvagni87@gmail.com',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Response Time
                const _InfoSection(
                  title: 'Tiempo estimado de respuesta:',
                  content: 'Responderemos dentro de 24 a 48 horas hábiles.',
                ),
                const SizedBox(height: 24),

                // Additional Info
                const _InfoSection(
                  title: 'Información adicional:',
                  content: 'TuGymFlow es una plataforma profesional orientada a gimnasios y entrenadores registrados.\n'
                           'El acceso de alumnos se realiza exclusivamente mediante invitación generada por un gimnasio activo.\n'
                           'No se permite el registro libre dentro de la aplicación.',
                ),
                
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 32),

                // FAQ Section
                const Text(
                  'Preguntas Frecuentes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                const _FaqItem(
                  question: '1. ¿Puedo crear una cuenta directamente desde la app?',
                  answer: 'No. TuGymFlow está orientada a gimnasios y entrenadores registrados. El acceso se realiza únicamente mediante invitación generada por el administrador del gimnasio.',
                ),
                const _FaqItem(
                  question: '2. Soy alumno, ¿cómo obtengo acceso?',
                  answer: 'Debés solicitar el enlace de invitación a tu gimnasio o entrenador. Una vez recibido, podrás registrarte y acceder a tu cuenta.',
                ),
                const _FaqItem(
                  question: '3. ¿Qué métodos de inicio de sesión están disponibles?',
                  answer: 'La aplicación permite iniciar sesión mediante:\n'
                          '- Correo electrónico y contraseña\n'
                          '- Google\n'
                          '- Apple\n'
                          'Siempre vinculando la cuenta a un gimnasio activo.',
                ),
                const _FaqItem(
                  question: '4. ¿Puedo usar la app si no pertenezco a un gimnasio?',
                  answer: 'No. La plataforma está diseñada para uso interno de gimnasios y sus alumnos registrados.',
                ),

                const SizedBox(height: 48),
                
                // Footer Links
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 10,
                  children: [
                     TextButton(
                      onPressed: () => _launchUrl('https://www.tugymflow.com/privacy/'),
                      child: const Text('Política de Privacidad'),
                    ),
                    TextButton(
                      onPressed: () {
                         Navigator.of(context).pushNamed('/terminos');
                      },
                      child: const Text('Términos y Condiciones'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;

  const _InfoSection({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.blueAccent, // Or primary color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }
}
