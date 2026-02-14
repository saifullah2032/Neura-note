import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../model/user_model.dart';
import '../model/token_model.dart';

/// Repository for token operations
class TokenRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  TokenRepository({
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  /// Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _transactionsCollection =>
      _firestore.collection('tokenTransactions');

  CollectionReference<Map<String, dynamic>> get _packagesCollection =>
      _firestore.collection('tokenPackages');

  CollectionReference<Map<String, dynamic>> get _subscriptionsCollection =>
      _firestore.collection('subscriptionPlans');

  /// Get user's token balance
  Future<TokenBalance?> getTokenBalance(String userId) async {
    final snapshot = await _usersCollection.doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;

    final userData = snapshot.data()!;
    if (userData['tokenBalance'] == null) return const TokenBalance();

    return TokenBalance.fromJson(
        userData['tokenBalance'] as Map<String, dynamic>);
  }

  /// Update user's token balance
  Future<void> updateTokenBalance(String userId, TokenBalance balance) async {
    await _usersCollection.doc(userId).update({
      'tokenBalance': balance.toJson(),
    });
  }

  /// Deduct tokens for a summarization
  Future<TokenTransactionModel?> deductTokens({
    required String userId,
    required int amount,
    required TokenSource source,
    required String referenceId,
    String? description,
  }) async {
    // Get current balance
    final currentBalance = await getTokenBalance(userId);
    if (currentBalance == null) return null;

    // Check if user has enough tokens
    if (currentBalance.remainingTokens < amount) {
      throw InsufficientTokensException(
        'Not enough tokens. Required: $amount, Available: ${currentBalance.remainingTokens}',
      );
    }

    // Calculate new balance
    final newUsedTokens = currentBalance.usedTokens + amount;
    final newBalance = currentBalance.copyWith(usedTokens: newUsedTokens);

    // Create transaction record
    final transaction = TokenTransactionModel(
      id: _uuid.v4(),
      userId: userId,
      type: TokenTransactionType.debit,
      source: source,
      amount: amount,
      balanceBefore: currentBalance.remainingTokens,
      balanceAfter: newBalance.remainingTokens,
      referenceId: referenceId,
      description: description ?? 'Summarization',
      createdAt: DateTime.now(),
    );

    // Execute in a transaction for consistency
    await _firestore.runTransaction((txn) async {
      txn.update(_usersCollection.doc(userId), {
        'tokenBalance': newBalance.toJson(),
      });
      txn.set(_transactionsCollection.doc(transaction.id), transaction.toJson());
    });

    return transaction;
  }

  /// Add tokens (credit)
  Future<TokenTransactionModel> addTokens({
    required String userId,
    required int amount,
    required TokenSource source,
    String? referenceId,
    String? description,
  }) async {
    // Get current balance
    final currentBalance = await getTokenBalance(userId) ?? const TokenBalance();

    // Calculate new balance
    final newTotalTokens = currentBalance.totalTokens + amount;
    final newBalance = currentBalance.copyWith(
      totalTokens: newTotalTokens,
      lastRefreshedAt: DateTime.now(),
    );

    // Create transaction record
    final transaction = TokenTransactionModel(
      id: _uuid.v4(),
      userId: userId,
      type: TokenTransactionType.credit,
      source: source,
      amount: amount,
      balanceBefore: currentBalance.remainingTokens,
      balanceAfter: newBalance.remainingTokens,
      referenceId: referenceId,
      description: description ?? source.displayName,
      createdAt: DateTime.now(),
    );

    // Execute in a transaction for consistency
    await _firestore.runTransaction((txn) async {
      txn.update(_usersCollection.doc(userId), {
        'tokenBalance': newBalance.toJson(),
      });
      txn.set(_transactionsCollection.doc(transaction.id), transaction.toJson());
    });

    return transaction;
  }

  /// Add bonus tokens
  Future<TokenTransactionModel> addBonusTokens({
    required String userId,
    required int amount,
    required String description,
    String? referenceId,
  }) async {
    final currentBalance = await getTokenBalance(userId) ?? const TokenBalance();

    final newTotalTokens = currentBalance.totalTokens + amount;
    final newBalance = currentBalance.copyWith(
      totalTokens: newTotalTokens,
      lastRefreshedAt: DateTime.now(),
    );

    final transaction = TokenTransactionModel(
      id: _uuid.v4(),
      userId: userId,
      type: TokenTransactionType.bonus,
      source: TokenSource.dailyBonus,
      amount: amount,
      balanceBefore: currentBalance.remainingTokens,
      balanceAfter: newBalance.remainingTokens,
      referenceId: referenceId,
      description: description,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((txn) async {
      txn.update(_usersCollection.doc(userId), {
        'tokenBalance': newBalance.toJson(),
      });
      txn.set(_transactionsCollection.doc(transaction.id), transaction.toJson());
    });

    return transaction;
  }

  /// Refund tokens
  Future<TokenTransactionModel> refundTokens({
    required String userId,
    required int amount,
    required String referenceId,
    String? description,
  }) async {
    final currentBalance = await getTokenBalance(userId) ?? const TokenBalance();

    // Reduce used tokens (refund)
    final newUsedTokens = (currentBalance.usedTokens - amount).clamp(0, currentBalance.totalTokens);
    final newBalance = currentBalance.copyWith(usedTokens: newUsedTokens);

    final transaction = TokenTransactionModel(
      id: _uuid.v4(),
      userId: userId,
      type: TokenTransactionType.refund,
      source: TokenSource.admin,
      amount: amount,
      balanceBefore: currentBalance.remainingTokens,
      balanceAfter: newBalance.remainingTokens,
      referenceId: referenceId,
      description: description ?? 'Refund',
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((txn) async {
      txn.update(_usersCollection.doc(userId), {
        'tokenBalance': newBalance.toJson(),
      });
      txn.set(_transactionsCollection.doc(transaction.id), transaction.toJson());
    });

    return transaction;
  }

  /// Get transaction history
  Future<List<TokenTransactionModel>> getTransactionHistory(
    String userId, {
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TokenTransactionModel.fromJson(doc.data()))
        .toList();
  }

  /// Stream of transaction history
  Stream<List<TokenTransactionModel>> transactionHistoryStream(
    String userId, {
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => TokenTransactionModel.fromJson(doc.data()))
        .toList());
  }

  /// Get transactions by type
  Future<List<TokenTransactionModel>> getTransactionsByType(
    String userId,
    TokenTransactionType type, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _transactionsCollection
        .where('userId', isEqualTo: userId)
        .where('type', isEqualTo: type.value)
        .orderBy('createdAt', descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => TokenTransactionModel.fromJson(doc.data()))
        .toList();
  }

  /// Get available token packages
  Future<List<TokenPackage>> getTokenPackages() async {
    final snapshot = await _packagesCollection
        .orderBy('tokenAmount', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => TokenPackage.fromJson(doc.data()))
        .toList();
  }

  /// Get subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final snapshot = await _subscriptionsCollection
        .orderBy('monthlyPrice', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => SubscriptionPlan.fromJson(doc.data()))
        .toList();
  }

  /// Purchase token package
  Future<TokenTransactionModel> purchaseTokenPackage({
    required String userId,
    required TokenPackage package,
    required String paymentReferenceId,
  }) async {
    return addTokens(
      userId: userId,
      amount: package.tokenAmount,
      source: TokenSource.purchase,
      referenceId: paymentReferenceId,
      description: 'Purchased ${package.name}',
    );
  }

  /// Add signup bonus
  Future<TokenTransactionModel> addSignupBonus(String userId) async {
    return addTokens(
      userId: userId,
      amount: 100, // Default signup bonus
      source: TokenSource.signup,
      description: 'Welcome bonus',
    );
  }

  /// Add referral bonus
  Future<TokenTransactionModel> addReferralBonus({
    required String userId,
    required String referredUserId,
  }) async {
    return addBonusTokens(
      userId: userId,
      amount: 50, // Default referral bonus
      description: 'Referral bonus',
      referenceId: referredUserId,
    );
  }

  /// Check if user can afford an operation
  Future<bool> canAfford(String userId, int amount) async {
    final balance = await getTokenBalance(userId);
    return balance != null && balance.remainingTokens >= amount;
  }

  /// Get token usage statistics
  Future<Map<String, dynamic>> getUsageStatistics(String userId) async {
    final transactions = await getTransactionHistory(userId);

    int totalCredits = 0;
    int totalDebits = 0;
    int imageSummaries = 0;
    int voiceSummaries = 0;

    for (final txn in transactions) {
      if (txn.isCredit) {
        totalCredits += txn.amount;
      } else {
        totalDebits += txn.amount;
      }

      if (txn.source == TokenSource.imageSummary) {
        imageSummaries++;
      } else if (txn.source == TokenSource.voiceSummary) {
        voiceSummaries++;
      }
    }

    return {
      'totalCredits': totalCredits,
      'totalDebits': totalDebits,
      'imageSummaries': imageSummaries,
      'voiceSummaries': voiceSummaries,
      'totalTransactions': transactions.length,
    };
  }

  /// Reset token balance (for monthly subscription reset)
  Future<void> resetMonthlyTokens({
    required String userId,
    required int monthlyTokens,
  }) async {
    final newBalance = TokenBalance(
      totalTokens: monthlyTokens,
      usedTokens: 0,
      lastRefreshedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );

    await updateTokenBalance(userId, newBalance);
  }
}

/// Exception thrown when user doesn't have enough tokens
class InsufficientTokensException implements Exception {
  final String message;
  InsufficientTokensException(this.message);

  @override
  String toString() => message;
}
