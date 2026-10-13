import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/queue_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Charger les clés depuis le fichier .env
  await dotenv.load(fileName: ".env");

  // Initialiser Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Connexion anonyme (seulement si pas déjà connecté)
  final auth = Supabase.instance.client.auth;
  if (auth.currentSession == null) {
    try {
      final res = await auth.signInAnonymously();
      print('Signed in anonymously as user: ${res.user?.id}');
    } catch (e) {
      print('Failed to sign in: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Waiting Room', home: const WaitingRoomScreen());
  }
}

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final TextEditingController controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _addClient() {
    if (controller.text.trim().isNotEmpty) {
      context.read<QueueProvider>().addClient(controller.text);
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = context.watch<QueueProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Waiting Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                    onSubmitted: (_) => _addClient(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addClient, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('nextClientButton'),
              onPressed: () {
                context.read<QueueProvider>().nextClient();
              },
              icon: const Icon(Icons.skip_next),
              label: const Text('Next Client'),
            ),
            const SizedBox(height: 16),
            Text('Clients in Queue: ${queueProvider.clients.length}'),
            Expanded(
              child: ListView.builder(
                itemCount: queueProvider.clients.length,
                itemBuilder: (context, index) {
                  final client = queueProvider.clients[index];
                  return Card(
                    child: ListTile(
                      title: Text(client.name),
                      subtitle: Text(
                        client.createdAt.toLocal().toString().split('.')[0],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<QueueProvider>().removeClient(client.id);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
