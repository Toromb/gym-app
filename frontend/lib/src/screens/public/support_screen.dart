import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Styles from privacy/index.html
    const textColor = Color(0xFF333333);
    const headingColor = Color(0xFF111111);
    const linkColor = Color(0xFF0066CC);
    const borderColor = Color(0xFFEAEAEA);

    return Scaffold(
      backgroundColor: Colors.white, // var(--bg-color)
      appBar: AppBar(
        title: const Text('Soporte'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: headingColor),
        titleTextStyle: const TextStyle(
          color: headingColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700), // max-width: 700px
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // H1
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: const Text(
                    'TuGymFlow – Soporte',
                    style: TextStyle(
                      fontSize: 32, // 2em
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 32), // H2 margin-top

                // Intro
                const Text(
                  'Si necesitás asistencia técnica o tenés consultas sobre la plataforma TuGymFlow, podés contactarnos a:',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: textColor,
                    fontFamily: 'Roboto', // Default but explicit for alignment
                  ),
                ),
                const SizedBox(height: 16),

                // Email Section (Simplifying to match privacy style)
                const Text(
                  'Email de soporte:',
                  style: TextStyle(
                    fontSize: 19, // ~1.2em (H3)
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'cristianvagni87@gmail.com',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: linkColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Response Time (H3 equivalent)
                const SizedBox(height: 24),
                const Text(
                  'Tiempo estimado de respuesta',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Responderemos dentro de 24 a 48 horas hábiles.',
                  style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
                ),

                // Additional Info (H3 equivalent)
                const SizedBox(height: 24),
                const Text(
                  'Información adicional',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'TuGymFlow es una plataforma profesional orientada a gimnasios y entrenadores registrados.\n'
                  'El acceso de alumnos se realiza exclusivamente mediante invitación generada por un gimnasio activo.\n'
                  'No se permite el registro libre dentro de la aplicación.',
                  style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
                ),

                const SizedBox(height: 48),
                const Divider(color: borderColor),
                const SizedBox(height: 32), // H2 margin-top

                // FAQ Section (H2 equivalent)
                const Text(
                  'Preguntas Frecuentes',
                  style: TextStyle(
                    fontSize: 24, // 1.5em
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16), // H2 margin-bottom

                const _FaqItem(
                  question: '1. ¿Puedo crear una cuenta directamente desde la app?',
                  answer: 'No. TuGymFlow está orientada a gimnasios y entrenadores registrados. El acceso se realiza únicamente mediante invitación generada por el administrador del gimnasio.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _FaqItem(
                  question: '2. Soy alumno, ¿cómo obtengo acceso?',
                  answer: 'Debés solicitar el enlace de invitación a tu gimnasio o entrenador. Una vez recibido, podrás registrarte y acceder a tu cuenta.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _FaqItem(
                  question: '3. ¿Qué métodos de inicio de sesión están disponibles?',
                  answer: 'La aplicación permite iniciar sesión mediante:\n'
                          '- Correo electrónico y contraseña\n'
                          '- Google\n'
                          '- Apple\n'
                          'Siempre vinculando la cuenta a un gimnasio activo.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _FaqItem(
                  question: '4. ¿Puedo usar la app si no pertenezco a un gimnasio?',
                  answer: 'No. La plataforma está diseñada para uso interno de gimnasios y sus alumnos registrados.',
                  headingColor: headingColor,
                  textColor: textColor,
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
                      child: const Text(
                        'Política de Privacidad',
                         style: TextStyle(color: linkColor, fontSize: 16),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                         Navigator.of(context).pushNamed('/terminos');
                      },
                      child: const Text(
                        'Términos y Condiciones',
                        style: TextStyle(color: linkColor, fontSize: 16),
                      ),
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

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final Color headingColor;
  final Color textColor;

  const _FaqItem({
    required this.question, 
    required this.answer,
    required this.headingColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 17, // Just slightly bigger/bolder than text, distinct from H3
              fontWeight: FontWeight.w600,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
          ),
        ],
      ),
    );
  }
}
