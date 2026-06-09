import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/guardian_provider.dart';
import '../../models/guardianship.dart';
import '../../widgets/empty_state.dart';

/// 家人监护列表页（增强版）
/// 支持：被监护人列表、我的监护人、邀请管理、添加家人
class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  @override
  void initState() {
    super.initState();
    context.read<GuardianProvider>().loadAll();
  }

  void _showAddFamilyDialog(ThemeProvider theme) {
    final relationshipController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加家人'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: '被监护人ID或邀请码',
                hintText: '输入对方的ID或邀请码',
                prefixIcon: const Icon(Icons.person_search),
              ),
            ),
            SizedBox(height: theme.spaceMD),
            TextField(
              controller: relationshipController,
              decoration: InputDecoration(
                labelText: '关系',
                hintText: '如：父亲、母亲、配偶',
                prefixIcon: const Icon(Icons.family_restroom),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final id = codeController.text.trim();
              final rel = relationshipController.text.trim();
              if (id.isNotEmpty && rel.isNotEmpty) {
                context.read<GuardianProvider>().sendInvitation(id, rel);
                Navigator.pop(ctx);
              }
            },
            child: const Text('发送邀请'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.watch<GuardianProvider>();
    final isElderly = theme.isElderlyMode;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('家人监护'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add_outlined, size: theme.iconStandard),
            onPressed: () => _showAddFamilyDialog(theme),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => provider.loadAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isElderly ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 待确认邀请
              if (provider.invitations.isNotEmpty)
                _buildInvitationsSection(theme, provider, isElderly),
              if (provider.invitations.isNotEmpty)
                SizedBox(height: theme.spaceLG),

              // 我的监护（被监护人）
              Text(
                '我的监护',
                style: TextStyle(
                  fontSize: theme.fontSizeH3,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              SizedBox(height: theme.spaceMD),

              if (provider.isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ))
              else if (provider.patients.isEmpty)
                EmptyState(
                  icon: Icons.family_restroom_outlined,
                  title: '暂无被监护人',
                  subtitle: '点击右上角 + 添加家人，开始远程监护',
                  actionLabel: '添加家人',
                  onAction: () => _showAddFamilyDialog(theme),
                )
              else
                ...provider.patients.map((patient) => Padding(
                  padding: EdgeInsets.only(bottom: theme.spaceMD),
                  child: _buildPatientCard(theme, patient, isElderly),
                )),

              // 添加家人按钮
              SizedBox(height: theme.spaceMD),
              _buildAddFamilyButton(theme, isElderly),

              // 我的监护人
              if (provider.myGuardians.isNotEmpty) ...[
                SizedBox(height: theme.spaceXL),
                Text(
                  '我的监护人',
                  style: TextStyle(
                    fontSize: theme.fontSizeH3,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                SizedBox(height: theme.spaceMD),
                ...provider.myGuardians.map((g) => _buildGuardianCard(theme, g, isElderly)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationsSection(ThemeProvider theme, GuardianProvider provider, bool isElderly) {
    return Container(
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(theme.cardRadius),
        border: Border.all(color: const Color(0xFFFAAD14).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add_alt_1, color: Color(0xFFFAAD14), size: 24),
              SizedBox(width: theme.spaceSM),
              Text(
                '待确认邀请',
                style: TextStyle(
                  fontSize: theme.fontSizeBody,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFAAD14),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spaceMD),
          ...provider.invitations.map((inv) => Padding(
            padding: EdgeInsets.only(bottom: theme.spaceSM),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${inv.patientName ?? '未知用户'} 请求您作为监护人',
                    style: TextStyle(fontSize: theme.fontSizeBodySmall),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.confirmInvitation(inv.patientId, true),
                  child: const Text('接受', style: TextStyle(color: Color(0xFF52C41A))),
                ),
                TextButton(
                  onPressed: () => provider.confirmInvitation(inv.patientId, false),
                  child: const Text('拒绝', style: TextStyle(color: Color(0xFFFF4D4F))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPatientCard(ThemeProvider theme, GuardianPatientSummary patient, bool isElderly) {
    final hasWarning = patient.missed > 0;

    return GestureDetector(
      onTap: () {
        context.read<GuardianProvider>().loadReport(patient.patientId);
        Navigator.pushNamed(context, AppConstants.routeFamilyDetail, arguments: {
          'patientId': patient.patientId,
          'patientName': patient.patientName,
          'relationship': patient.relationship,
        });
      },
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          boxShadow: theme.shadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isElderly ? 28 : 24,
                  backgroundColor: theme.primaryLight,
                  child: Icon(Icons.person, color: theme.primary, size: theme.iconStandard),
                ),
                SizedBox(width: theme.spaceMD),
                Expanded(
                  child: Text(
                    '${patient.patientName}（${patient.relationship}）',
                    style: TextStyle(
                      fontSize: theme.fontSizeBody,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.textDisabled, size: theme.iconStandard),
              ],
            ),
            SizedBox(height: theme.spaceMD),
            Row(
              children: [
                _buildStatItem(theme, '今日用药', '${patient.completed}/${patient.total}', theme.primary),
                SizedBox(width: theme.spaceXL),
                _buildStatItem(theme, '按时率', '${patient.complianceRate.toStringAsFixed(0)}%', const Color(0xFF52C41A)),
              ],
            ),
            SizedBox(height: theme.spaceSM),
            Container(
              padding: EdgeInsets.symmetric(horizontal: theme.spaceSM, vertical: 4),
              decoration: BoxDecoration(
                color: hasWarning
                    ? const Color(0xFFFFF1F0)
                    : const Color(0xFF52C41A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasWarning ? Icons.warning_amber_rounded : Icons.check_circle,
                    size: 16,
                    color: hasWarning ? const Color(0xFFFF4D4F) : const Color(0xFF52C41A),
                  ),
                  SizedBox(width: theme.spaceXS),
                  Text(
                    hasWarning
                        ? '今日漏服 ${patient.missed} 次'
                        : '今日全部按时服药',
                    style: TextStyle(
                      fontSize: theme.fontSizeCaption,
                      color: hasWarning ? const Color(0xFFFF4D4F) : const Color(0xFF52C41A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianCard(ThemeProvider theme, Guardianship guardian, bool isElderly) {
    return Container(
      margin: EdgeInsets.only(bottom: theme.spaceMD),
      padding: EdgeInsets.all(theme.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(theme.cardRadius),
        boxShadow: theme.shadowLight,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isElderly ? 28 : 24,
            backgroundColor: theme.primaryLight,
            child: Icon(Icons.person, color: theme.primary, size: theme.iconStandard),
          ),
          SizedBox(width: theme.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guardian.patientName ?? '未知',
                  style: TextStyle(
                    fontSize: theme.fontSizeBody,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  guardian.relationshipLabel,
                  style: TextStyle(
                    fontSize: theme.fontSizeCaption,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddFamilyButton(ThemeProvider theme, bool isElderly) {
    return GestureDetector(
      onTap: () => _showAddFamilyDialog(theme),
      child: Container(
        padding: EdgeInsets.all(theme.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(theme.cardRadius),
          border: Border.all(
            color: theme.primary.withOpacity(0.3),
            width: isElderly ? 2 : 1,
          ),
          boxShadow: theme.shadowLight,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, color: theme.primary, size: theme.iconStandard),
            SizedBox(width: theme.spaceSM),
            Text(
              '添加家人',
              style: TextStyle(
                fontSize: theme.fontSizeBody,
                fontWeight: FontWeight.w500,
                color: theme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeProvider theme, String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label：',
          style: TextStyle(fontSize: theme.fontSizeCaption, color: theme.textSecondary),
        ),
        Icon(Icons.check_circle, size: 16, color: color),
        const SizedBox(width: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: theme.fontSizeBodySmall,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
