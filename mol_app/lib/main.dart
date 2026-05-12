import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'screens/predict_screen.dart';
import 'screens/batch_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/search_screen.dart';

void main() {
  runApp(const MolApp());
}

class MolApp extends StatelessWidget {
  const MolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MolPredict — Molecular Properties',
      debugShowCheckedModeBanner: false,
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
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  String? _pendingSmiles;

  static const _navItems = [
    (Icons.home_outlined,          Icons.home,          'Home'),
    (Icons.science_outlined,       Icons.science,       'Predict'),
    (Icons.table_chart_outlined,   Icons.table_chart,   'Batch'),
    (Icons.compare_outlined,       Icons.compare,       'Compare'),
    (Icons.search,                 Icons.search,        'Search'),
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
                const Text('MolPredict',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_navItems.length, (i) {
                        final item = _navItems[i];
                        final selected = _selectedIndex == i;
                        return _TopNavItem(
                          icon: selected ? item.$2 : item.$1,
                          label: item.$3,
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
              ],
            ),
          ),
        ),
      ),
      body: screens[_selectedIndex],
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
