import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'router.dart';

/// Public name + preferred language. The name is what students see when they
/// enter the teacher code.
class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _locale;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(currentProfileProvider);
    _name = TextEditingController(text: p.displayName);
    _locale = p.locale == 'de' ? 'de' : 'ar';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final p = ref.read(currentProfileProvider);
      final updated = await ref
          .read(profileRepositoryProvider)
          .updateProfile(p.id, displayName: _name.text, locale: _locale);
      ref.read(sessionControllerProvider.notifier).profileUpdated(updated);
      if (mounted) context.go(TeacherRoutes.dashboard);
    } on AppFailure catch (f) {
      if (mounted) setState(() => _error = f.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = ref.watch(currentProfileProvider).hasDisplayName;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: canGoBack ? BackButton(onPressed: () => context.go(TeacherRoutes.dashboard)) : null,
        title: Text(bilingualLabel('الملف الشخصي', 'Profil')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(DLSpacing.xl),
          children: [
            Form(
              key: _formKey,
              child: DLCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const DLBilingualTitle(arabic: 'إعداد الملف الشخصي', german: 'Profil einrichten'),
                    const SizedBox(height: DLSpacing.sm),
                    Text(
                      'يظهر اسمك للطلاب عندما يدخلون رمزك. لا يظهر بريدك الإلكتروني.\n'
                      'Schüler sehen nur deinen Namen, nicht deine E-Mail.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: DLSpacing.xl),
                    TextFormField(
                      key: const Key('profile-name'),
                      controller: _name,
                      decoration: InputDecoration(
                        labelText: bilingualLabel('الاسم الظاهر', 'Anzeigename'),
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: AuthValidators.displayName,
                    ),
                    const SizedBox(height: DLSpacing.lg),
                    Text(
                      bilingualLabel('لغة الواجهة المفضلة', 'Bevorzugte Sprache'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: DLSpacing.sm),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ar', label: Text('العربية')),
                        ButtonSegment(value: 'de', label: Text('Deutsch')),
                      ],
                      selected: {_locale},
                      onSelectionChanged: (s) => setState(() => _locale = s.first),
                    ),
                    const SizedBox(height: DLSpacing.xl),
                    if (_error != null) FormErrorBanner(_error!),
                    DLPrimaryButton(
                      key: const Key('profile-save'),
                      label: bilingualLabel('حفظ', 'Speichern'),
                      icon: Icons.check,
                      loading: _busy,
                      onPressed: _busy ? null : _save,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
