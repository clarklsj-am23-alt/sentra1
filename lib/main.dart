import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/station_facilities_screen.dart';
// Practical 11 Supabase Configuration
const String supabaseUrl = 'YOUR_SUPABASE_URL'; // Shared by Cheng Zhe
const String supabaseKey = 'YOUR_SUPABASE_ANON_KEY';

const Color appYellow = Color(0xFFFCEB00);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Step 18 from Practical 11
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const Sentra1App());
}

final supabase = Supabase.instance.client;

class Sentra1App extends StatelessWidget {
  const Sentra1App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentra1 Accessibility Transit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        textTheme: GoogleFonts.dmSansTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.light(
          primary: appYellow,
          onPrimary: Colors.black,
          secondary: Colors.black,
          onSecondary: appYellow,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: appYellow,
          elevation: 2,
          titleTextStyle: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: appYellow,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.black,
          indicatorColor: appYellow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.dmSans(
                color: appYellow,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              );
            }
            return GoogleFonts.dmSans(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return const IconThemeData(color: Colors.grey);
          }),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  // 3 tabs matching the 3 NavigationDestinations below
  final List<Widget> _screens = const [
    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Explore Map (Jia Cheng)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),

    ThamFeatureHomeScreen(),

    Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.departure_board, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Schedules & Cards (Clark)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentra1'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: appYellow),
            onPressed: () {
              // TODO: Navigator.push to Cheng Zhe's user_management profile screen
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Explore Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.alt_route_outlined),
            selectedIcon: Icon(Icons.alt_route),
            label: 'Trip Planner',
          ),
          NavigationDestination(
            icon: Icon(Icons.departure_board_outlined),
            selectedIcon: Icon(Icons.departure_board),
            label: 'Schedules',
          ),
        ],
      ),
    );
  }
}
class ThamFeatureHomeScreen extends StatelessWidget {
  const ThamFeatureHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.alt_route,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),

          const Text(
            'Trip Planner (Tham)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: const Icon(Icons.accessible),
            label: const Text('Station Facilities'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const StationFacilitiesScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
// Keep the MapHomeScreen, JourneyPlannerScreen, and RoutesScheduleScreen classes below as fallback UI until each member replaces them with their actual feature folders.