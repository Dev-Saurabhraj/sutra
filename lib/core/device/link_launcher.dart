import 'package:url_launcher/url_launcher.dart';

/// Opens WhatsApp / UPI links in the right app.
abstract interface class LinkLauncher {
  Future<bool> open(String url);
}

class DeviceLinkLauncher implements LinkLauncher {
  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
