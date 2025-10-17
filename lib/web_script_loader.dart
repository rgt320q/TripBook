import 'package:web/web.dart' as web;

void loadGoogleMapsScript(String apiKey) {
  final script = web.document.createElement('script') as web.HTMLScriptElement;
  script.id = 'google-maps-sdk';
  script.type = 'text/javascript';
  script.src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=places';
  web.document.head?.append(script);
}