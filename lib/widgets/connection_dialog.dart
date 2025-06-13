import 'package:echo_mpd/widgets/connection_form.dart';
import 'package:echo_mpd/widgets/dialog_buttons.dart';
import 'package:echo_mpd/widgets/dialog_header.dart';
import 'package:flutter/material.dart';

class ConnectionDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ipController;
  final TextEditingController portController;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onCancel;

  const ConnectionDialog({
    super.key,
    required this.formKey,
    required this.ipController,
    required this.portController,
    required this.isConnecting,
    required this.onConnect,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF333333), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DialogHeader(),
            const SizedBox(height: 24),
            ConnectionForm(
              formKey: formKey,
              ipController: ipController,
              portController: portController,
            ),
            const SizedBox(height: 24),
            DialogButtons(
              isConnecting: isConnecting,
              onConnect: onConnect,
              onCancel: onCancel,
            ),
          ],
        ),
      ),
    );
  }
}
