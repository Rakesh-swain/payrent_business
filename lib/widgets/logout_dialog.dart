import 'package:flutter/material.dart';
import 'package:payrent_business/screens/auth/login_page.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback? onLogout;

   const LogoutDialog({
    super.key,
    this.onLogout,
  });
  @override
  Widget build(BuildContext context) {
     return AlertDialog(backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Center(
          child: Text(
            'Logout',
            style: TextStyle(fontWeight: FontWeight.w600,fontFamily: 'SFProDisplay'),
          ),
        ),
        content: const Text(
          textAlign: TextAlign.center,
          'Are you sure you want to logout?',
        ),actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(), // Cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              // Use the provided callback if available, otherwise default behavior
              if (onLogout != null) {
                onLogout!();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text('Logout'),
          ),
        ],
      );
  }
}



