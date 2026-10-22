import 'package:flutter/material.dart';

import '../l10n/language.dart';
import '../services/api_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/menu_row.dart';
import '../widgets/page_header.dart';
import 'web_page_screen.dart';

/// The privacy policy, the terms, and how to delete an account — all three
/// are pages on the backend, so they can change without a release.
///
/// Play wants the policy and the way to delete an account reachable from
/// inside the app, not only from the store listing; this is where they are.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static final _pages =
      <
        ({
          IconData icon,
          String labelId,
          String label,
          String path,
          String? section,
        })
      >[
        (
          icon: AppIcons.description,
          labelId: 'Kebijakan privasi',
          label: 'Privacy Policy',
          path: 'policy',
          section: null,
        ),
        (
          icon: AppIcons.gavel,
          labelId: 'Ketentuan layanan',
          label: 'Terms of Service',
          path: 'terms',
          section: null,
        ),
        (
          icon: AppIcons.personRemove,
          labelId: 'Hapus akun',
          label: 'Delete account',
          path: 'policy',
          section: 'delete',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    // The site has English and Indonesian; the app's chosen language picks.
    final language = context.language.name;

    return Scaffold(
      body: Column(
        children: [
          PageHeader(
            title: context.tr('Privasi', 'Privacy'),
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.marginMobile),
              children: [
                for (final page in _pages) ...[
                  MenuRow(
                    icon: page.icon,
                    label: context.tr(page.labelId, page.label),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WebPageScreen(
                          title: context.tr(page.labelId, page.label),
                          url: ApiConfig.page(
                            page.path,
                            language: language,
                            section: page.section,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.sm),
                ],
                const SizedBox(height: AppTheme.sm),
                Text(
                  context.tr(
                    'Data apa yang kami kumpulkan, bagaimana digunakan, dan '
                        'cara menghapus akun serta datanya.',
                    'What we collect, how it is used, and how to have your '
                        'account and its data removed.',
                  ),
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
