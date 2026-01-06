import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

enum TransactionType { earning, spending }

class WorkTask {
  final String id;
  final String name;
  final DateTime createdAt;
  final double coinsPerMinute; // Dakika başına coin
  bool isRunning;
  DateTime? startTime;
  int totalSeconds;

  WorkTask({
    required this.id,
    required this.name,
    required this.createdAt,
    this.coinsPerMinute = 1.0,
    this.isRunning = false,
    this.startTime,
    this.totalSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'coinsPerMinute': coinsPerMinute,
        'isRunning': isRunning,
        'startTime': startTime?.toIso8601String(),
        'totalSeconds': totalSeconds,
      };

  factory WorkTask.fromJson(Map<String, dynamic> json) => WorkTask(
        id: json['id'],
        name: json['name'],
        createdAt: DateTime.parse(json['createdAt']),
        coinsPerMinute: (json['coinsPerMinute'] ?? 1).toDouble(),
        isRunning: json['isRunning'] ?? false,
        startTime:
            json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
        totalSeconds: json['totalSeconds'] ?? 0,
      );
}

class RewardTask {
  final String id;
  final String name;
  final double coinCost;
  final DateTime createdAt;

  RewardTask({
    required this.id,
    required this.name,
    required this.coinCost,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'coinCost': coinCost,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RewardTask.fromJson(Map<String, dynamic> json) => RewardTask(
        id: json['id'],
        name: json['name'],
        coinCost: (json['coinCost']).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'type': type.name,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: (json['amount']).toDouble(),
        date: DateTime.parse(json['date']),
        type: TransactionType.values.byName(json['type']),
      );
}

// ============================================================================
// 3D COIN WIDGET
// ============================================================================

class CoinWidget extends StatelessWidget {
  final double size;
  final bool withGlow;

  const CoinWidget({super.key, this.size = 40, this.withGlow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [
            Color(0xFFFFE566), // Bright gold highlight
            Color(0xFFFFD700), // Gold
            Color(0xFFFF8C00), // Deep orange
            Color(0xFFCC7000), // Dark gold edge
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD700).withAlpha(150),
                  blurRadius: size * 0.5,
                  spreadRadius: size * 0.1,
                ),
                BoxShadow(
                  color: const Color(0xFFFF8C00).withAlpha(80),
                  blurRadius: size * 0.8,
                  spreadRadius: size * 0.2,
                ),
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main icon
          Icon(
            Icons.access_time_filled,
            size: size * 0.55,
            color: Colors.white.withAlpha(230),
          ),
          // Shine effect
          Positioned(
            top: size * 0.1,
            left: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(180),
                    Colors.white.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// NEON BUTTON WIDGET
// ============================================================================

class NeonButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color color;
  final bool isSmall;

  const NeonButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.color = const Color(0xFF4CAF50),
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(150),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 16 : 24,
              vertical: isSmall ? 10 : 14,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withAlpha(200)],
              ),
              borderRadius: BorderRadius.circular(isSmall ? 12 : 16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: isSmall ? 18 : 22),
                  SizedBox(width: isSmall ? 6 : 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmall ? 14 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3D ICON WIDGET (for tasks and rewards)
// ============================================================================

class Icon3D extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color primaryColor;
  final Color secondaryColor;
  final bool withGlow;

  const Icon3D({
    super.key,
    required this.icon,
    this.size = 48,
    this.primaryColor = const Color(0xFF6B4EE6),
    this.secondaryColor = const Color(0xFF9D4EDD),
    this.withGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            secondaryColor,
          ],
        ),
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: primaryColor.withAlpha(120),
                  blurRadius: size * 0.4,
                  spreadRadius: size * 0.05,
                ),
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: size * 0.55, color: Colors.white),
          // Shine effect
          Positioned(
            top: size * 0.1,
            left: size * 0.15,
            child: Container(
              width: size * 0.3,
              height: size * 0.1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha(150),
                    Colors.white.withAlpha(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STORAGE SERVICE
// ============================================================================

class StorageService {
  static const String _workTasksKey = 'work_tasks';
  static const String _rewardTasksKey = 'reward_tasks';
  static const String _transactionsKey = 'transactions';
  static const String _balanceKey = 'coin_balance';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // Work Tasks
  Future<List<WorkTask>> loadWorkTasks() async {
    final prefs = await _prefs;
    final data = prefs.getString(_workTasksKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => WorkTask.fromJson(e)).toList();
  }

  Future<void> saveWorkTasks(List<WorkTask> tasks) async {
    final prefs = await _prefs;
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_workTasksKey, data);
  }

  // Reward Tasks
  Future<List<RewardTask>> loadRewardTasks() async {
    final prefs = await _prefs;
    final data = prefs.getString(_rewardTasksKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => RewardTask.fromJson(e)).toList();
  }

  Future<void> saveRewardTasks(List<RewardTask> tasks) async {
    final prefs = await _prefs;
    final data = jsonEncode(tasks.map((e) => e.toJson()).toList());
    await prefs.setString(_rewardTasksKey, data);
  }

  // Transactions
  Future<List<Transaction>> loadTransactions() async {
    final prefs = await _prefs;
    final data = prefs.getString(_transactionsKey);
    if (data == null) return [];
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => Transaction.fromJson(e)).toList();
  }

  Future<void> saveTransactions(List<Transaction> transactions) async {
    final prefs = await _prefs;
    final data = jsonEncode(transactions.map((e) => e.toJson()).toList());
    await prefs.setString(_transactionsKey, data);
  }

  // Balance
  Future<double> loadBalance() async {
    final prefs = await _prefs;
    return prefs.getDouble(_balanceKey) ?? 0.0;
  }

  Future<void> saveBalance(double balance) async {
    final prefs = await _prefs;
    await prefs.setDouble(_balanceKey, balance);
  }
}

// ============================================================================
// APP PROVIDER (STATE MANAGEMENT)
// ============================================================================

class AppProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final Uuid _uuid = const Uuid();

  List<WorkTask> _workTasks = [];
  List<RewardTask> _rewardTasks = [];
  List<Transaction> _transactions = [];
  double _coinBalance = 0.0;
  bool _isLoading = true;

  Timer? _timer;

  List<WorkTask> get workTasks => _workTasks;
  List<RewardTask> get rewardTasks => _rewardTasks;
  List<Transaction> get transactions => _transactions;
  double get coinBalance => _coinBalance;
  bool get isLoading => _isLoading;

  AppProvider() {
    _loadData();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool hasRunning = _workTasks.any((t) => t.isRunning);
      if (hasRunning) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    _workTasks = await _storage.loadWorkTasks();
    _rewardTasks = await _storage.loadRewardTasks();
    _transactions = await _storage.loadTransactions();
    _coinBalance = await _storage.loadBalance();

    // Reset running tasks on app restart
    for (var task in _workTasks) {
      if (task.isRunning) {
        task.isRunning = false;
        task.startTime = null;
      }
    }
    await _storage.saveWorkTasks(_workTasks);

    _isLoading = false;
    notifyListeners();
  }

  // Work Task Methods
  Future<void> addWorkTask(String name, double coinsPerMinute) async {
    final task = WorkTask(
      id: _uuid.v4(),
      name: name,
      createdAt: DateTime.now(),
      coinsPerMinute: coinsPerMinute,
    );
    _workTasks.add(task);
    await _storage.saveWorkTasks(_workTasks);
    notifyListeners();
  }

  Future<void> deleteWorkTask(String id) async {
    _workTasks.removeWhere((t) => t.id == id);
    await _storage.saveWorkTasks(_workTasks);
    notifyListeners();
  }

  // Süreyi sıfırla
  Future<void> resetWorkTask(String id) async {
    final task = _workTasks.firstWhere((t) => t.id == id);
    task.totalSeconds = 0;
    task.isRunning = false;
    task.startTime = null;
    await _storage.saveWorkTasks(_workTasks);
    notifyListeners();
  }

  Future<void> startWorkTask(String id) async {
    final task = _workTasks.firstWhere((t) => t.id == id);
    task.isRunning = true;
    task.startTime = DateTime.now();
    await _storage.saveWorkTasks(_workTasks);
    notifyListeners();
  }

  Future<double> stopWorkTask(String id) async {
    final task = _workTasks.firstWhere((t) => t.id == id);
    if (!task.isRunning || task.startTime == null) return 0.0;

    final elapsed = DateTime.now().difference(task.startTime!).inSeconds;
    task.totalSeconds += elapsed;
    task.isRunning = false;
    task.startTime = null;

    // Hassas coin hesaplama: dakikada başına coin * (saniye / 60)
    double earnedCoins = task.coinsPerMinute * (elapsed / 60.0);

    if (earnedCoins > 0) {
      _coinBalance += earnedCoins;
      _transactions.insert(
        0,
        Transaction(
          id: _uuid.v4(),
          description: '${task.name} - ${_formatDuration(elapsed)}',
          amount: earnedCoins,
          date: DateTime.now(),
          type: TransactionType.earning,
        ),
      );
      await _storage.saveTransactions(_transactions);
      await _storage.saveBalance(_coinBalance);
    }

    await _storage.saveWorkTasks(_workTasks);
    notifyListeners();
    return earnedCoins;
  }

  int getElapsedSeconds(WorkTask task) {
    if (!task.isRunning || task.startTime == null) return 0;
    return DateTime.now().difference(task.startTime!).inSeconds;
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}sa ${minutes}dk';
    } else if (minutes > 0) {
      return '${minutes}dk ${secs}sn';
    } else {
      return '${secs}sn';
    }
  }

