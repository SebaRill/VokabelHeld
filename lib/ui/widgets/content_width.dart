import 'package:material_ui/material_ui.dart';

/// Begrenzt die Inhaltsbreite auf Tablets (sieht in Querformat besser aus).
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
        ),
      );
}
