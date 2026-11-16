import 'package:material_ui/material_ui.dart';

class ConnectButton extends StatelessWidget {
  final VoidCallback connect;

  const ConnectButton(this.connect, {super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: connect,
        icon: const Icon(Icons.cloud_rounded),
        label: const Text('Connect Dropbox'),
      ),
    );
  }
}