  // Reward Task Methods
  Future<void> addRewardTask(String name, double cost) async {
    final task = RewardTask(
      id: _uuid.v4(),
      name: name,
      coinCost: cost,
      createdAt: DateTime.now(),
    );
    _rewardTasks.add(task);
    await _storage.saveRewardTasks(_rewardTasks);
    notifyListeners();
  }

  Future<void> deleteRewardTask(String id) async {
    _rewardTasks.removeWhere((t) => t.id == id);
    await _storage.saveRewardTasks(_rewardTasks);
    notifyListeners();
  }

  Future<bool> purchaseReward(String id) async {
    final task = _rewardTasks.firstWhere((t) => t.id == id);
    if (_coinBalance < task.coinCost) {
      return false;
    }

    _coinBalance -= task.coinCost;
    _transactions.insert(
      0,
      Transaction(
        id: _uuid.v4(),
        description: task.name,
        amount: -task.coinCost,
        date: DateTime.now(),
        type: TransactionType.spending,
      ),
    );

    await _storage.saveTransactions(_transactions);
    await _storage.saveBalance(_coinBalance);
    notifyListeners();
    return true;
  }
}

// ============================================================================
// MAIN APP
// ============================================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF25F425), // Neon green
        scaffoldBackgroundColor: const Color(0xFF18181B), // Very dark gray
        cardColor: const Color(0xFF27272A), // Dark gray surface
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF25F425),
          secondary: Color(0xFF25F425),
          surface: Color(0xFF27272A),
          background: Color(0xFF18181B),
          onPrimary: Color(0xFF18181B),
          onSecondary: Color(0xFF18181B),
          onSurface: Colors.white,
          onBackground: Colors.white,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF27272A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF25F425),
          foregroundColor: Color(0xFF18181B),
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF18181B),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
      home: const WelcomeScreen(),
    );
  }
}

