import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/l10n.dart';
import 'screens/home_screen.dart';
import 'screens/predict_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/search_screen.dart';
import 'screens/optimize_screen.dart';

void main() {
  runApp(const MolApp());
}

class MolApp extends StatefulWidget {
  const MolApp({super.key});

  @override
  State<MolApp> createState() => _MolAppState();
}

class _MolAppState extends State<MolApp> {
  Locale? _locale;

  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeepChem',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.blueAccent,
          surface: const Color(0xFF1A1A2E),
          onSurface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardColor: const Color(0xFF1E1E32),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E32),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white12),
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF252540),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF252540),
          side: const BorderSide(color: Colors.white12),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.tealAccent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.tealAccent,
            side: const BorderSide(color: Colors.tealAccent),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        dividerColor: Colors.white12,
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.white54,
          textColor: Colors.white,
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: Colors.white54,
          collapsedIconColor: Colors.white38,
        ),
        dataTableTheme: DataTableThemeData(
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
          dataTextStyle: const TextStyle(fontSize: 12),
          headingRowColor:
              WidgetStateProperty.all(const Color(0xFF252540)),
          dividerThickness: 0.3,
        ),
      ),
      home: AppShell(onLocaleChange: _setLocale),
    );
  }
}

class AppShell extends StatefulWidget {
  final void Function(Locale) onLocaleChange;
  const AppShell({super.key, required this.onLocaleChange});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String? _pendingSmiles;

  static const _navIcons = [
    (Icons.home_outlined,          Icons.home),
    (Icons.science_outlined,       Icons.science),
    (Icons.table_chart_outlined,   Icons.table_chart),
    (Icons.compare_outlined,       Icons.compare),
    (Icons.search,                 Icons.search),
    (Icons.auto_awesome_outlined,  Icons.auto_awesome),
  ];

  void _navigateToPredict(String smiles) {
    setState(() {
      _selectedIndex = 1;
      _pendingSmiles = smiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      HomeScreen(onPredict: _navigateToPredict),
      PredictScreen(initialSmiles: _pendingSmiles),
      const BatchScreen(),
      const CompareScreen(),
      SearchScreen(onPredict: _navigateToPredict),
      const OptimizeScreen(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Container(
          color: const Color(0xFF12122A),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.biotech, color: Colors.tealAccent, size: 24),
                const SizedBox(width: 8),
                const Text('DeepChem',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_navIcons.length, (i) {
                        final navLabels = [
                          context.l10n.navHome,
                          context.l10n.navPredict,
                          context.l10n.navBatch,
                          context.l10n.navCompare,
                          context.l10n.navSearch,
                          context.l10n.navGaOpt,
                        ];
                        final item = _navIcons[i];
                        final selected = _selectedIndex == i;
                        return _TopNavItem(
                          icon: selected ? item.$2 : item.$1,
                          label: navLabels[i],
                          selected: selected,
                          accentColor: Colors.tealAccent,
                          onTap: () {
                            setState(() {
                              _selectedIndex = i;
                              if (i != 1) _pendingSmiles = null;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                ),
                _LangButton(onLocaleChange: widget.onLocaleChange),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: screens[_selectedIndex],
    );
  }
}

class _LangButton extends StatelessWidget {
  final void Function(Locale) onLocaleChange;
  const _LangButton({required this.onLocaleChange});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white54, size: 18),
      tooltip: 'Language',
      color: const Color(0xFF1E1E32),
      onSelected: (code) => onLocaleChange(Locale(code)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'en', child: Text('🇺🇸  English')),
        PopupMenuItem(value: 'ja', child: Text('🇯🇵  日本語')),
        PopupMenuItem(value: 'zh', child: Text('🇨🇳  中文')),
      ],
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _TopNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: selected
            ? BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentColor.withValues(alpha: 0.5)),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? accentColor : Colors.white54),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? accentColor : Colors.white54,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
