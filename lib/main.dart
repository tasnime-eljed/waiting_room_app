import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() {
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
    return MaterialApp(home: const WaitingRoomScreen());
  }
}

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // watch permet d'écouter les changements du QueueProvider.
    // Quand notifyListeners() est appelé, l'interface se reconstruit.
    final queueProvider = context.watch<QueueProvider>();

    // Controller du champ de texte.
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Local Waiting Room')),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ de saisie + bouton Add
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Client Name'),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      context.read<QueueProvider>().addClient(controller.text);

                      controller.clear();
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Bouton Next Client
            ElevatedButton.icon(
              key: const Key('nextClientButton'),
              onPressed: () {
                context.read<QueueProvider>().nextClient();
              },
              icon: const Icon(Icons.skip_next),
              label: const Text('Next Client'),
            ),

            const SizedBox(height: 16),

            // Nombre de clients dans la file
            Text('Clients in Queue: ${queueProvider.clients.length}'),

            // Liste des clients
            Expanded(
              child: ListView.builder(
                itemCount: queueProvider.clients.length,
                itemBuilder: (context, index) {
                  final clientName = queueProvider.clients[index];

                  return Card(
                    child: ListTile(
                      title: Text(clientName),

                      // Bouton supprimer
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<QueueProvider>().removeClient(
                            clientName,
                          );
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
