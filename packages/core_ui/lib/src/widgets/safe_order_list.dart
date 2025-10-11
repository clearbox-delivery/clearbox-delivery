import 'package:flutter/material.dart';
import 'package:core_data/core_data.dart';

/// Safe order list with animations that prevent mis-taps
/// [REQ-MER-CO-002] Real-time updates with safe animations
class SafeOrderList extends StatefulWidget {
  final List<Order> orders;
  final Widget Function(Order order) itemBuilder;
  final Duration animationDuration;

  const SafeOrderList({
    super.key,
    required this.orders,
    required this.itemBuilder,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<SafeOrderList> createState() => _SafeOrderListState();
}

class _SafeOrderListState extends State<SafeOrderList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Order> _currentOrders = [];
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentOrders = List.from(widget.orders);
  }

  @override
  void didUpdateWidget(SafeOrderList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateList(oldWidget.orders, widget.orders);
  }

  void _updateList(List<Order> oldList, List<Order> newList) {
    // Prevent touch during animation (200ms delay)
    if (_isAnimating) return;

    setState(() => _isAnimating = true);
    
    // Find removed items
    for (var i = oldList.length - 1; i >= 0; i--) {
      if (!newList.contains(oldList[i])) {
        final removedOrder = oldList[i];
        _currentOrders.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimatedItem(
            removedOrder,
            animation,
            isRemoving: true,
          ),
          duration: widget.animationDuration,
        );
      }
    }

    // Find added items
    for (var i = 0; i < newList.length; i++) {
      if (i >= oldList.length || newList[i] != oldList[i]) {
        if (!_currentOrders.contains(newList[i])) {
          _currentOrders.insert(i, newList[i]);
          _listKey.currentState?.insertItem(
            i,
            duration: widget.animationDuration,
          );
        }
      }
    }

    // Re-enable touch after animation completes
    Future.delayed(widget.animationDuration + const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _isAnimating = false);
      }
    });
  }

  Widget _buildAnimatedItem(
    Order order,
    Animation<double> animation, {
    bool isRemoving = false,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: widget.itemBuilder(order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isAnimating,
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _currentOrders.length,
        itemBuilder: (context, index, animation) {
          if (index >= _currentOrders.length) {
            return const SizedBox.shrink();
          }
          return _buildAnimatedItem(_currentOrders[index], animation);
        },
      ),
    );
  }
}


