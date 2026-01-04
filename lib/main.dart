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
  final int coinsPerMinute; // Dakika başına coin
  bool isRunning;
  DateTime? startTime;
  int totalSeconds;

  WorkTask({
    required this.id,
    required this.name,
    required this.createdAt,
    this.coinsPerMinute = 1,
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
        coinsPerMinute: json['coinsPerMinute'] ?? 1,
        isRunning: json['isRunning'] ?? false,
        startTime:
            json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
        totalSeconds: json['totalSeconds'] ?? 0,
      );
}

class RewardTask {
  final String id;
  final String name;
  final int coinCost;
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
        coinCost: json['coinCost'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class Transaction {
  final String id;
  final String description;
  final int amount;
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
        amount: json['amount'],
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
  Future<int> loadBalance() async {
    final prefs = await _prefs;
    return prefs.getInt(_balanceKey) ?? 0;
  }

  Future<void> saveBalance(int balance) async {
    final prefs = await _prefs;
    await prefs.setInt(_balanceKey, balance);
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
  int _coinBalance = 0;
  bool _isLoading = true;

  Timer? _timer;

  List<WorkTask> get workTasks => _workTasks;
  List<RewardTask> get rewardTasks => _rewardTasks;
  List<Transaction> get transactions => _transactions;
  int get coinBalance => _coinBalance;
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
  Future<void> addWorkTask(String name, int coinsPerMinute) async {
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

  Future<int> stopWorkTask(String id) async {
    final task = _workTasks.firstWhere((t) => t.id == id);
    if (!task.isRunning || task.startTime == null) return 0;

    final elapsed = DateTime.now().difference(task.startTime!).inSeconds;
    task.totalSeconds += elapsed;
    task.isRunning = false;
    task.startTime = null;

    // Calculate coins based on custom rate
    int earnedCoins = (elapsed ~/ 60) * task.coinsPerMinute;
    if (earnedCoins == 0 && elapsed >= 30) {
      earnedCoins = task.coinsPerMinute; // Minimum 30 saniye = 1 tur coin
    }

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
  Future<void> addRewardTask(String name, int cost) async {
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
      title: 'TimeMint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4EE6),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A14),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A2E),
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFFD700),
          foregroundColor: Color(0xFF1A1A2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
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

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0A14)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Coin Sol, Profil Sağ
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol: Coin Balance
                    Row(
                      children: [
                        const CoinWidget(size: 44),
                        const SizedBox(width: 12),
                        Text(
                          '${provider.coinBalance}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    // Sağ: Profil Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B4EE6), Color(0xFF9D4EDD)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EE6).withAlpha(100),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Çalışma Görevleri',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zamanlayıcıyı başlat ve coin kazan!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Task List
              Expanded(
                child: provider.workTasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.workTasks.length,
                        itemBuilder: (context, index) {
                          final task = provider.workTasks[index];
                          return WorkTaskCard(task: task);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha(100),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTaskDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Görev Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
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
    final coinController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_task, color: Color(0xFFFFD700)),
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Örn: 2',
                labelText: 'Dakika Başına Coin',
                prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
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
              final coins = int.tryParse(coinController.text.trim()) ?? 1;
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
    final currentSeconds = task.isRunning
        ? task.totalSeconds + provider.getElapsedSeconds(task)
        : task.totalSeconds;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        // Glassmorphism effect
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: task.isRunning
              ? [Colors.white.withAlpha(25), Colors.white.withAlpha(10)]
              : [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: task.isRunning
              ? const Color(0xFFFFD700).withAlpha(100)
              : Colors.white.withAlpha(30),
          width: task.isRunning ? 2 : 1,
        ),
        boxShadow: [
          if (task.isRunning)
            BoxShadow(
              color: const Color(0xFFFFD700).withAlpha(50),
              blurRadius: 20,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 3D Task Icon
                Icon3D(
                  icon: Icons.timer,
                  size: 44,
                  primaryColor: task.isRunning ? const Color(0xFFFFD700) : const Color(0xFF6B4EE6),
                  secondaryColor: task.isRunning ? const Color(0xFFFF8C00) : const Color(0xFF9D4EDD),
                  withGlow: task.isRunning,
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.monetization_on, size: 14, color: Color(0xFFFFD700)),
                          const SizedBox(width: 4),
                          Text(
                            '${task.coinsPerMinute} coin/dk',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menü butonu (Sil / Sıfırla)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  color: const Color(0xFF1A1A2E),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteConfirmation(context, provider);
                    } else if (value == 'reset') {
                      provider.resetWorkTask(task.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.refresh, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Süre sıfırlandı'),
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
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Color(0xFFFFD700)),
                          SizedBox(width: 12),
                          Text('Süreyi Sıfırla'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Görevi Sil', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 20,
                  color: task.isRunning
                      ? const Color(0xFFFFD700)
                      : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTime(currentSeconds),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: task.isRunning
                        ? const Color(0xFFFFD700)
                        : Colors.grey[400],
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    if (task.isRunning) {
                      final earned = await provider.stopWorkTask(task.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.monetization_on,
                                    color: Color(0xFFFFD700)),
                                const SizedBox(width: 8),
                                Text(earned > 0
                                    ? '+$earned Coin kazandın! 🎉'
                                    : 'En az 30 saniye çalışmalısın!'),
                              ],
                            ),
                            backgroundColor: earned > 0
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFE65100),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    } else {
                      provider.startWorkTask(task.id);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: task.isRunning
                        ? const Color(0xFFE53935)
                        : const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  icon: Icon(task.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(
                    task.isRunning ? 'Bitir' : 'Başlat',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            Text('Görevi Sil'),
          ],
        ),
        content: Text('"${task.name}" görevini silmek istediğinize emin misiniz?'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0A14)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Coin Sol, Profil Sağ (same as EarningPage)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Sol: Coin Balance
                    Row(
                      children: [
                        const CoinWidget(size: 44),
                        const SizedBox(width: 12),
                        Text(
                          '${provider.coinBalance}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                    // Sağ: Profil Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B4EE6), Color(0xFF9D4EDD)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EE6).withAlpha(100),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ödül Marketi',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coinlerini harcayarak ödüllerini al!',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.rewardTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.card_giftcard,
                                size: 60,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Henüz ödül yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '+ butonuyla yeni ödül ekle',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.rewardTasks.length,
                        itemBuilder: (context, index) {
                          final task = provider.rewardTasks[index];
                          return RewardTaskCard(task: task);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRewardDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Ödül Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showAddRewardDialog(BuildContext context) {
    final nameController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: Color(0xFFFFD700)),
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
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Örn: 60',
                labelText: 'Coin Bedeli',
                prefixIcon: const Icon(Icons.monetization_on,
                    color: Color(0xFFFFD700)),
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
              final cost = int.tryParse(costController.text.trim()) ?? 0;
              if (name.isNotEmpty && cost > 0) {
                context.read<AppProvider>().addRewardTask(name, cost);
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
                          '${task.coinCost}',
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
                                    'Yetersiz bakiye! ${task.coinCost - provider.coinBalance} coin daha lazım.'),
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
  String _dateFilter = 'Tümü';
  DateTime? _selectedDate;
  final List<String> _filterOptions = ['Tümü', 'Bugün', 'Bu Hafta', 'Bu Ay', 'Tarih Seç'];

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'TARİH SEÇ',
      cancelText: 'İPTAL',
      confirmText: 'TAMAM',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6B4EE6),
              surface: Color(0xFF1A1A2E),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateFilter = 'Tarih Seç';
      });
    }
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    switch (_dateFilter) {
      case 'Bugün':
        return transactions.where((t) =>
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day
        ).toList();
      case 'Bu Hafta':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        return transactions.where((t) => t.date.isAfter(weekStart)).toList();
      case 'Bu Ay':
        return transactions.where((t) =>
          t.date.year == now.year && t.date.month == now.month
        ).toList();
      case 'Tarih Seç':
        if (_selectedDate != null) {
          return transactions.where((t) =>
            t.date.year == _selectedDate!.year &&
            t.date.month == _selectedDate!.month &&
            t.date.day == _selectedDate!.day
          ).toList();
        }
        return transactions;
      default:
        return transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filteredTransactions = _filterTransactions(provider.transactions);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0A2E), Color(0xFF0A0A14)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Balance Header with 3D Coin
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B4EE6),
                      Color(0xFF9D4EDD),
                      Color(0xFFE040FB),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6B4EE6).withAlpha(100),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Toplam Bakiye',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CoinWidget(size: 50, withGlow: false),
                        const SizedBox(width: 12),
                        Text(
                          '${provider.coinBalance}',
                          style: const TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700).withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'TIMEMINT',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD700),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Toplam Kazanç',
                        provider.transactions
                            .where((t) => t.type == TransactionType.earning)
                            .fold(0, (sum, t) => sum + t.amount),
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Toplam Harcama',
                        provider.transactions
                            .where((t) => t.type == TransactionType.spending)
                            .fold(0, (sum, t) => sum + t.amount.abs()),
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Transactions Header with Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text(
                      'Hesap Özeti',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    // Date Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF6B4EE6).withAlpha(60),
                            const Color(0xFF6B4EE6).withAlpha(30),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6B4EE6).withAlpha(80)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _dateFilter,
                          dropdownColor: const Color(0xFF1A1A2E),
                          icon: const Icon(Icons.filter_list, color: Color(0xFFFFD700), size: 18),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          items: _filterOptions.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == 'Tarih Seç') {
                              _pickDate(context);
                            } else if (value != null) {
                              setState(() => _dateFilter = value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '${filteredTransactions.length} işlem',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Transactions List
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(10),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _dateFilter == 'Tümü'
                                  ? 'Henüz işlem yok'
                                  : 'Bu dönemde işlem yok',
                              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          return TransactionCard(transaction: transaction);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withAlpha(15), Colors.white.withAlpha(5)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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
              '${isEarning ? '+' : ''}${transaction.amount}',
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