// ============================================================================
// WELCOME / LOGIN SCREEN
// ============================================================================

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _checkExistingUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name');
    if (userName != null && userName.isNotEmpty && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _saveAndContinue() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _nameController.text.trim());
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A14), Color(0xFF1A1A2E), Color(0xFF0A0A14)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Neon Coin Logo
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withAlpha(150),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF8C00).withAlpha(100),
                        blurRadius: 60,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.toll,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                // App Title with Neon Effect
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF8C00), Color(0xFFFFD700)],
                  ).createShader(bounds),
                  child: const Text(
                    'TIME',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: Colors.white,
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF6B4EE6), Color(0xFF9D4EDD)],
                  ).createShader(bounds),
                  child: const Text(
                    'MINT',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Çalış. Kazan. Harca.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 60),
                // Name Input
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EE6).withAlpha(50),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Adınızı girin',
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF6B4EE6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: const Color(0xFF6B4EE6).withAlpha(100)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Start Button with Neon Glow
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B4EE6), Color(0xFF9D4EDD)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EE6).withAlpha(150),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveAndContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'BAŞLA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN WITH BOTTOM NAVIGATION
// ============================================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    EarningPage(),
    MarketPage(),
    WalletPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withAlpha(15),
              Colors.white.withAlpha(8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(20)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B4EE6).withAlpha(30),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.timer_outlined, Icons.timer, 'Görevler'),
            _buildNavItem(1, Icons.storefront_outlined, Icons.storefront, 'Mağaza'),
            _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, 'Cüzdan'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF6B4EE6).withAlpha(80),
                    const Color(0xFF6B4EE6).withAlpha(40),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B4EE6).withAlpha(100),
                    blurRadius: 15,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? const Color(0xFFFFD700) : Colors.grey[500],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFFD700) : Colors.grey[500],
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EARNING PAGE (WORK TASKS)
// ============================================================================

