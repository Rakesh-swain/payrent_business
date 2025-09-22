import 'package:flutter/material.dart';
import 'package:payrent_business/screens/auth/login_page.dart';

class LogoutDialog extends StatelessWidget {

   LogoutDialog({
    super.key,
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
        content: Text(
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
               Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
            },
            child: const Text('Logout'),
          ),
        ],
      );
  }
}



