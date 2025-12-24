import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gyms_provider.dart';
import 'manage_gym_screen.dart';

class GymsListScreen extends StatefulWidget {
  const GymsListScreen({super.key});

  @override
  State<GymsListScreen> createState() => _GymsListScreenState();
}

class _GymsListScreenState extends State<GymsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GymsProvider>().fetchGyms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Gyms'),
        actions: [
            IconButton(icon: const Icon(Icons.add), onPressed: (){
                Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => const ManageGymScreen())
                );
            })
        ],
      ),
      body: Consumer<GymsProvider>(
          builder: (context, provider, child) {
              if (provider.isLoading) return const Center(child: CircularProgressIndicator());
              if (provider.error != null) return Center(child: Text('Error: ${provider.error}'));
              
              return ListView.builder(
                  itemCount: provider.gyms.length,
                  itemBuilder: (context, index) {
                      final gym = provider.gyms[index];
                      return ListTile(
                          title: Text(gym.businessName),
                          subtitle: Text('Status: ${gym.status} | Profiles: ${gym.maxProfiles}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (_) => ManageGymScreen(gym: gym))
                              );
                          },
                      );
                  },
              );
          },
      ),
    );
  }
}
