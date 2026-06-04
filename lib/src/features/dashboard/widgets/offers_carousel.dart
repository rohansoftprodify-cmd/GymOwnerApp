import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gym_owner_app/src/features/dashboard/widgets/exclusive_offer_card.dart';

class OffersCarousel extends StatefulWidget {
  const OffersCarousel({super.key, required this.promotions});

  final List<Map<String, dynamic>> promotions;

  @override
  State<OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<OffersCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;
  double _currentPage = 0;

  static const _cardHeight = 148.0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _controller.addListener(() {
      if (_controller.hasClients) {
        setState(() => _currentPage = _controller.page ?? 0);
      }
    });
    if (widget.promotions.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        _index = (_index + 1) % widget.promotions.length;
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.promotions.isEmpty) {
      return Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                color: colorScheme.outline,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text('No active offers', style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: _cardHeight,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.promotions.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) {
              final offer = widget.promotions[i];
              final value = (_currentPage - i).abs();
              final scale = (1 - (value * 0.06)).clamp(0.94, 1.0);
              final opacity = (1 - (value * 0.25)).clamp(0.75, 1.0);

              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: ExclusiveOfferCard(
                    offer: offer,
                    height: _cardHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.promotions.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              width: _index == index ? 14 : 4,
              decoration: BoxDecoration(
                color: _index == index
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
