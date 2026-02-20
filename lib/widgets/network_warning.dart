import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_provider.dart';

/// A simple banner that is shown at the top of the UI when the network is
/// considered to be too slow according to the rules defined in
/// [NetworkProvider].  When the connection is adequate the widget collapses
/// to zero height.
class NetworkWarningBanner extends StatelessWidget {
  const NetworkWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, network, _) {
        if (network.isPoor) {
          final mq = MediaQuery.of(context);
          // adapt height/padding to screen size; on a 6.78" phone this will
          // still be reasonably compact but scales up on tablets.
          final height = mq.size.height * 0.06; // 6% of screen height
          final iconSize = mq.size.width * 0.06; // 6% of screen width
          final fontSize = mq.textScaleFactor * 14;

          // choose message based on whether we have any connectivity at all
          final message = network.hasConnection
              ? (network.speedMbps != null
                  ? 'Poor network connection (${network.speedMbps!.toStringAsFixed(2)} Mbps)'
                  : 'Poor network connection')
              : 'No network connection';

          return Container(
            width: double.infinity,
            height: height,
            color: Colors.red.shade700,
            padding: EdgeInsets.symmetric(
                vertical: height * 0.15, horizontal: mq.size.width * 0.03),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  network.hasConnection
                      ? Icons.signal_cellular_connected_no_internet_0_bar
                      : Icons.signal_cellular_off,
                  color: Colors.white,
                  size: iconSize,
                ),
                SizedBox(width: mq.size.width * 0.02),
                Flexible(
                  child: Text(
                    message,
                    style:
                        TextStyle(color: Colors.white, fontSize: fontSize),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
