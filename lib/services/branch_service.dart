import '../models/account_information_model.dart';

class BranchService {
  static final Map<String, List<BranchInfo>> _branchData = {
    // Kuwait Banking
    'KFHKWKWT': [
      BranchInfo(
        bankBic: 'KFHKWKWT',
        branchCode: '001',
        branchName: 'Kuwait Finance House - Main Branch',
        branchDescription: 'Main headquarters branch located in Kuwait City',
      ),
      BranchInfo(
        bankBic: 'KFHKWKWT',
        branchCode: '002',
        branchName: 'Kuwait Finance House - Salmiya',
        branchDescription: 'Salmiya commercial district branch',
      ),
      BranchInfo(
        bankBic: 'KFHKWKWT',
        branchCode: '003',
        branchName: 'Kuwait Finance House - Hawalli',
        branchDescription: 'Hawalli governorate branch',
      ),
    ],
    'NBLKKWKW': [
      BranchInfo(
        bankBic: 'NBLKKWKW',
        branchCode: '001',
        branchName: 'National Bank of Kuwait - Head Office',
        branchDescription: 'Central head office in Kuwait City',
      ),
      BranchInfo(
        bankBic: 'NBLKKWKW',
        branchCode: '002',
        branchName: 'National Bank of Kuwait - Sharq',
        branchDescription: 'Sharq business district branch',
      ),
      BranchInfo(
        bankBic: 'NBLKKWKW',
        branchCode: '003',
        branchName: 'National Bank of Kuwait - Jahra',
        branchDescription: 'Jahra governorate branch',
      ),
    ],
    'CBKKWKW1': [
      BranchInfo(
        bankBic: 'CBKKWKW1',
        branchCode: '001',
        branchName: 'Commercial Bank of Kuwait - Main',
        branchDescription: 'Main branch in Kuwait City center',
      ),
      BranchInfo(
        bankBic: 'CBKKWKW1',
        branchCode: '002',
        branchName: 'Commercial Bank of Kuwait - Fahaheel',
        branchDescription: 'Fahaheel coastal area branch',
      ),
    ],
    'GULBKWKW': [
      BranchInfo(
        bankBic: 'GULBKWKW',
        branchCode: '001',
        branchName: 'Gulf Bank - Headquarters',
        branchDescription: 'Central headquarters branch',
      ),
      BranchInfo(
        bankBic: 'GULBKWKW',
        branchCode: '002',
        branchName: 'Gulf Bank - Shuwaikh',
        branchDescription: 'Shuwaikh industrial area branch',
      ),
    ],
    // UAE Banking
    'EBILAEAD': [
      BranchInfo(
        bankBic: 'EBILAEAD',
        branchCode: '001',
        branchName: 'Emirates NBD - Dubai Main',
        branchDescription: 'Main branch in Dubai financial district',
      ),
      BranchInfo(
        bankBic: 'EBILAEAD',
        branchCode: '002',
        branchName: 'Emirates NBD - Abu Dhabi',
        branchDescription: 'Abu Dhabi capital branch',
      ),
      BranchInfo(
        bankBic: 'EBILAEAD',
        branchCode: '003',
        branchName: 'Emirates NBD - Sharjah',
        branchDescription: 'Sharjah emirate branch',
      ),
    ],
    'ADCBAEAA': [
      BranchInfo(
        bankBic: 'ADCBAEAA',
        branchCode: '001',
        branchName: 'ADCB - Abu Dhabi Main',
        branchDescription: 'Abu Dhabi Commercial Bank main branch',
      ),
      BranchInfo(
        bankBic: 'ADCBAEAA',
        branchCode: '002',
        branchName: 'ADCB - Dubai Branch',
        branchDescription: 'Dubai commercial district branch',
      ),
    ],
    'FABKAEAA': [
      BranchInfo(
        bankBic: 'FABKAEAA',
        branchCode: '001',
        branchName: 'FAB - Abu Dhabi HQ',
        branchDescription: 'First Abu Dhabi Bank headquarters',
      ),
      BranchInfo(
        bankBic: 'FABKAEAA',
        branchCode: '002',
        branchName: 'FAB - Dubai International',
        branchDescription: 'Dubai international business branch',
      ),
    ],
  };

  // Get all available bank BICs
  static List<String> getAllBankBics() {
    return _branchData.keys.toList()..sort();
  }

  // Get bank name from BIC
  static String getBankName(String bankBic) {
    switch (bankBic) {
      case 'KFHKWKWT':
        return 'Kuwait Finance House';
      case 'NBLKKWKW':
        return 'National Bank of Kuwait';
      case 'CBKKWKW1':
        return 'Commercial Bank of Kuwait';
      case 'GULBKWKW':
        return 'Gulf Bank';
      case 'EBILAEAD':
        return 'Emirates NBD';
      case 'ADCBAEAA':
        return 'Abu Dhabi Commercial Bank';
      case 'FABKAEAA':
        return 'First Abu Dhabi Bank';
      default:
        return bankBic;
    }
  }

  // Get branches for a specific bank BIC
  static List<BranchInfo> getBranchesForBank(String bankBic) {
    return _branchData[bankBic] ?? [];
  }

  // Get specific branch info
  static BranchInfo? getBranchInfo(String bankBic, String branchCode) {
    final branches = _branchData[bankBic];
    if (branches != null) {
      for (final branch in branches) {
        if (branch.branchCode == branchCode) {
          return branch;
        }
      }
    }
    return null;
  }

  // Search branches by name or description
  static List<BranchInfo> searchBranches(String query) {
    final List<BranchInfo> results = [];
    final lowerQuery = query.toLowerCase();
    
    for (final branches in _branchData.values) {
      for (final branch in branches) {
        if (branch.branchName.toLowerCase().contains(lowerQuery) ||
            branch.branchDescription.toLowerCase().contains(lowerQuery) ||
            getBankName(branch.bankBic).toLowerCase().contains(lowerQuery)) {
          results.add(branch);
        }
      }
    }
    
    return results;
  }

  // Validate if a bank BIC and branch code combination exists
  static bool isValidBankBranch(String bankBic, String branchCode) {
    return getBranchInfo(bankBic, branchCode) != null;
  }
}