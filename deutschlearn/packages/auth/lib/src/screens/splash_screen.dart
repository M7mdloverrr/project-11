import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

/// Shown while the persisted session and profile are restored.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.subtitle});
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DLLogo(size: 96, subtitle: subtitle),
            const SizedBox(height: DLSpacing.xxl),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          ],
        ),
      ),
    );
  }
}
