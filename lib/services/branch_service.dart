import '../models/account_information_model.dart';

class BranchService {
  static final List<BranchInfo> _branchData = [
    BranchInfo(
      bankBic: 'OMABOMRU',
      branchCode: '001',
      branchName: 'OAB HQ',
      branchDescription: 'OAB Headquarters TEST',
    ),
    BranchInfo(
      bankBic: 'BARBOMMX',
      branchCode: '001',
      branchName: 'BOB HQ',
      branchDescription: 'BOB Headquarters',
    ),
    BranchInfo(
      bankBic: 'MELIOMRX',
      branchCode: '001',
      branchName: 'BMI HQ test',
      branchDescription: 'BMI Headquarters',
    ),
    BranchInfo(
      bankBic: 'BSIROMRX',
      branchCode: '001',
      branchName: 'BSI HQ',
      branchDescription: 'BSI Headquarters',
    ),
    BranchInfo(
      bankBic: 'BBMEOMRX',
      branchCode: '001',
      branchName: 'HSBC HQ',
      branchDescription: 'HSBC Headquarters',
    ),
    BranchInfo(
      bankBic: 'SCBLOMRX',
      branchCode: '001',
      branchName: 'SCB HQ',
      branchDescription: 'SCB Headquarters',
    ),
    BranchInfo(
      bankBic: 'HABBOMRX',
      branchCode: '001',
      branchName: 'HABB HQ',
      branchDescription: 'HABB Headquarters',
    ),
    BranchInfo(
      bankBic: 'NBADOMRX',
      branchCode: '001',
      branchName: 'FAB HQ',
      branchDescription: 'FAB Headquarters',
    ),
    BranchInfo(
      bankBic: 'NBOMOMRX',
      branchCode: '001',
      branchName: 'NBO HQ',
      branchDescription: 'NBO Headquarters',
    ),
    BranchInfo(
      bankBic: 'BDOFOMRU',
      branchCode: '001',
      branchName: 'BDOF HQ',
      branchDescription: 'BDOF Headquarters',
    ),
    BranchInfo(
      bankBic: 'BMUSOMRX',
      branchCode: '001',
      branchName: 'BMCT HQ',
      branchDescription: 'BMCT Headquarters',
    ),
    BranchInfo(
      bankBic: 'SBINOMRX',
      branchCode: '001',
      branchName: 'SBI HQ',
      branchDescription: 'SBI Headquarters',
    ),
    BranchInfo(
      bankBic: 'BABEOMRX',
      branchCode: '001',
      branchName: 'BBUT HQ',
      branchDescription: 'BBUT Headquarters',
    ),
    BranchInfo(
      bankBic: 'BSHROMRU',
      branchCode: '001',
      branchName: 'BSHR HQ',
      branchDescription: 'BSHR Headquarters',
    ),
    BranchInfo(
      bankBic: 'AUBOOMRU',
      branchCode: '001',
      branchName: 'AHLI HQ',
      branchDescription: 'AHLI Headquarters',
    ),
    BranchInfo(
      bankBic: 'QNBAOMRX',
      branchCode: '001',
      branchName: 'QNB HQ',
      branchDescription: 'QNB Headquarters',
    ),
    BranchInfo(
      bankBic: 'BNZWOMRX',
      branchCode: '001',
      branchName: 'BNZW HQ',
      branchDescription: 'BNZW Headquarters',
    ),
    BranchInfo(
      bankBic: 'BMUSOMRXISL',
      branchCode: '001',
      branchName: 'MTHQ HQ',
      branchDescription: 'MTHQ Headquarters',
    ),
    BranchInfo(
      bankBic: 'NBOMOMRXIBS',
      branchCode: '001',
      branchName: 'MUZN HQ',
      branchDescription: 'MUZN Headquarters',
    ),
    BranchInfo(
      bankBic: 'BDOFOMRUMIB',
      branchCode: '001',
      branchName: 'MISR HQ',
      branchDescription: 'MISR Headquarters',
    ),
    BranchInfo(
      bankBic: 'AUBOOMRUALH',
      branchCode: '001',
      branchName: 'HLAL HQ',
      branchDescription: 'HLAL Headquarters',
    ),
    BranchInfo(
      bankBic: 'BSHROMRUISL',
      branchCode: '001',
      branchName: 'SHRI HQ',
      branchDescription: 'SHRI Headquarters',
    ),
    BranchInfo(
      bankBic: 'OMABOMRUYSR',
      branchCode: '001',
      branchName: 'YUSR HQ',
      branchDescription: 'YUSR Headquarters',
    ),
    BranchInfo(
      bankBic: 'ODBLOMRX',
      branchCode: '001',
      branchName: 'ODB HQ',
      branchDescription: 'ODB Headquarters',
    ),
    BranchInfo(
      bankBic: 'IZZBOMRU',
      branchCode: '001',
      branchName: 'IZZB HQ',
      branchDescription: 'IZZB Headquarters',
    ),
    BranchInfo(
      bankBic: 'OHBLOMRX',
      branchCode: '001',
      branchName: 'OHB HQ',
      branchDescription: 'OHB Headquarters',
    ),
    BranchInfo(
      bankBic: 'CBOMOMRUHRD',
      branchCode: '001',
      branchName: 'HRD HQ',
      branchDescription: 'HRD Headquarters',
    ),
    BranchInfo(
      bankBic: 'CBOMOMRUFID',
      branchCode: '001',
      branchName: 'FID HQ',
      branchDescription: 'FID Headquarters',
    ),
    BranchInfo(
      bankBic: 'CBOMOMRU1',
      branchCode: '001',
      branchName: 'CBPD HQ',
      branchDescription: 'CBPD Headquarters',
    ),
    BranchInfo(
      bankBic: 'HBMEOMRX',
      branchCode: '001',
      branchName: 'HBME HQ',
      branchDescription: 'HBME Headquarters',
    ),
    BranchInfo(
      bankBic: 'OIBBOMRX',
      branchCode: '001',
      branchName: 'OIBB HQ',
      branchDescription: 'OIBB Headquarters',
    ),
  ];

  // Get all available bank BICs
  static List<BranchInfo> getAllBranchList() {
    return _branchData;
  }

  // Get branches for a specific bank BIC
  static BranchInfo getBranchesForBank(String bankName) {
    return _branchData.where((branch) => branch.branchName == bankName).first;
  }

  // Get specific branch info
  static BranchInfo? getBranchInfo(String bankBic, String branchCode) {
    try {
      return _branchData.firstWhere(
        (branch) => branch.bankBic == bankBic && branch.branchCode == branchCode,
      );
    } catch (e) {
      return null;
    }
  }

  // Search branches by name or description
  static List<BranchInfo> searchBranches(String query) {
    final lowerQuery = query.toLowerCase();
    return _branchData.where((branch) {
      return branch.branchName.toLowerCase().contains(lowerQuery) ||
          branch.branchDescription.toLowerCase().contains(lowerQuery) ||
          branch.bankBic.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Validate if a bank BIC and branch code combination exists
  static bool isValidBankBranch(String bankBic, String branchCode) {
    return getBranchInfo(bankBic, branchCode) != null;
  }
}