class EarningPage extends StatelessWidget {
  const EarningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final runningTask = provider.workTasks.firstWhere(
      (t) => t.isRunning,
      orElse: () => WorkTask(id: '', name: '', createdAt: DateTime.now()),
    );
    final hasRunningTask = runningTask.id.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Focus',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'EARN MODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  // Coin Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      border: Border.all(
                        color: const Color(0xFF25F425).withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF25F425).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          provider.coinBalance.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF25F425),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                children: [
                  // In Progress Section
                  if (hasRunningTask) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25F425),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'IN PROGRESS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25F425),
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRunningTaskCard(context, runningTask, provider),
                    const SizedBox(height: 32),
                  ],
                  
                  // Your Tasks Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Tasks',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'VIEW ALL',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF25F425),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Task List
                  if (provider.workTasks.isEmpty)
                    _buildEmptyState()
                  else
                    ...provider.workTasks
                        .where((t) => !t.isRunning)
                        .map((task) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: WorkTaskCard(task: task),
                            )),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF25F425).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddTaskDialog(context),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }

  Widget _buildRunningTaskCard(BuildContext context, WorkTask task, AppProvider provider) {
    final currentSeconds = task.totalSeconds + provider.getElapsedSeconds(task);
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF25F425),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25F425).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25F425).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.code,
                        color: Color(0xFF25F425),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${task.coinsPerMinute.toStringAsFixed(1)} coins/min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF25F425).withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25F425).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sync,
                        color: Color(0xFF25F425),
                        size: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Duration',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(currentSeconds),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontFeatures: [FontFeature.tabularFigures()],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        final earned = await provider.stopWorkTask(task.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.monetization_on, color: Color(0xFF25F425)),
                                  const SizedBox(width: 8),
                                  Text('+${earned.toStringAsFixed(2)} Coin kazandın! 🎉'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF27272A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.stop_circle, size: 20),
                      label: const Text('Stop'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Progress bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (currentSeconds % 60) / 60,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF25F425),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(Icons.timer_outlined, size: 60, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Text('Henüz görev yok', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('+ butonuyla yeni görev ekle', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final nameController = TextEditingController();
    final coinController = TextEditingController(text: '1.0');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_task, color: Color(0xFF25F425)),
            SizedBox(width: 12),
            Text('Yeni Çalışma Görevi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: Matematik Çöz',
                labelText: 'Görev Adı',
                prefixIcon: const Icon(Icons.task_alt),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: coinController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Örn: 2',
                labelText: 'Dakika Başına Coin',
                prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFF25F425)),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                helperText: '1 dakika = belirtilen coin',
                helperStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final coins = double.tryParse(coinController.text.trim()) ?? 1.0;
              if (name.isNotEmpty && coins > 0) {
                context.read<AppProvider>().addWorkTask(name, coins);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EE6),
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

class WorkTaskCard extends StatelessWidget {
  final WorkTask task;

  const WorkTaskCard({super.key, required this.task});

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.menu_book,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.bolt,
                      size: 14,
                      color: Color(0xFF25F425),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${task.coinsPerMinute.toStringAsFixed(1)} coins/min',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF25F425),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Start Button
          Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25F425).withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: FilledButton(
              onPressed: () {
                provider.startWorkTask(task.id);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25F425),
                foregroundColor: const Color(0xFF18181B),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Görevi Sil'),
          ],
        ),
        content: Text('"${task.name}" görevi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteWorkTask(task.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.delete, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Görev silindi'),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MARKET PAGE (REWARDS)
