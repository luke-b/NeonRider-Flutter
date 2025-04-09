import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Needs flutter pub get
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Needs flutter pub get
import 'dart:ui' show ImageFilter;
import 'dart:async'; // For Future.delayed
import 'dart:math'; // For Random

// --- Configuration & Theme ---

const Color primaryColor = Color(0xFF8A2BE2); // BlueViolet
const Color secondaryColor = Color(0xFFFF1493); // DeepPink
const Color darkColor = Color(0xFF0F0F1A);
const Color darkerColor = Color(0xFF070710);
const Color lightColor = Color(0xFFF0F0FF);
const Color accentColor = Color(0xFF00F5FF); // Cyan Aqua
const Color successColor = Color(0xFF00FF7F); // SpringGreen

// Neon Glow BoxShadows (Combine primary glow for simplicity in use)
final List<BoxShadow> neonGlowPrimary = _createNeonGlow(primaryColor);
final List<BoxShadow> neonGlowSecondary = _createNeonGlow(secondaryColor);
final List<BoxShadow> neonGlowAccent = _createNeonGlow(accentColor);

List<BoxShadow> _createNeonGlow(Color color) {
  return [
    BoxShadow(color: color.withOpacity(0.7), blurRadius: 10, spreadRadius: 0),
    BoxShadow(color: color.withOpacity(0.5), blurRadius: 20, spreadRadius: -5),
    BoxShadow(color: color.withOpacity(0.3), blurRadius: 30, spreadRadius: -10),
  ];
}

final List<BoxShadow> neonGlowDark = [
  BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 30,
    spreadRadius: -10,
    offset: const Offset(0, -10),
  ),
];

// --- Data Models ---

// Represents a selectable ride option
class RideOption {
  final String key;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String details;
  final String price;
  final int etaMinutes; // Added Estimated Time Arrival
  final String? tagText;
  final IconData? tagIcon;

  const RideOption({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.details,
    required this.price,
    required this.etaMinutes,
    this.tagText,
    this.tagIcon,
  });
}

// Represents an assigned driver (dummy data)
class Driver {
  final String name;
  final String carModel;
  final String licensePlate;
  final double rating;
  final String photoUrl; // Placeholder URL
  final int etaMinutes;

  Driver({
    required this.name,
    required this.carModel,
    required this.licensePlate,
    required this.rating,
    required this.photoUrl,
    required this.etaMinutes,
  });
}

// --- Application State ---

// Enum to manage the current state of the booking process
enum AppState {
  idle, // Initial state, selecting ride
  searching, // Searching for a driver
  driverAssigned, // Driver found and assigned
  onTrip, // (Optional state for future expansion)
}

// --- Main Application ---

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));
  runApp(const NeonRideApp());
}

