import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/network_provider.dart';

/// Shows a modal dialog in the centre of the screen when the network
/// connection is considered poor.  The widget listens to the
/// [NetworkProvider] so it is easy to drop in near the top of the
/// widget tree (see `main.dart`).
///
/// The dialog only appears once per outage; when the user taps **OK** the
/// connection is re‑checked and, if it is still bad, another dialog is
/// scheduled after a short delay (10–15 s).  This avoids a continuous
/// barrage of pop‑ups while still letting the user know the app is having
/// trouble.
class NetworkAlert extends StatefulWidget {
  const NetworkAlert({super.key});

  @override
  State<NetworkAlert> createState() => _NetworkAlertState();
}

class _NetworkAlertState extends State<NetworkAlert> {
  bool _dialogVisible = false;
  Timer? _retryTimer;

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _maybeShow(NetworkProvider network) {
    if (network.isPoor && !_dialogVisible && _retryTimer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showDialog(network);
      });
    }
  }

  void _showDialog(NetworkProvider network) {
    _dialogVisible = true;
    final hasConn = network.hasConnection;
    final icon = hasConn
        ? Icons.signal_cellular_connected_no_internet_0_bar
        : Icons.signal_cellular_off;
    final message = hasConn
        ? (network.speedMbps != null
            ? 'Poor network connection (${network.speedMbps!.toStringAsFixed(2)} Mbps)'
            : 'Poor network connection')
        : 'No network connection';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // custom container so the appearance can be adjusted easily
        final mq = MediaQuery.of(context);
        final maxWidth = mq.size.width * 0.8;
        final fontSize = mq.textScaleFactor * 16;

        return Center(
          child: Container(
            width: maxWidth,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogBackgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: mq.size.width * 0.15, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: fontSize),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    _dialogVisible = false;

                    // force a fresh measurement immediately
                    await network.performCheck();
                    if (network.isPoor) {
                      // schedule another alert in 10 seconds
                      _retryTimer = Timer(const Duration(seconds: 10), () {
                        _retryTimer = null;
                        if (mounted && network.isPoor) {
                          _showDialog(network);
                        }
                      });
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // make sure the flag is cleared if the dialog is dismissed by other
      // means (shouldn't happen since barrierDismissible=false, but being
      // defensive is harmless).
      _dialogVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, child) {
        _maybeShow(network);
        return const SizedBox.shrink();
      },
    );
  }
}
