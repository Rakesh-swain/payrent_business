import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/widgets/logout_dialog.dart';

PreferredSizeWidget appBar(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: Container(
      // extra container for custom bottom shadows
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            spreadRadius: 6,
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title:FadeInDown(
          duration: const Duration(milliseconds: 800),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset("assets/logo.png", height: 36, width: 32),
              const SizedBox(width: 8),
              Text(
                'PayRent',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F287D),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child:IconButton(icon: Icon(Icons.logout_outlined),onPressed: (){
              showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return  LogoutDialog();
                    },
                  );
            },)
          ),
        ],
      ),
    ),
  );
}