class NeonRideApp extends StatelessWidget {
  const NeonRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeonRide Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkerColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          surface: darkColor,
          background: darkerColor,
          onPrimary: lightColor,
          onSecondary: lightColor,
          onSurface: lightColor,
          onBackground: lightColor,
          error: Colors.redAccent,
          onError: lightColor,
        ),
        textTheme: GoogleFonts.interTextTheme( // Requires google_fonts
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: lightColor,
          displayColor: lightColor,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- Home Screen Widget ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- State Variables ---
  AppState _appState = AppState.idle;
  RideOption? _selectedRideOption;
  Driver? _assignedDriver;
  String _pickupLocation = "Hlavní 123"; // Default pickup
  String? _destinationLocation; // User input for destination

  // --- Controllers ---
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // --- Ride Options Data --- (Moved here for easier access)
  final List<RideOption> _availableRides = const [
    RideOption(key: 'neonx', icon: FontAwesomeIcons.car, iconColor: primaryColor, title: "NeonX", details: "2-4 osoby", price: "250 Kč", etaMinutes: 5, tagText: "Nejrychlejší", tagIcon: FontAwesomeIcons.bolt),
    RideOption(key: 'neonxl', icon: FontAwesomeIcons.bolt, iconColor: secondaryColor, title: "NeonXL", details: "4-6 osob", price: "375 Kč", etaMinutes: 7),
    RideOption(key: 'neonblack', icon: FontAwesomeIcons.star, iconColor: accentColor, title: "NeonBlack", details: "Luxusní vůz", price: "499 Kč", etaMinutes: 8),
    RideOption(key: 'neonbike', icon: FontAwesomeIcons.bicycle, iconColor: primaryColor, title: "NeonBike", details: "Ekologická", price: "105 Kč", etaMinutes: 10),
  ];

  @override
  void initState() {
    super.initState();
    _pickupController.text = _pickupLocation; // Initialize pickup field
    _selectedRideOption = _availableRides[0]; // Pre-select first ride

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _floatAnimation = Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, -0.3)).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _sheetController.dispose(); // Dispose sheet controller
    super.dispose();
  }

  // --- State Management Methods ---

  void _selectRide(RideOption ride) {
    if (_appState == AppState.idle) {
      setState(() {
        _selectedRideOption = ride;
      });
    }
  }

  void _confirmRide() {
    if (_selectedRideOption != null && _appState == AppState.idle) {
      setState(() {
        _appState = AppState.searching;
      });
      // Animate sheet slightly higher during search
       _sheetController.animateTo(
           0.5, // Or desired height
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeOut,
       );
      _simulateSearch();
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Prosím, vyberte typ jízdy."), backgroundColor: secondaryColor)
       );
    }
  }

  void _simulateSearch() {
    // Simulate network delay
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return; // Check if widget is still in tree
      _assignDriver();
    });
  }

  void _assignDriver() {
     final random = Random();
     final driverNames = ["Jana N.", "Petr S.", "Lucie K.", "Tomáš P."];
     final carModels = ["Tesla Model 3", "Audi e-tron", "Škoda Enyaq", "VW ID.4"];
     final plates = ["1AB 1234", "5CD 5678", "9EF 9012", "3GH 3456"];

     final driver = Driver(
        name: driverNames[random.nextInt(driverNames.length)],
        carModel: carModels[random.nextInt(carModels.length)],
        licensePlate: plates[random.nextInt(plates.length)],
        rating: 4.5 + random.nextDouble() * 0.5, // 4.5 to 5.0
        photoUrl: "https://via.placeholder.com/100", // Placeholder image
        etaMinutes: 2 + random.nextInt(4) // 2-5 minutes ETA after assignment
     );

     setState(() {
       _assignedDriver = driver;
       _appState = AppState.driverAssigned;
     });
     // Animate sheet to show driver details fully
      _sheetController.animateTo(
           0.6, // Or desired height
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeOut,
       );
  }

  void _cancelSearchOrTrip() {
     _resetState();
  }

  void _resetState() {
    setState(() {
      _appState = AppState.idle;
      _assignedDriver = null;
      // Keep selected ride or reset it? Let's keep it for now.
      // _selectedRideOption = _availableRides[0];
    });
     // Animate sheet back down
      _sheetController.animateTo(
           // _sheetController.initialSize, // <-- This was the error
           0.35, // <-- FIX: Use the actual initialChildSize value defined below
           duration: const Duration(milliseconds: 300),
           curve: Curves.easeOut,
       );
  }

  // --- Build Methods ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildMapArea(),
          _buildTopNavigation(),
          _buildLocationSearch(),
          _buildFloatingActionButton(), // Kept for centering map etc.
          // Show driver marker only when assigned
          if (_appState == AppState.driverAssigned && _assignedDriver != null)
             _buildDriverMarker(),
          _buildBottomSheet(), // DraggableScrollableSheet handles its position
        ],
      ),
    );
  }

  // --- Map Area and its Elements ---

  Widget _buildMapArea() {
    return Container(
       decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [ Color(0xFF1A0A2E), darkerColor], stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          _buildCurrentLocationMarker(),
          // Only show destination marker if destination is set (and not searching/assigned)
          if (_destinationLocation != null && _destinationLocation!.isNotEmpty && _appState == AppState.idle)
             _buildDestinationMarker(),
          // Only show route line if destination set (and not searching/assigned)
           if (_destinationLocation != null && _destinationLocation!.isNotEmpty && _appState == AppState.idle)
              _buildRouteLine(),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
     return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: MediaQuery.of(context).size.width * 0.5 - 10,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) => Transform.scale(scale: _pulseAnimation.value, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle, boxShadow: neonGlowAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMarkerLabel("Jste zde", neonGlowPrimary),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationMarker() {
     return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: MediaQuery.of(context).size.width * 0.3,
      child: SlideTransition(
        position: _floatAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(color: secondaryColor, shape: BoxShape.circle, boxShadow: neonGlowSecondary),
            ),
            const SizedBox(height: 8),
            _buildMarkerLabel("Cílová destinace", neonGlowSecondary),
          ],
        ),
      ),
    );
  }

   Widget _buildDriverMarker() {
     return Positioned(
      top: MediaQuery.of(context).size.height * 0.5,
      left: MediaQuery.of(context).size.width * 0.6,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.9),
              shape: BoxShape.circle,
              boxShadow: neonGlowPrimary,
            ),
            // Requires font_awesome_flutter
            child: FaIcon(FontAwesomeIcons.carSide, color: lightColor, size: 20),
          ),
          const SizedBox(height: 8),
          _buildMarkerLabel("${_assignedDriver!.etaMinutes} min", neonGlowPrimary),
        ],
      ),
     );
  }

  Widget _buildMarkerLabel(String text, List<BoxShadow> shadow) {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: darkColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow,
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: lightColor)),
    );
  }

  Widget _buildRouteLine() {
     return Positioned(
      top: MediaQuery.of(context).size.height * 0.325,
      left: MediaQuery.of(context).size.width * 0.4,
      child: Transform.rotate(
        angle: -0.7,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.2, height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryColor, secondaryColor, accentColor]),
            boxShadow: neonGlowPrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  // --- Top UI Elements ---

  Widget _buildTopNavigation() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconButton(
                  FontAwesomeIcons.bars, // Requires font_awesome_flutter
                  neonGlowPrimary,
                  onTap: _appState == AppState.idle ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Menu tapped (placeholder)"), duration: Duration(seconds: 1))
                    );
                  } : _cancelSearchOrTrip, // Use menu to cancel if searching/assigned
                  iconOverride: _appState != AppState.idle ? FontAwesomeIcons.xmark : null // Requires font_awesome_flutter
              ),
              _buildTimePill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData defaultIcon, List<BoxShadow> shadow, {VoidCallback? onTap, IconData? iconOverride}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: darkColor.withOpacity(0.8),
            shape: BoxShape.circle,
            boxShadow: shadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onTap,
              // Requires font_awesome_flutter (used for Icon widget)
              child: Icon(iconOverride ?? defaultIcon, color: lightColor, size: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePill() {
      return GestureDetector(
         onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Time selection tapped (placeholder)"), duration: Duration(seconds: 1))
              );
         },
         child: ClipRRect(
           borderRadius: BorderRadius.circular(30),
           child: BackdropFilter(
             filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                 gradient: LinearGradient(colors: [primaryColor.withOpacity(0.2), secondaryColor.withOpacity(0.2)]),
                 borderRadius: BorderRadius.circular(30),
                 border: Border.all(color: primaryColor.withOpacity(0.3), width: 0.5),
               ),
               // Row is NOT const because FaIcon might not be, and color division was used
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   // Requires font_awesome_flutter
                   FaIcon(FontAwesomeIcons.clock, color: secondaryColor, size: 14),
                   const SizedBox(width: 8),
                   const Text("Nyní", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                   const SizedBox(width: 8),
                   // Requires font_awesome_flutter
                   // Using withOpacity for safety instead of custom operator in case it caused issues
                   FaIcon(FontAwesomeIcons.chevronDown, color: lightColor.withOpacity(0.5), size: 12),
                 ],
               ),
             ),
           ),
         ),
      );
  }

  Widget _buildLocationSearch() {
    return Positioned(
      top: 100, left: 20, right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: darkColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 25, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSearchInputRow(
                  primaryColor,
                  "Aktuální poloha",
                  FontAwesomeIcons.times, // Requires font_awesome_flutter
                  _pickupController,
                  readOnly: true,
                  onActionTap: () => _pickupController.clear(),
                ),
                 // FIX: Removed const
                Divider(color: lightColor.withOpacity(0.25), height: 16, thickness: 0.5), // Using withOpacity instead of '/'
                _buildSearchInputRow(
                  secondaryColor,
                  "Kam pojedeme?",
                  FontAwesomeIcons.mapMarkerAlt, // Requires font_awesome_flutter
                  _destinationController,
                  onChanged: (value) => setState(() => _destinationLocation = value),
                  onActionTap: () { /* Maybe trigger search suggestions? */ },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInputRow(Color dotColor, String hint, IconData actionIcon, TextEditingController controller, {bool readOnly = false, VoidCallback? onActionTap, ValueChanged<String>? onChanged}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12, margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle, boxShadow: dotColor == primaryColor ? neonGlowPrimary : neonGlowSecondary),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly || _appState != AppState.idle,
            style: TextStyle(color: lightColor.withOpacity(readOnly ? 0.7 : 1.0), fontWeight: FontWeight.w500),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: lightColor.withOpacity(0.7)),
              border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        IconButton(
          // Requires font_awesome_flutter (used for FaIcon)
          icon: FaIcon(actionIcon, color: lightColor.withOpacity(0.5), size: 16),
          onPressed: _appState == AppState.idle ? onActionTap : null,
          constraints: const BoxConstraints(), padding: EdgeInsets.zero, splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    final screenHeight = MediaQuery.of(context).size.height;
    // Use the same value as DraggableScrollableSheet's initialChildSize
    final initialSheetHeight = screenHeight * 0.35;
    final fabBottomMargin = initialSheetHeight + 20;

    return Positioned(
      bottom: fabBottomMargin,
      right: 20,
      child: ClipRRect(
         borderRadius: BorderRadius.circular(30),
         child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
             child: Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.9), shape: BoxShape.circle, boxShadow: neonGlowPrimary,
              ),
              child: Material(
                 color: Colors.transparent,
                 child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text("Center map tapped (placeholder)"), duration: Duration(seconds: 1))
                       );
                  },
                  // Requires font_awesome_flutter
                  child: const Center(child: FaIcon(FontAwesomeIcons.locationArrow, color: lightColor, size: 20)),
                 ),
               ),
             ),
         ),
      ),
    );
  }

  // --- Bottom Sheet ---

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.35, // MUST MATCH the value used in _resetState fix
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (BuildContext context, ScrollController scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: darkColor.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: neonGlowDark,
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                children: [
                  _buildSheetHandle(),
                  Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24.0),
                     child: AnimatedSwitcher(
                         duration: const Duration(milliseconds: 400),
                         transitionBuilder: (Widget child, Animation<double> animation) {
                           return FadeTransition(opacity: animation, child: child);
                         },
                         child: _buildSheetContent(),
                     ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 48, height: 4, margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [primaryColor.withOpacity(0.5), secondaryColor.withOpacity(0.5)]),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetContent() {
    switch (_appState) {
      case AppState.idle:
        return _buildIdleSheetContent(key: const ValueKey('idle'));
      case AppState.searching:
        return _buildSearchingSheetContent(key: const ValueKey('searching'));
      case AppState.driverAssigned:
        return _buildDriverAssignedSheetContent(key: const ValueKey('driverAssigned'));
      case AppState.onTrip:
        return Center(child: Text("Na cestě...", key: const ValueKey('onTrip')));
    }
  }

  Widget _buildIdleSheetContent({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEstimatedTimePrice(),
        const SizedBox(height: 24),
        // Requires google_fonts
        _buildGradientText("Vyberte si vozidlo", 24, FontWeight.bold, isPoppins: true),
        const SizedBox(height: 20),
        _buildRideOptionsGrid(),
        const SizedBox(height: 24),
        _buildPaymentMethod(),
        const SizedBox(height: 24),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildSearchingSheetContent({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           const SizedBox(
               width: 60,
               height: 60,
               child: CircularProgressIndicator(
                   valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                   strokeWidth: 3,
               )
           ),
           const SizedBox(height: 24),
           Text(
             "Hledání řidiče NeonRide...",
             style: TextStyle(fontSize: 18, color: lightColor.withOpacity(0.8)),
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 30),
            _buildCancelButton("Zrušit hledání"),
        ],
      ),
    );
  }

  Widget _buildDriverAssignedSheetContent({Key? key}) {
    if (_assignedDriver == null) return const SizedBox.shrink();

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        children: [
          Text(
            "${_assignedDriver!.name} je na cestě",
            // Requires google_fonts
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
             "Příjezd za ~${_assignedDriver!.etaMinutes} min",
             style: const TextStyle(fontSize: 16, color: accentColor, fontWeight: FontWeight.w600),
           ),
          const SizedBox(height: 24),
          _buildDriverDetailsCard(_assignedDriver!),
          const SizedBox(height: 24),
          _buildDriverActionButtons(),
          const SizedBox(height: 16),
           _buildCancelButton("Zrušit jízdu"),
        ],
      ),
    );
  }


   Widget _buildDriverDetailsCard(Driver driver) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
         filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
         child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
               gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)]),
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
               children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: primaryColor.withOpacity(0.3),
                    // Requires font_awesome_flutter
                    child: const FaIcon(FontAwesomeIcons.userAstronaut, size: 24, color: lightColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(driver.carModel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                           Text(driver.licensePlate, style: TextStyle(fontSize: 14, color: lightColor.withOpacity(0.8))),
                           Row(
                             children: [
                               // Requires font_awesome_flutter
                               const FaIcon(FontAwesomeIcons.solidStar, color: accentColor, size: 14),
                               const SizedBox(width: 4),
                               Text(driver.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                             ],
                           )
                        ],
                     ),
                  ),
               ],
            ),
         ),
      ),
    );
   }

   Widget _buildDriverActionButtons() {
      return Row(
         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
         children: [
             // Requires font_awesome_flutter
             _buildSmallActionButton(icon: FontAwesomeIcons.solidCommentDots, label: "Zpráva"),
             _buildSmallActionButton(icon: FontAwesomeIcons.phone, label: "Volat"),
             _buildSmallActionButton(icon: FontAwesomeIcons.shareNodes, label: "Sdílet"),
         ],
      );
   }

    Widget _buildSmallActionButton({required IconData icon, required String label}) {
       return GestureDetector(
          onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("$label tapped (placeholder)"), duration: const Duration(seconds: 1))
              );
          },
          child: Column(
             children: [
                 Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: darkColor.withOpacity(0.7),
                       border: Border.all(color: primaryColor.withOpacity(0.4))
                    ),
                    // Requires font_awesome_flutter
                    child: Center(child: FaIcon(icon, color: lightColor, size: 18)),
                 ),
                 const SizedBox(height: 6),
                 Text(label, style: TextStyle(fontSize: 12, color: lightColor.withOpacity(0.8))),
             ],
          ),
       );
    }

  Widget _buildEstimatedTimePrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Předpokládaný příjezd", style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14)),
            Text(
              "${_selectedRideOption?.etaMinutes ?? '-'} min",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("Přibližná cena", style: TextStyle(color: lightColor.withOpacity(0.7), fontSize: 14)),
            _buildGradientText(_selectedRideOption?.price ?? '-', 20, FontWeight.bold),
          ],
        ),
      ],
    );
  }

  Widget _buildGradientText(String text, double fontSize, FontWeight fontWeight, {bool isPoppins = false}) {
     return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(colors: [primaryColor, secondaryColor, accentColor]).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      // Requires google_fonts
      child: Text(text, style: (isPoppins ? GoogleFonts.poppins() : GoogleFonts.inter()).copyWith(fontSize: fontSize, fontWeight: fontWeight, color: Colors.white)),
    );
  }

  Widget _buildRideOptionsGrid() {
    return Wrap(
      spacing: 16, runSpacing: 16,
      children: _availableRides.map((ride) => _buildRideOption(
          ride: ride,
          isSelected: _selectedRideOption?.key == ride.key,
        )).toList(),
    );
  }

  Widget _buildRideOption({required RideOption ride, required bool isSelected}) {
    final Color borderColor = isSelected ? ride.iconColor : darkColor.withOpacity(0.5);
    final List<BoxShadow> glow = isSelected ? _createNeonGlow(ride.iconColor) : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: (constraints.maxWidth / 2) - 8),
          child: ClipRRect(
             borderRadius: BorderRadius.circular(16),
             child: Material(
                 color: Colors.transparent,
                 child: InkWell(
                    onTap: () => _selectRide(ride),
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [darkColor.withOpacity(0.8), darkerColor.withOpacity(0.9)]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor.withOpacity(isSelected ? 0.7 : 0.5), width: isSelected ? 1.5 : 1.0),
                            boxShadow: glow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40, height: 40, margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: ride.iconColor.withOpacity(0.2), shape: BoxShape.circle,
                                      boxShadow: !isSelected ? [BoxShadow(color: ride.iconColor.withOpacity(0.4), blurRadius: 8)] : []
                                    ),
                                    // Requires font_awesome_flutter
                                    child: Center(child: FaIcon(ride.icon, color: ride.iconColor, size: 18)),
                                  ),
                                  Expanded(
                                    child: Text(ride.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? ride.iconColor : lightColor), overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(ride.details, style: TextStyle(fontSize: 12, color: lightColor.withOpacity(0.6))),
                              const SizedBox(height: 8),
                              Text(ride.price, style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                              if (ride.tagText != null && ride.tagIcon != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Requires font_awesome_flutter
                                    FaIcon(ride.tagIcon!, color: successColor, size: 12),
                                    const SizedBox(width: 4),
                                    Text(ride.tagText!, style: const TextStyle(color: successColor, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                 ),
             ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethod() {
     return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text("Payment method tapped (placeholder)"), duration: Duration(seconds: 1))
                );
            },
            borderRadius: BorderRadius.circular(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), secondaryColor.withOpacity(0.1)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                    boxShadow: neonGlowPrimary,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                         Container(
                            width: 40, height: 40, margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(color: primaryColor.withOpacity(0.2), shape: BoxShape.circle),
                            // Requires font_awesome_flutter
                            child: const Center(child: FaIcon(FontAwesomeIcons.creditCard, color: primaryColor, size: 18)),
                         ),
                         Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("Platební metoda", style: TextStyle(fontSize: 14, color: lightColor.withOpacity(0.7))),
                            const Text("•••• 4242", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                         ]),
                      ]),
                      // Requires font_awesome_flutter
                      FaIcon(FontAwesomeIcons.chevronRight, color: lightColor.withOpacity(0.5), size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
     );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _appState == AppState.idle ? _confirmRide : null,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0, backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
      ).copyWith(
         overlayColor: MaterialStateProperty.resolveWith<Color?>(
           (Set<MaterialState> states) {
             if (states.contains(MaterialState.pressed)) return Colors.white.withOpacity(0.1);
             return null;
           },
         ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: _appState == AppState.idle
              ? const LinearGradient(colors: [primaryColor, secondaryColor])
              : LinearGradient(colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.4)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _appState == AppState.idle
              ? [BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 4))]
              : [],
        ),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), alignment: Alignment.center,
          child: Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                 Text(
                  "Potvrdit ${_selectedRideOption?.title ?? ''}",
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: lightColor.withOpacity(_appState == AppState.idle ? 1.0 : 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                 // Requires font_awesome_flutter
                FaIcon(FontAwesomeIcons.arrowRight, color: lightColor.withOpacity(_appState == AppState.idle ? 1.0 : 0.6), size: 16),
             ],
          ),
        ),
      ),
    );
  }

   Widget _buildCancelButton(String text) {
     return OutlinedButton(
        onPressed: _cancelSearchOrTrip,
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor.withOpacity(0.6), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
     );
   }
}

// Helper for dividing colors (opacity) - NOT usable in const contexts
extension ColorAlphaDivide on Color {
  Color operator /(int divisor) {
    if (divisor <= 0) return this;
    return withAlpha(alpha ~/ divisor);
  }
}

/*
Dependencies needed in pubspec.yaml (ensure compatible versions):

dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0        # Or other compatible version
  font_awesome_flutter: ^10.5.0 # Or other compatible version
  cupertino_icons: ^1.0.2

Make sure to run `flutter pub get` successfully!
*/