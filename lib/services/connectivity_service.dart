import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

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
    _checkInitialConnection();
    _startListening(context);
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _removeOverlay();
  }

  Future<void> _checkInitialConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult.contains(ConnectivityResult.mobile) ||
                    connectivityResult.contains(ConnectivityResult.wifi) ||
                    connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      _isConnected = false;
    }
  }

  void _startListening(BuildContext context) {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) {
        final bool wasConnected = _isConnected;
        _isConnected = result.contains(ConnectivityResult.mobile) ||
                      result.contains(ConnectivityResult.wifi) ||
                      result.contains(ConnectivityResult.ethernet);
        
        if (wasConnected && !_isConnected) {
          // İnternet bağlantısı kesildi
          _showNoConnectionOverlay(context);
        } else if (!wasConnected && _isConnected) {
          // İnternet bağlantısı yeniden bağlandı
          _removeOverlay();
        }
      },
    );
  }

  void _showNoConnectionOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
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
                  color: Colors.black.withOpacity(0.3),
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
                const Expanded(
                  child: Text(
                    'İnternet bağlantısı kesildi. Uygulamanın çalışmasını etkileyecek.',
                    style: TextStyle(
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
      // If overlay insertion fails, reset the overlay entry
      _overlayEntry = null;
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Manuel bağlantı kontrolü için
  Future<bool> checkConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.contains(ConnectivityResult.mobile) ||
             connectivityResult.contains(ConnectivityResult.wifi) ||
             connectivityResult.contains(ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }

  // Ağ işlemlerinde kullanmak için helper method
  Future<bool> executeWithConnectivityCheck<T>(
    Future<T> Function() operation, {
    VoidCallback? onNoConnection,
  }) async {
    if (!await checkConnection()) {
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