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

    final navItems = [
      (Icons.home_outlined, Icons.home, 'Home'),
      (Icons.science_outlined, Icons.science, 'Predict'),
      (Icons.table_chart_outlined, Icons.table_chart, 'Batch'),
      (Icons.compare_outlined, Icons.compare, 'Compare'),
      (Icons.search, Icons.search, 'Search'),
    ];

    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      body: Row(
        children: [
          // Navigation Rail (desktop)
          if (isWide)
            NavigationRail(
              backgroundColor: const Color(0xFF12122A),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() {
                  _selectedIndex = i;
                  if (i != 1) _pendingSmiles = null;
                });
              },
              labelType: NavigationRailLabelType.all,
              minWidth: 80,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.biotech, color: Colors.tealAccent, size: 28),
              ),
              selectedIconTheme:
                  const IconThemeData(color: Colors.tealAccent),
              selectedLabelTextStyle:
                  const TextStyle(color: Colors.tealAccent, fontSize: 11),
              unselectedLabelTextStyle:
                  const TextStyle(color: Colors.white38, fontSize: 11),
              destinations: navItems
                  .map((n) => NavigationRailDestination(
                        icon: Icon(n.$1),
                        selectedIcon: Icon(n.$2),
                        label: Text(n.$3),
                      ))
                  .toList(),
            ),
          if (isWide)
            const VerticalDivider(thickness: 1, width: 1, color: Colors.white12),
          // Main content
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
      // Bottom nav (mobile)
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              backgroundColor: const Color(0xFF12122A),
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() {
                  _selectedIndex = i;
                  if (i != 1) _pendingSmiles = null;
                });
              },
              destinations: navItems
                  .map((n) => NavigationDestination(
                        icon: Icon(n.$1),
                        selectedIcon: Icon(n.$2),
                        label: n.$3,
                      ))
                  .toList(),
            ),
    );
  }
}
