import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'blocs/dashboard/dashboard_bloc.dart';
import 'blocs/dashboard/dashboard_event.dart';
import 'blocs/scanner/scanner_bloc.dart';
import 'repositories/document_repository.dart';
import 'services/scanner_service.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FolioApp());
}

class FolioApp extends StatelessWidget {
  const FolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => DocumentRepository()),
        RepositoryProvider(create: (context) => ScannerService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => DashboardBloc(
              repository: context.read<DocumentRepository>(),
            )..add(LoadDashboard()),
          ),
          BlocProvider(
            create: (context) => ScannerBloc(
              repository: context.read<DocumentRepository>(),
              scannerService: context.read<ScannerService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Folio',
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.light, // Force light mode to show the violet theme
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF9C27B0), // Vibrant Violet
              primary: const Color(0xFF9C27B0),
              onPrimary: Colors.white,
              secondary: const Color(0xFFE1BEE7), // Light Violet
              surface: const Color(0xFFFDFBFF), // Very subtle violet-tinted white
              brightness: Brightness.light,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFFDFBFF),
              foregroundColor: Color(0xFF211924),
              elevation: 0,
              centerTitle: true,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2D5AF0),
              primary: const Color(0xFF3B82F6),
              secondary: const Color(0xFF2DD4BF),
              brightness: Brightness.dark,
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}