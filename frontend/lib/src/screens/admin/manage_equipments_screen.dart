import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../models/plan_model.dart';

class ManageEquipmentsScreen extends StatefulWidget {
  const ManageEquipmentsScreen({super.key});

  @override
  State<ManageEquipmentsScreen> createState() => _ManageEquipmentsScreenState();
}

class _ManageEquipmentsScreenState extends State<ManageEquipmentsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<Equipment> _equipments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEquipments();
  }

  Future<void> _loadEquipments() async {
    setState(() {
       _isLoading = true;
       _error = null;
    });
    try {
      final eqs = await _apiClient.getEquipments();
      setState(() {
        _equipments = eqs;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addEquipment(String name) async {
      try {
          await _apiClient.createEquipment(name);
          _loadEquipments();
          if (mounted) Navigator.pop(context);
      } catch(e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
  }

  Future<void> _deleteEquipment(Equipment eq) async {
       if (!eq.isEditable) return;
       try {
           final confirm = await showDialog<bool>(
               context: context,
               builder: (ctx) => AlertDialog(
                   title: const Text('Eliminar Equipamiento'),
                   content: Text('¿Seguro que quieres eliminar "${eq.name}"?'),
                   actions: [
                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                       TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                   ],
               )
           );

           if (confirm == true) {
               await _apiClient.deleteEquipment(eq.id);
               _loadEquipments();
           }
       } catch(e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
       }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar Equipamiento'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _error != null 
          ? Center(child: Text('Error: $_error'))
          : ListView.separated(
              itemCount: _equipments.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final eq = _equipments[index];
                return ListTile(
                  leading: Icon(eq.isBodyWeight ? Icons.person : Icons.fitness_center),
                  title: Text(eq.name),
                  subtitle: eq.isBodyWeight ? const Text('Sistema (Automático)') : null,
                  trailing: eq.isEditable 
                    ? IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEquipment(eq),
                      )
                    : const Icon(Icons.lock, color: Colors.grey),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
              showDialog(context: context, builder: (ctx) {
                  final ctrl = TextEditingController();
                  return AlertDialog(
                      title: const Text('Nuevo Equipamiento'),
                      content: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(labelText: 'Nombre'),
                          textCapitalization: TextCapitalization.sentences,
                      ),
                      actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                          ElevatedButton(onPressed: () {
                              if (ctrl.text.isNotEmpty) _addEquipment(ctrl.text);
                          }, child: const Text('Crear')),
                      ],
                  );
              });
          },
          child: const Icon(Icons.add),
      ),
    );
  }
}
