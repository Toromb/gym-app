import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../providers/theme_provider.dart';
import 'package:intl/intl.dart';

class SuperAdminLeadsScreen extends StatefulWidget {
  const SuperAdminLeadsScreen({super.key});

  @override
  _SuperAdminLeadsScreenState createState() => _SuperAdminLeadsScreenState();
}

class _SuperAdminLeadsScreenState extends State<SuperAdminLeadsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _leads = [];

  // Paginación futura scaffolding
  int _currentPage = 1;
  final int _limit = 50;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results =
          await _apiClient.getGymLeads(page: _currentPage, limit: _limit);

      // La API devuelve ordenados por createdAt descendente por default
      setState(() {
        _leads = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'No se pudieron cargar los leads comerciales: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Hubo un error inesperado.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchLeads,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.grey[400], size: 80),
            const SizedBox(height: 16),
            Text(
              'Aún no hay leads de gimnasios',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Los administradores que soliciten información desde el formulario público aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchLeads,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar panel'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) =>
                isDark ? Colors.grey[900] : Colors.blue[50],
          ),
          columns: const [
            DataColumn(
                label: Text('Fecha',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Nombre',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Gimnasio',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Email',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Ciudad',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Alumnos',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Origen',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(
                label: Text('Mensaje',
                    style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _leads.map((lead) {
            return DataRow(
              cells: [
                DataCell(Text(_formatDate(lead['createdAt'] ?? ''))),
                DataCell(Text(lead['fullName'] ?? '-')),
                DataCell(Text(lead['gymName'] ?? '-')),
                DataCell(SelectableText(lead['email'] ?? '-')),
                DataCell(SelectableText(lead['phone'] ?? '-')),
                DataCell(Text(lead['city'] ?? '-')),
                DataCell(Text(lead['studentsCount']?.toString() ?? '-')),
                DataCell(
                  Chip(
                    label: Text(
                      lead['source'] == 'mobile_app' ? 'Mobile App' : 'Web App',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: lead['source'] == 'mobile_app'
                        ? Colors.purple[100]
                        : Colors.blue[100],
                    side: BorderSide.none,
                  ),
                ),
                DataCell(
                  Container(
                    width: 200, // Limit width of message column
                    child: Tooltip(
                      message: lead['message'] ?? 'Sin mensaje',
                      child: Text(
                        lead['message'] ?? '-',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList(bool isDark) {
    return ListView.builder(
      itemCount: _leads.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final lead = _leads[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        lead['gymName'] ?? '-',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: lead['source'] == 'mobile_app'
                            ? (isDark ? Colors.purple[900] : Colors.purple[100])
                            : (isDark ? Colors.blue[900] : Colors.blue[100]),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead['source'] == 'mobile_app'
                            ? 'Mobile App'
                            : 'Web App',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: lead['source'] == 'mobile_app'
                              ? (isDark
                                  ? Colors.purple[100]
                                  : Colors.purple[900])
                              : (isDark ? Colors.blue[100] : Colors.blue[900]),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('👤 ${lead['fullName'] ?? '-'}',
                    style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.grey[300] : Colors.grey[800])),
                const SizedBox(height: 4),
                Text('📍 ${lead['city'] ?? '-'}',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700])),
                const SizedBox(height: 4),
                Text('👥 Alumnos aprox: ${lead['studentsCount'] ?? '-'}',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[700])),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                SelectableText('✉️ ${lead['email'] ?? '-'}',
                    style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 4),
                SelectableText('📞 ${lead['phone'] ?? '-'}',
                    style: const TextStyle(fontSize: 14)),
                if (lead['message'] != null &&
                    lead['message'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💬 "${lead['message']}"',
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: isDark ? Colors.grey[300] : Colors.grey[800]),
                    ),
                  )
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatDate(lead['createdAt'] ?? ''),
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final isDesktop =
        MediaQuery.of(context).size.width > 800; // Responsive breakpoint

    Widget bodyContent;

    if (_isLoading) {
      bodyContent = _buildLoadingState();
    } else if (_errorMessage != null) {
      bodyContent = _buildErrorState();
    } else if (_leads.isEmpty) {
      bodyContent = _buildEmptyState();
    } else {
      // Content loaded
      bodyContent =
          isDesktop ? _buildDesktopTable(isDark) : _buildMobileList(isDark);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leads Comerciales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: () {
              _fetchLeads();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLeads,
        child: bodyContent,
      ),
    );
  }
}
