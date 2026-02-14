/// Token transaction type
enum TokenTransactionType {
  credit,     // Tokens added (purchase, reward, etc.)
  debit,      // Tokens used (summarization)
  refund,     // Tokens refunded
  expired,    // Tokens expired
  bonus,      // Bonus tokens (promotions)
}

extension TokenTransactionTypeExtension on TokenTransactionType {
  String get value {
    switch (this) {
      case TokenTransactionType.credit:
        return 'credit';
      case TokenTransactionType.debit:
        return 'debit';
      case TokenTransactionType.refund:
        return 'refund';
      case TokenTransactionType.expired:
        return 'expired';
      case TokenTransactionType.bonus:
        return 'bonus';
    }
  }

  static TokenTransactionType fromString(String value) {
    switch (value) {
      case 'credit':
        return TokenTransactionType.credit;
      case 'debit':
        return TokenTransactionType.debit;
      case 'refund':
        return TokenTransactionType.refund;
      case 'expired':
        return TokenTransactionType.expired;
      case 'bonus':
        return TokenTransactionType.bonus;
      default:
        return TokenTransactionType.debit;
    }
  }
}

/// Source of token transaction
enum TokenSource {
  imageSummary,
  voiceSummary,
  purchase,
  signup,
  referral,
  dailyBonus,
  subscription,
  admin,
}

extension TokenSourceExtension on TokenSource {
  String get value {
    switch (this) {
      case TokenSource.imageSummary:
        return 'imageSummary';
      case TokenSource.voiceSummary:
        return 'voiceSummary';
      case TokenSource.purchase:
        return 'purchase';
      case TokenSource.signup:
        return 'signup';
      case TokenSource.referral:
        return 'referral';
      case TokenSource.dailyBonus:
        return 'dailyBonus';
      case TokenSource.subscription:
        return 'subscription';
      case TokenSource.admin:
        return 'admin';
    }
  }

  static TokenSource fromString(String value) {
    switch (value) {
      case 'imageSummary':
        return TokenSource.imageSummary;
      case 'voiceSummary':
        return TokenSource.voiceSummary;
      case 'purchase':
        return TokenSource.purchase;
      case 'signup':
        return TokenSource.signup;
      case 'referral':
        return TokenSource.referral;
      case 'dailyBonus':
        return TokenSource.dailyBonus;
      case 'subscription':
        return TokenSource.subscription;
      case 'admin':
        return TokenSource.admin;
      default:
        return TokenSource.imageSummary;
    }
  }

  /// Get display name for the source
  String get displayName {
    switch (this) {
      case TokenSource.imageSummary:
        return 'Image Summary';
      case TokenSource.voiceSummary:
        return 'Voice Summary';
      case TokenSource.purchase:
        return 'Purchase';
      case TokenSource.signup:
        return 'Sign Up Bonus';
      case TokenSource.referral:
        return 'Referral Bonus';
      case TokenSource.dailyBonus:
        return 'Daily Bonus';
      case TokenSource.subscription:
        return 'Subscription';
      case TokenSource.admin:
        return 'Admin Adjustment';
    }
  }
}

/// Model representing a token transaction
class TokenTransactionModel {
  final String id;
  final String userId;
  final TokenTransactionType type;
  final TokenSource source;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String? referenceId; // e.g., summaryId for debits
  final String? description;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const TokenTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.source,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceId,
    this.description,
    required this.createdAt,
    this.metadata,
  });

  /// Check if this is a credit transaction
  bool get isCredit =>
      type == TokenTransactionType.credit ||
      type == TokenTransactionType.refund ||
      type == TokenTransactionType.bonus;

  /// Check if this is a debit transaction
  bool get isDebit =>
      type == TokenTransactionType.debit || type == TokenTransactionType.expired;

  /// Get signed amount (positive for credit, negative for debit)
  int get signedAmount => isCredit ? amount : -amount;

  factory TokenTransactionModel.fromJson(Map<String, dynamic> json) {
    return TokenTransactionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: TokenTransactionTypeExtension.fromString(json['type'] as String),
      source: TokenSourceExtension.fromString(json['source'] as String),
      amount: json['amount'] as int,
      balanceBefore: json['balanceBefore'] as int,
      balanceAfter: json['balanceAfter'] as int,
      referenceId: json['referenceId'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'source': source.value,
      'amount': amount,
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
      'referenceId': referenceId,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  String toString() {
    return 'TokenTransaction(id: $id, type: ${type.value}, amount: $amount)';
  }
}

/// Token package available for purchase
class TokenPackage {
  final String id;
  final String name;
  final int tokenAmount;
  final double price;
  final String currency;
  final double? discountPercentage;
  final bool isFeatured;
  final String? description;

  const TokenPackage({
    required this.id,
    required this.name,
    required this.tokenAmount,
    required this.price,
    this.currency = 'USD',
    this.discountPercentage,
    this.isFeatured = false,
    this.description,
  });

  /// Get price per token
  double get pricePerToken => tokenAmount > 0 ? price / tokenAmount : 0;

  /// Get original price (before discount)
  double get originalPrice {
    if (discountPercentage == null || discountPercentage == 0) return price;
    return price / (1 - (discountPercentage! / 100));
  }

  /// Check if package has discount
  bool get hasDiscount => discountPercentage != null && discountPercentage! > 0;

  factory TokenPackage.fromJson(Map<String, dynamic> json) {
    return TokenPackage(
      id: json['id'] as String,
      name: json['name'] as String,
      tokenAmount: json['tokenAmount'] as int,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tokenAmount': tokenAmount,
      'price': price,
      'currency': currency,
      'discountPercentage': discountPercentage,
      'isFeatured': isFeatured,
      'description': description,
    };
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final int monthlyTokens;
  final double monthlyPrice;
  final double? yearlyPrice;
  final String currency;
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyTokens,
    required this.monthlyPrice,
    this.yearlyPrice,
    this.currency = 'USD',
    this.features = const [],
    this.isPopular = false,
  });

  /// Get yearly savings if yearly plan exists
  double? get yearlySavings {
    if (yearlyPrice == null) return null;
    return (monthlyPrice * 12) - yearlyPrice!;
  }

  /// Get effective monthly price for yearly plan
  double? get effectiveMonthlyPrice {
    if (yearlyPrice == null) return null;
    return yearlyPrice! / 12;
  }

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyTokens: json['monthlyTokens'] as int,
      monthlyPrice: (json['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (json['yearlyPrice'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isPopular: json['isPopular'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyTokens': monthlyTokens,
      'monthlyPrice': monthlyPrice,
      'yearlyPrice': yearlyPrice,
      'currency': currency,
      'features': features,
      'isPopular': isPopular,
    };
  }
}
