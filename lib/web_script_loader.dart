// lib/web_script_loader.dart
import 'dart:html' as html;

void loadGoogleMapsScript(String apiKey) {
  final script = html.ScriptElement()
    ..id = 'google-maps-sdk'
    ..type = 'text/javascript'
    ..src = 'https://maps.googleapis.com/maps/api/js?key=\$apiKey&libraries=places';
  html.document.head?.append(script);
}
