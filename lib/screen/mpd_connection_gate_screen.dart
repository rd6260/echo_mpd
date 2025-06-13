// main_screen.dart
import 'package:echo_mpd/screen/main_screen.dart';
import 'package:echo_mpd/service/mpd_remote_service.dart';
import 'package:echo_mpd/widgets/connecting_state_widget.dart';
import 'package:echo_mpd/widgets/connection_dialog.dart';
import 'package:echo_mpd/widgets/error_overlay_widget.dart';
import 'package:echo_mpd/widgets/idle_state_widget.dart';
import 'package:echo_mpd/widgets/loading_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MpdConnectionGateScreen extends StatefulWidget {
  const MpdConnectionGateScreen({super.key});

  @override
  State<MpdConnectionGateScreen> createState() =>
      _MpdConnectionGateScreenState();
}

class _MpdConnectionGateScreenState extends State<MpdConnectionGateScreen>
    with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(
    text: '6600',
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isConnecting = false;
  bool _showConnectionError = false;
  bool _isInitializing = true;
  String _errorMessage = '';

  late AnimationController _pulseController;
  late AnimationController _errorController;
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAndConnect();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _errorController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _errorController.dispose();
    _loadingController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('mpd_ip');
    final savedPort = prefs.getInt('mpd_port');

    if (savedIp != null &&
        savedIp.isNotEmpty &&
        savedPort != null &&
        savedPort > 0) {
      await _attemptAutoConnect(savedIp, savedPort);
    } else {
      setState(() => _isInitializing = false);
      await Future.delayed(const Duration(milliseconds: 500));
      _showConnectionDialog();
    }
  }

  Future<void> _attemptAutoConnect(String ip, int port) async {
    setState(() {
      _ipController.text = ip;
      _portController.text = port.toString();
      _isConnecting = true;
      _isInitializing = false;
    });

    try {
      await MpdRemoteService.instance.initialize(host: ip, port: port);
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  Future<void> _attemptConnection() async {
    if (!_formKey.currentState!.validate()) return;

    final host = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());

    if (port == null || port < 1 || port > 65535) {
      _showError('Please enter a valid port number (1-65535)');
      return;
    }

    setState(() {
      _isConnecting = true;
      _showConnectionError = false;
      _errorMessage = '';
    });

    try {
      await _saveConnectionSettings();
      await MpdRemoteService.instance.initialize(host: host, port: port);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      _handleConnectionError(e);
    }
  }

  Future<void> _saveConnectionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mpd_ip', _ipController.text);
    await prefs.setInt('mpd_port', int.parse(_portController.text));
  }

  void _handleConnectionError(dynamic error) {
    debugPrint('MPD connection failed: $error');
    setState(() {
      _isConnecting = false;
      _showConnectionError = true;
      _errorMessage = _getErrorMessage(error.toString());
    });
    _errorController.forward();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _showConnectionError = true;
    });
    _errorController.forward();
  }

  String _getErrorMessage(String error) {
    if (error.contains('Connection refused')) {
      return 'Connection refused. Please check if MPD is running on the specified address.';
    } else if (error.contains('No route to host')) {
      return 'Cannot reach the host. Please check the IP address and network connectivity.';
    } else if (error.contains('timeout')) {
      return 'Connection timed out. Please check your network connection.';
    } else if (error.contains('SocketException')) {
      return 'Network error. Please check your connection settings.';
    } else {
      return 'Failed to connect to MPD server. Please check your settings and try again.';
    }
  }

  void _showConnectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConnectionDialog(
        formKey: _formKey,
        ipController: _ipController,
        portController: _portController,
        isConnecting: _isConnecting,
        onConnect: () async {
          Navigator.of(context).pop();
          await _attemptConnection();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _dismissError() {
    setState(() {
      _showConnectionError = false;
      _errorMessage = '';
    });
    _errorController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (_isInitializing)
              LoadingStateWidget(animation: _loadingController)
            else if (_isConnecting)
              ConnectingStateWidget(
                animation: _pulseController,
                host: _ipController.text,
                port: _portController.text,
              )
            else
              IdleStateWidget(onConfigurePressed: _showConnectionDialog),

            if (_showConnectionError)
              ErrorOverlayWidget(
                animation: _errorController,
                errorMessage: _errorMessage,
                onTryAgain: () {
                  _dismissError();
                  _showConnectionDialog();
                },
                onCancel: _dismissError,
              ),
          ],
        ),
      ),
    );
  }
}
