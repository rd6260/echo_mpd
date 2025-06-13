import 'package:echo_mpd/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

class ConnectionForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController ipController;
  final TextEditingController portController;

  const ConnectionForm({
    super.key,
    required this.formKey,
    required this.ipController,
    required this.portController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: ipController,
            labelText: 'IP Address',
            hintText: '192.168.1.100',
            prefixIcon: Icons.router,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter IP address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: portController,
            labelText: 'Port',
            hintText: '6600',
            prefixIcon: Icons.lan,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter port number';
              }
              final port = int.tryParse(value.trim());
              if (port == null || port < 1 || port > 65535) {
                return 'Please enter a valid port (1-65535)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
