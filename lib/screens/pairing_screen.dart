import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class PairingScreen extends StatefulWidget {
  final bool isShowingQr;
  const PairingScreen({super.key, required this.isShowingQr});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  String? _pairingCode;
  bool _isLoading = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isShowingQr) {
      _generateCode();
    }
  }

  Future<void> _generateCode() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      final code = await chatProvider.createPairing(authProvider.user!.userId);
      if (mounted) {
        setState(() {
          _pairingCode = code;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinPairing(String code) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (authProvider.user != null) {
      final success = await chatProvider.joinPairing(code, authProvider.user!.userId);
      if (mounted) {
         setState(() => _isLoading = false);
         if (success) {
           Navigator.of(context).pop(); // Return to Home, which will show Chat
         } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Failed to join pairing. Check code.')),
           );
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for connection status to auto-close if we are showing QR
    final isConnected = context.select<ChatProvider, bool>((p) => p.isConnected);
    if (widget.isShowingQr && isConnected) {
      // Use addPostFrameCallback to avoid build issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isShowingQr ? 'Pair Device' : 'Scan Code'),
      ),
      body: widget.isShowingQr ? _buildShowQr() : _buildScanQr(),
    );
  }

  Widget _buildShowQr() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pairingCode == null) {
       return Center(
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text('Failed to generate code'),
             ElevatedButton(onPressed: _generateCode, child: const Text('Retry')),
           ],
         ),
       );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Scan this code to pair:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 24),
          QrImageView(
            data: _pairingCode!,
            version: QrVersions.auto,
            size: 200.0,
          ),
          const SizedBox(height: 24),
          Text(
            _pairingCode!,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 12),
          const Text('Waiting for connection...', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildScanQr() {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _joinPairing(barcode.rawValue!);
                  break; // Only take the first one
                }
              }
            },
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Or enter code manually:'),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'Pairing Code',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _joinPairing(_codeController.text.trim().toUpperCase()),
                    ),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (val) => _joinPairing(val.trim().toUpperCase()),
                ),
                if (_isLoading)
                   const Padding(
                     padding: EdgeInsets.only(top: 16.0),
                     child: CircularProgressIndicator(),
                   ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
