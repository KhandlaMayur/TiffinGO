import 'dart:async';
import 'package:http/http.dart' as http;

/// Utility class used to estimate download speed by fetching a small
/// static resource and measuring how long it takes.  The returned value
/// is in megabits-per-second (Mb/s).
class NetworkService {
  /// A simple test that downloads a small image from Google and uses the
  /// elapsed time to compute an approximate throughput.  We intentionally
  /// pick a very small file so that the test is quick and inexpensive.
  static Future<double> checkNetworkSpeed() async {
    final url = Uri.parse(
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png');
    final stopwatch = Stopwatch()..start();
    final response = await http.get(url);
    stopwatch.stop();

    if (response.statusCode != 200) {
      throw Exception('Unable to download test file');
    }

    final bytes = response.contentLength ?? response.bodyBytes.length;
    final seconds = stopwatch.elapsedMilliseconds / 1000.0;

    if (seconds == 0) {
      return 0.0;
    }

    // Convert bytes/second to megabits/second
    final mbps = (bytes * 8) / (seconds * 1000000);
    return mbps;
  }
}
