import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/common/app_loading_indicator.dart';

class FirebaseInitializer {
  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Error initializing Firebase: $e');
      rethrow;
    }
  }
  
  // Wrapper widget for Firebase initialization
  static Widget initializeApp({required Widget child}) {
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                    boxShadow: Theme.of(context).extension<AppDecorations>()?.shadows.level1,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connection Issue',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error initializing Firebase: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.done) {
          return child;
        }
        
        return const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: AppLoadingIndicator(
              showLabel: true,
              label: 'Preparing your dashboard',
            ),
          ),
        );
      },
    );
  }
}
