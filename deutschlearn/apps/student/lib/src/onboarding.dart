import 'package:auth/auth.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPreferencesProvider in main()'),
);

/// Whether the welcome/onboarding pages were completed on this device.
final onboardingSeenProvider = NotifierProvider<OnboardingSeen, bool>(OnboardingSeen.new);

class OnboardingSeen extends Notifier<bool> {
  static const _key = 'onboarding_seen_v1';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  Future<void> markSeen() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(_key, true);
  }
}

class _Page {
  const _Page(this.icon, this.color, this.tint, this.titleAr, this.bodyAr, this.de);
  final IconData icon;
  final Color color;
  final Color tint;
  final String titleAr;
  final String bodyAr;
  final String de;
}

const _pages = [
  _Page(
    Icons.school_rounded,
    DLColors.teal,
    DLColors.tintTeal,
    'تعلّم الألمانية خطوة بخطوة',
    'مسار واضح من A1 حتى C1 بدروس قصيرة باللغة العربية.',
    'Deutsch lernen – Schritt für Schritt von A1 bis C1.',
  ),
  _Page(
    Icons.groups_rounded,
    DLColors.blue,
    DLColors.tintBlue,
    'معلّمك معك',
    'اربط حسابك بمعلّمك عبر رمز المعلّم ليتابع تقدّمك.',
    'Verbinde dich mit deiner Lehrkraft über den Lehrer-Code.',
  ),
  _Page(
    Icons.insights_rounded,
    DLColors.yellow,
    DLColors.tintYellow,
    'تابع تقدّمك',
    'مستواك وإنجازاتك محفوظة في حسابك على كل أجهزتك.',
    'Dein Fortschritt wird in deinem Konto gespeichert.',
  ),
];

/// Arabic welcome/onboarding shown before the first sign-in.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DLSpacing.xl),
          child: Column(
            children: [
              Row(
                children: [
                  const DLLogo(size: 40, showWordmark: false),
                  const Spacer(),
                  TextButton(
                    key: const Key('welcome-skip'),
                    onPressed: () => _finish(AuthRoutes.login),
                    child: const Text('تخطي • Überspringen'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(color: p.tint, shape: BoxShape.circle),
                          child: Icon(p.icon, size: 96, color: p.color),
                        ),
                        const SizedBox(height: DLSpacing.xxl),
                        Text(p.titleAr, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: DLSpacing.md),
                        Text(p.bodyAr, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                        const SizedBox(height: DLSpacing.sm),
                        Text(
                          p.de,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? DLColors.teal : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(DLRadius.pill),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DLSpacing.xl),
              if (last) ...[
                DLPrimaryButton(
                  key: const Key('welcome-signup'),
                  label: bilingualLabel('ابدأ الآن', 'Jetzt starten'),
                  onPressed: () => _finish(AuthRoutes.signUp),
                ),
                const SizedBox(height: DLSpacing.md),
                DLSecondaryButton(
                  key: const Key('welcome-login'),
                  label: bilingualLabel('لدي حساب', 'Ich habe ein Konto'),
                  onPressed: () => _finish(AuthRoutes.login),
                ),
              ] else
                DLPrimaryButton(
                  key: const Key('welcome-next'),
                  label: bilingualLabel('التالي', 'Weiter'),
                  onPressed: () =>
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