// ============================================================================

class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Market',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SPEND MODE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  // Coin Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      border: Border.all(
                        color: const Color(0xFFfb923c).withOpacity(0.2),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFfb923c).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          provider.coinBalance.toStringAsFixed(0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFfb923c),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: provider.rewardTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                      children: [
                        // Rewards Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: provider.rewardTasks.length,
                          itemBuilder: (context, index) {
                            final task = provider.rewardTasks[index];
                            return _buildRewardCard(context, task, provider);
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Custom Reward Card
                        _buildCustomRewardCard(context),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, RewardTask task, AppProvider provider) {
    final canAfford = provider.coinBalance >= task.coinCost;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard,
                size: 48,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Reward',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Bottom: Cost + Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    task.coinCost.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFfb923c),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: canAfford
                      ? [
                          BoxShadow(
                            color: const Color(0xFFfb923c).withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: FilledButton(
                  onPressed: canAfford
                      ? () async {
                          final success = await provider.purchaseReward(task.id);
                          if (context.mounted && success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.celebration, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text('${task.name} ödülünü aldın! 🎉')),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFfb923c),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: canAfford ? const Color(0xFFfb923c) : Colors.grey[800],
                    foregroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Buy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomRewardCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFfb923c).withOpacity(0.2),
            const Color(0xFF27272A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFfb923c).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFfb923c).withOpacity(0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFfb923c).withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.redeem,
              color: Color(0xFFfb923c),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Custom Reward',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Create your own reward.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF27272A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFfb923c).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => _showAddRewardDialog(context),
              icon: const Icon(
                Icons.add,
                color: Color(0xFFfb923c),
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(Icons.card_giftcard, size: 60, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Text('Henüz ödül yok', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Özel ödül oluştur', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }

  void _showAddRewardDialog(BuildContext context) {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF27272A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFfb923c)),
            SizedBox(width: 12),
            Text('Yeni Ödül'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: TV İzle',
                labelText: 'Ödül Adı',
                prefixIcon: const Icon(Icons.emoji_events),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Örn: 100',
                labelText: 'Maliyet (Coin)',
                prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFfb923c)),
                filled: true,
                fillColor: const Color(0xFF0D0D1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final cost = double.tryParse(costController.text.trim()) ?? 0.0;
              if (name.isNotEmpty && cost > 0) {
                context.read<AppProvider>().addRewardTask(name, cost);
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFfb923c),
              foregroundColor: const Color(0xFF18181B),
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
class RewardTaskCard extends StatelessWidget {
  final RewardTask task;

  const RewardTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final canAfford = provider.coinBalance >= task.coinCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 3D Reward Icon
            const Icon3D(
              icon: Icons.card_giftcard,
              size: 50,
              primaryColor: Color(0xFFE040FB),
              secondaryColor: Color(0xFF9D4EDD),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CoinWidget(size: 18, withGlow: false),
                        const SizedBox(width: 6),
                      Text(
                          '${task.coinCost.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    if (canAfford) {
                      final success = await provider.purchaseReward(task.id);
                      if (context.mounted && success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.celebration,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Expanded(child: Text('${task.name} ödülünü aldın! 🎉')),
                              ],
                            ),
                            backgroundColor: const Color(0xFF6B4EE6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    'Yetersiz bakiye! ${(task.coinCost - provider.coinBalance).toStringAsFixed(2)} coin daha lazım.'),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFFE53935),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: canAfford
                        ? const Color(0xFF6B4EE6)
                        : Colors.grey[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(canAfford ? Icons.shopping_cart : Icons.lock),
                  label: const Text('Satın Al'),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(context, provider),
                  child: Text(
                    'Sil',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Text('Ödülü Sil'),
          ],
        ),
        content: Text('"${task.name}" ödülünü silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              provider.deleteRewardTask(task.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WALLET PAGE (BALANCE & HISTORY)
// ============================================================================

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Group transactions by date
    final Map<String, List<Transaction>> groupedTransactions = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    for (final transaction in provider.transactions) {
      final txDate = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
      String key;
      if (txDate == today) {
        key = 'TODAY';
      } else if (txDate == yesterday) {
        key = 'YESTERDAY';
      } else if (txDate.isAfter(today.subtract(const Duration(days: 7)))) {
        key = 'LAST WEEK';
      } else {
        key = DateFormat('MMMM yyyy', 'tr_TR').format(transaction.date).toUpperCase();
      }
      groupedTransactions.putIfAbsent(key, () => []);
      groupedTransactions[key]!.add(transaction);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF18181B),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wallet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'BALANCE & HISTORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  // Notification Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF27272A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.05),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                children: [
                  // Balance Card
                  _buildBalanceCard(provider),
                  
                  const SizedBox(height: 32),
                  
                  // Transaction History Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Row(
                            children: [
                              Text(
                                'FILTER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF25F425),
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.filter_list,
                                color: Color(0xFF25F425),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Transaction List
                  if (provider.transactions.isEmpty)
                    _buildEmptyState()
                  else
                    ...groupedTransactions.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
                            child: Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          ...entry.value.map((tx) => _buildTransactionItem(tx)),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          // Glow effect behind coin
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF25F425).withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              // Coin icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF25F425).withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25F425).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🪙', style: TextStyle(fontSize: 32)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance Amount
          Text(
            provider.coinBalance.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Coins Available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF25F425).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_circle, size: 18),
                  label: const Text('Top Up'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25F425),
                    foregroundColor: const Color(0xFF18181B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.redeem, size: 18),
                label: const Text('Redeem'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isEarning = transaction.type == TransactionType.earning;
    final timeFormat = DateFormat('HH:mm', 'tr_TR');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27272A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarning 
                  ? const Color(0xFF25F425).withOpacity(0.1)
                  : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEarning ? Icons.check_circle : Icons.shopping_bag,
              color: isEarning ? const Color(0xFF25F425) : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${isEarning ? "Focus Session" : "Purchase"} • ${timeFormat.format(transaction.date)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Text(
            '${isEarning ? "+" : "-"}${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              color: isEarning ? const Color(0xFF25F425) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: Icon(Icons.receipt_long, size: 60, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          Text('Henüz işlem yok', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Görev tamamlayarak coin kazan', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
class TransactionCard extends StatelessWidget {
  final Transaction transaction;

  const TransactionCard({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isEarning = transaction.type == TransactionType.earning;
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEarning
                  ? Colors.green.withAlpha(40)
                  : Colors.red.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isEarning ? Icons.add_circle : Icons.remove_circle,
              color: isEarning ? Colors.green : Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  dateFormat.format(transaction.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isEarning
                  ? Colors.green.withAlpha(30)
                  : Colors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${isEarning ? '+' : ''}${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isEarning ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
