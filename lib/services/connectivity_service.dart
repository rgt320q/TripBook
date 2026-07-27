import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:tripbook/l10n/app_localizations.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isConnected = true;
  OverlayEntry? _overlayEntry;

  bool get isConnected => _isConnected;

  void initialize(BuildContext context) {
    _checkInitialConnection(context);
    _startListening(context);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _removeOverlay();
  }

  Future<void> _checkInitialConnection(BuildContext context) async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult.any((res) => res != ConnectivityResult.none);
      
      if (!_isConnected && context.mounted) {
        _showNoConnectionOverlay(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noInternetAtStartup),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _isConnected = false;
    }
  }

  void _startListening(BuildContext context) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        final bool wasConnected = _isConnected;
        _isConnected = result.any((res) => res != ConnectivityResult.none);
        
        if (wasConnected && !_isConnected) {
          // İnternet bağlantısı kesildi
          _showNoConnectionOverlay(context);
        } else if (!wasConnected && _isConnected) {
          // İnternet bağlantısı yeniden bağlandı
          _removeOverlay();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.connectionRestored),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  void _showNoConnectionOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        top: MediaQuery.of(overlayContext).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade600,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.noInternetForOperation ?? 
                    'İnternet bağlantısı kesildi.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _removeOverlay,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      _overlayEntry = null;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.any((res) => res != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  Future<bool> executeWithConnectivityCheck<T>(
    BuildContext context,
    Future<T> Function() operation, {
    VoidCallback? onNoConnection,
    bool showSnackBar = true,
  }) async {
    if (!await checkConnection()) {
      if (showSnackBar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.noInternetForOperation),
            backgroundColor: Colors.red,
          ),
        );
      }
      onNoConnection?.call();
      return false;
    }
    
    try {
      await operation();
      return true;
    } catch (e) {
      return false;
    }
  }
}
