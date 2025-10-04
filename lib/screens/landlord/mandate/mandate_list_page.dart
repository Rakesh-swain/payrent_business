import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payrent_business/config/theme.dart';
import 'package:payrent_business/controllers/mandate_controller.dart';
import 'package:payrent_business/extensions/context_extension.dart';
import 'package:payrent_business/models/mandate_model.dart';
import 'mandate_status_page.dart';

class MandateListPage extends StatelessWidget {
  final MandateController _mandateController = Get.find<MandateController>();

  MandateListPage({super.key});

  Color _getMandateStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMandateListItem(BuildContext context, MandateModel mandate) {
    final statusColor = _getMandateStatusColor(mandate.mmsStatus);

    return GestureDetector(
      onTap: () {
        if (mandate.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MandateStatusPage(mandateId: mandate.id!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mandate.tenantAccountHolderName ?? 'Unknown',
                    style: context.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '\$${mandate.rentAmount} × ${mandate.noOfInstallments} payments',
                    style: context.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                mandate.mmsStatus ?? 'PENDING',
                style: context.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.visibility,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          'All Mandates',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Obx(() {
          if (_mandateController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final mandates = _mandateController.mandates;
          if (mandates.isEmpty) {
            return const Center(
              child: Text('No mandates found.'),
            );
          }

          return ListView.builder(
            itemCount: mandates.length,
            itemBuilder: (context, index) {
              final mandate = mandates[index];
              return _buildMandateListItem(context, mandate);
            },
          );
        }),
      ),
    );
  }
}
