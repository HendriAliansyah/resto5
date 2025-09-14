// lib/providers/order_summary_filter_provider.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:resto2/models/order_model.dart';
import 'package:resto2/providers/staff_filter_provider.dart';

enum OrderSortOption { byDate, byTotal }

class OrderSummaryFilterState {
  final DateTimeRange? dateRange;
  final OrderStatus? status;
  final OrderSortOption sortOption;
  final SortOrder sortOrder;

  OrderSummaryFilterState({
    this.dateRange,
    this.status,
    this.sortOption = OrderSortOption.byDate,
    this.sortOrder = SortOrder.desc,
  });

  OrderSummaryFilterState copyWith({
    ValueGetter<DateTimeRange?>? dateRange,
    ValueGetter<OrderStatus?>? status,
    OrderSortOption? sortOption,
    SortOrder? sortOrder,
  }) {
    return OrderSummaryFilterState(
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      status: status != null ? status() : this.status,
      sortOption: sortOption ?? this.sortOption,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class OrderSummaryFilterNotifier
    extends StateNotifier<OrderSummaryFilterState> {
  OrderSummaryFilterNotifier() : super(OrderSummaryFilterState());

  void setDateRange(DateTimeRange? newDateRange) {
    state = state.copyWith(dateRange: () => newDateRange);
  }

  void setStatusFilter(OrderStatus? newStatus) {
    state = state.copyWith(status: () => newStatus);
  }

  void setSortOption(OrderSortOption newSortOption) {
    state = state.copyWith(sortOption: newSortOption);
  }

  void setSortOrder(SortOrder newSortOrder) {
    state = state.copyWith(sortOrder: newSortOrder);
  }
}

final orderSummaryFilterProvider =
    StateNotifierProvider.autoDispose<
      OrderSummaryFilterNotifier,
      OrderSummaryFilterState
    >((ref) => OrderSummaryFilterNotifier());
