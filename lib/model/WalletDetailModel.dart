import 'WalletListModel.dart';

class WalletDetailModel {
  UserWalletModel? walletBalance;
  num? minAmountToGetRide;
  num? totalAmount;
  num? subscriptionAmountToGetRide;
  bool? isDriverSubscriptionExpire;
  num? driverDailyFee;
  bool? dailyFeeChargedToday;
  bool? dailyFeePendingToday;
  String? dailyFeeReminder;
  bool? dailyFeeJustCharged;
  String? dailyFeeApplyMessage;
  String? dailyFeeApplyError;

  WalletDetailModel({
    this.walletBalance,
    this.minAmountToGetRide,
    this.totalAmount,
    this.subscriptionAmountToGetRide,
    this.isDriverSubscriptionExpire,
    this.driverDailyFee,
    this.dailyFeeChargedToday,
    this.dailyFeePendingToday,
    this.dailyFeeReminder,
    this.dailyFeeJustCharged,
    this.dailyFeeApplyMessage,
    this.dailyFeeApplyError,
  });

  factory WalletDetailModel.fromJson(Map<String, dynamic> json) {
    return WalletDetailModel(
      walletBalance: json['wallet_data'] != null ? UserWalletModel.fromJson(json['wallet_data']) : (json['wallet_balance'] != null ? UserWalletModel.fromJson(json['wallet_balance']) : null),
      minAmountToGetRide: json['min_amount_to_get_ride'],
      totalAmount: json['total_amount'],
      subscriptionAmountToGetRide: json['subscription_amount_to_get_ride'],
      isDriverSubscriptionExpire: json['is_driver_subscription_expire'],
      driverDailyFee: json['driver_daily_fee'],
      dailyFeeChargedToday: json['daily_fee_charged_today'],
      dailyFeePendingToday: json['daily_fee_pending_today'],
      dailyFeeReminder: json['daily_fee_reminder'],
      dailyFeeJustCharged: json['daily_fee_just_charged'],
      dailyFeeApplyMessage: json['daily_fee_apply_message'],
      dailyFeeApplyError: json['daily_fee_apply_error'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.walletBalance != null) {
      data['wallet_balance'] = this.walletBalance!.toJson();
    }
    data['min_amount_to_get_ride'] = this.minAmountToGetRide;
    data['total_amount'] = this.totalAmount;
    data['subscription_amount_to_get_ride'] = this.subscriptionAmountToGetRide;
    data['is_driver_subscription_expire'] = this.isDriverSubscriptionExpire;
    data['driver_daily_fee'] = this.driverDailyFee;
    data['daily_fee_charged_today'] = this.dailyFeeChargedToday;
    data['daily_fee_pending_today'] = this.dailyFeePendingToday;
    data['daily_fee_reminder'] = this.dailyFeeReminder;
    data['daily_fee_just_charged'] = this.dailyFeeJustCharged;
    data['daily_fee_apply_message'] = this.dailyFeeApplyMessage;
    data['daily_fee_apply_error'] = this.dailyFeeApplyError;
    return data;
  }
}
