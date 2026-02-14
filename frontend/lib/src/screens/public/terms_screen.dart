import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Styles from privacy/index.html
    const textColor = Color(0xFF333333);
    const headingColor = Color(0xFF111111);
    const linkColor = Color(0xFF0066CC);
    const borderColor = Color(0xFFEAEAEA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
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
          constraints: const BoxConstraints(maxWidth: 700),
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
                    'TuGymFlow – Términos y Condiciones',
                    style: TextStyle(
                      fontSize: 32, // 2em
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Última actualización: Febrero 2026',
                  style: TextStyle(
                     color: textColor,
                     fontWeight: FontWeight.bold,
                     fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'TuGymFlow es una plataforma digital orientada a gimnasios y entrenadores registrados. Al utilizar la aplicación, aceptás los siguientes términos:',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: textColor,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 24),

                const _TermSection(
                  title: '1. Uso del servicio',
                  content: 'La plataforma está destinada exclusivamente a gimnasios, entrenadores y alumnos vinculados mediante invitación. No se permite el uso fuera de esta estructura.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _TermSection(
                  title: '2. Registro y acceso',
                  content: 'El acceso a la aplicación se realiza mediante invitación generada por un gimnasio activo. Los usuarios son responsables de la veracidad de los datos proporcionados.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _TermSection(
                  title: '3. Responsabilidad del contenido',
                  content: 'TuGymFlow actúa como herramienta de gestión y organización. No brinda asesoramiento médico ni garantiza resultados físicos específicos.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _TermSection(
                  title: '4. Seguridad',
                  content: 'Cada usuario es responsable de mantener la confidencialidad de sus credenciales de acceso.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                const _TermSection(
                  title: '5. Modificaciones',
                  content: 'TuGymFlow podrá actualizar funcionalidades o términos cuando sea necesario para mejorar el servicio.',
                  headingColor: headingColor,
                  textColor: textColor,
                ),
                
                const SizedBox(height: 32), // H2 margin-top
                const Text(
                  '6. Contacto',
                  style: TextStyle(
                    fontSize: 24, // 1.5em (H2)
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16), // H2 margin-bottom

                const Text(
                  'Para consultas relacionadas con estos términos:',
                  style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
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
                
                const SizedBox(height: 48),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: linkColor,
                      elevation: 0,
                      side: const BorderSide(color: borderColor),
                    ),
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
  final Color headingColor;
  final Color textColor;

  const _TermSection({
    required this.title, 
    required this.content,
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
            title,
            style: TextStyle(
              fontSize: 24, // H2 style for numbered sections
              fontWeight: FontWeight.bold,
              color: headingColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(fontSize: 16, height: 1.6, color: textColor),
          ),
        ],
      ),
    );
  }
}
