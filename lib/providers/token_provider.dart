import 'dart:async';
import 'package:flutter/foundation.dart';
import '../model/user_model.dart';
import '../model/token_model.dart';
import '../repo/token_repo.dart';

/// State for token operations
enum TokenState {
  initial,
  loading,
  loaded,
  error,
  purchasing,
}

/// Provider for token state management
class TokenProvider extends ChangeNotifier {
  final TokenRepository _tokenRepository;

  TokenState _state = TokenState.initial;
  TokenBalance? _balance;
  List<TokenTransactionModel> _transactions = [];
  List<TokenPackage> _packages = [];
  List<SubscriptionPlan> _subscriptionPlans = [];
  String? _errorMessage;
  StreamSubscription<List<TokenTransactionModel>>? _transactionSubscription;

  TokenProvider({TokenRepository? tokenRepository})
      : _tokenRepository = tokenRepository ?? TokenRepository();

  // Getters
  TokenState get state => _state;
  TokenBalance? get balance => _balance;
  List<TokenTransactionModel> get transactions => _transactions;
  List<TokenPackage> get packages => _packages;
  List<SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TokenState.loading;
  bool get isPurchasing => _state == TokenState.purchasing;

  // Balance getters
  int get remainingTokens => _balance?.remainingTokens ?? 0;
  int get totalTokens => _balance?.totalTokens ?? 0;
  int get usedTokens => _balance?.usedTokens ?? 0;
  double get usagePercentage => _balance?.usagePercentage ?? 0;
  bool get hasTokens => _balance?.hasTokens ?? false;

  // Transaction getters
  List<TokenTransactionModel> get recentTransactions =>
      _transactions.take(10).toList();

  List<TokenTransactionModel> get creditTransactions =>
      _transactions.where((t) => t.isCredit).toList();

  List<TokenTransactionModel> get debitTransactions =>
      _transactions.where((t) => t.isDebit).toList();

  /// Load token balance for a user
  Future<void> loadBalance(String userId) async {
    try {
      _setState(TokenState.loading);
      _clearError();

      _balance = await _tokenRepository.getTokenBalance(userId);
      _setState(TokenState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load transaction history
  Future<void> loadTransactions(String userId, {int? limit}) async {
    try {
      _clearError();

      _transactions = await _tokenRepository.getTransactionHistory(
        userId,
        limit: limit,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Subscribe to transaction updates
  void subscribeToTransactions(String userId) {
    _transactionSubscription?.cancel();

    _transactionSubscription =
        _tokenRepository.transactionHistoryStream(userId, limit: 50).listen(
      (transactions) {
        _transactions = transactions;
        notifyListeners();
      },
      onError: (error) {
        _setError(error.toString());
      },
    );
  }

  /// Load available token packages
  Future<void> loadPackages() async {
    try {
      _packages = await _tokenRepository.getTokenPackages();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Load subscription plans
  Future<void> loadSubscriptionPlans() async {
    try {
      _subscriptionPlans = await _tokenRepository.getSubscriptionPlans();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  /// Check if user can afford an operation
  Future<bool> canAfford(String userId, int amount) async {
    try {
      return await _tokenRepository.canAfford(userId, amount);
    } catch (e) {
      return remainingTokens >= amount;
    }
  }

  /// Deduct tokens for a summarization
  Future<TokenTransactionModel?> deductTokens({
    required String userId,
    required int amount,
    required TokenSource source,
    required String referenceId,
    String? description,
  }) async {
    try {
      _clearError();

      final transaction = await _tokenRepository.deductTokens(
        userId: userId,
        amount: amount,
        source: source,
        referenceId: referenceId,
        description: description,
      );

      if (transaction != null) {
        // Update local balance
        _balance = _balance?.copyWith(
          usedTokens: (_balance!.usedTokens) + amount,
        );
        _transactions = [transaction, ..._transactions];
        notifyListeners();
      }

      return transaction;
    } on InsufficientTokensException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Add tokens (for purchases, bonuses, etc.)
  Future<TokenTransactionModel?> addTokens({
    required String userId,
    required int amount,
    required TokenSource source,
    String? referenceId,
    String? description,
  }) async {
    try {
      _clearError();

      final transaction = await _tokenRepository.addTokens(
        userId: userId,
        amount: amount,
        source: source,
        referenceId: referenceId,
        description: description,
      );

      // Update local balance
      _balance = _balance?.copyWith(
        totalTokens: (_balance!.totalTokens) + amount,
        lastRefreshedAt: DateTime.now(),
      );
      _transactions = [transaction, ..._transactions];
      notifyListeners();

      return transaction;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Purchase token package
  Future<bool> purchasePackage({
    required String userId,
    required TokenPackage package,
    required String paymentReferenceId,
  }) async {
    try {
      _setState(TokenState.purchasing);
      _clearError();

      final transaction = await _tokenRepository.purchaseTokenPackage(
        userId: userId,
        package: package,
        paymentReferenceId: paymentReferenceId,
      );

      // Update local balance
      _balance = _balance?.copyWith(
        totalTokens: (_balance!.totalTokens) + package.tokenAmount,
        lastRefreshedAt: DateTime.now(),
      );
      _transactions = [transaction, ..._transactions];
      _setState(TokenState.loaded);

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Add signup bonus
  Future<bool> addSignupBonus(String userId) async {
    try {
      await _tokenRepository.addSignupBonus(userId);
      await loadBalance(userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Add referral bonus
  Future<bool> addReferralBonus({
    required String userId,
    required String referredUserId,
  }) async {
    try {
      await _tokenRepository.addReferralBonus(
        userId: userId,
        referredUserId: referredUserId,
      );
      await loadBalance(userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>> getUsageStatistics(String userId) async {
    try {
      return await _tokenRepository.getUsageStatistics(userId);
    } catch (e) {
      _setError(e.toString());
      return {};
    }
  }

  /// Refresh token data
  Future<void> refresh(String userId) async {
    await Future.wait([
      loadBalance(userId),
      loadTransactions(userId),
    ]);
  }

  /// Clear all data (for logout)
  void clear() {
    _transactionSubscription?.cancel();
    _balance = null;
    _transactions = [];
    _packages = [];
    _subscriptionPlans = [];
    _errorMessage = null;
    _state = TokenState.initial;
    notifyListeners();
  }

  /// Set state and notify listeners
  void _setState(TokenState state) {
    _state = state;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    _state = TokenState.error;
    notifyListeners();
  }

  /// Clear error
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }
}
