import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/queue_provider.dart';

const supabaseUrl = 'https://swccmnemljwtbxcdspqf.supabase.co';
const supabaseAnonKey = 'sb_publishable_D0JU4M4Ej4p1RThA1ICtGA_sCzu_nrM';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    ChangeNotifierProvider(
      create: (_) =>
          QueueProvider(supabase: Supabase.instance.client)..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'Waiting Room', home: WaitingRoomScreen());
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    context.read<QueueProvider>().addClient(name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QueueProvider>();
    final clients = provider.clients;

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Client name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Text(
            'Clients in Queue: ${clients.length}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: clients.length,
              itemBuilder: (context, index) {
                final client = clients[index];
                final synced = client['is_synced'] == 1;
                return ListTile(
                  leading: Icon(
                    synced ? Icons.cloud_done : Icons.cloud_off,
                    color: synced ? Colors.green : Colors.orange,
                  ),
                  title: Text(client['name'] as String),
                  subtitle: Text(
                    client['lat'] == null
                        ? '📍 Location not captured'
                        : '📍 ${(client['lat'] as num).toStringAsFixed(4)}, '
                              '${(client['lng'] as num).toStringAsFixed(4)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => context.read<QueueProvider>().deleteClient(
                      client['id'] as String,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<QueueProvider>().serveNext(),
        child: const Icon(Icons.skip_next),
      ),
    );
  }
}
