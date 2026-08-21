import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class FrogMascotWidget extends StatefulWidget {
  final bool compact;
  const FrogMascotWidget({super.key, this.compact = false});

  @override
  State<FrogMascotWidget> createState() => _FrogMascotWidgetState();
}

class _FrogMascotWidgetState extends State<FrogMascotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  final List<String> _frogTips = [
    "Coâââ ! Sécurise ton combiné Côte 5 du jour et saute vers la victoire !",
    "Ribbit ! Gère ta bankroll prudemment, pas de saut dans le vide !",
    "Coââ ! Abonnez-vous pour débloquer les Côtes 5, 10, 50 et la Montante !",
    "Croââ ! Nos analystes ont repéré 3 matchs européens en or ce soir !",
    "Ribbit ! La stratégie Montante se joue pas à pas : chaque victoire finance l'étape suivante !"
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  void _onFrogTapped() {
    _controller.forward().then((_) => _controller.reverse());
    final tip = _frogTips[Random().nextInt(_frogTips.length)];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppTheme.frogGreen, width: 2),
        ),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐸 ', style: TextStyle(inherit: true, fontSize: 28)),
            Text(
              'FROGAZZ DIT :',
              style: TextStyle(inherit: true, 
                color: AppTheme.frogGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Text(
          '"$tip"',
          textAlign: TextAlign.center,
          style: const TextStyle(inherit: true, 
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.check, color: Colors.black),
              label: const Text(
                'MERCI FROGAZZ !',
                style: TextStyle(inherit: true, color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.frogGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return GestureDetector(
        onTap: _onFrogTapped,
        child: AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.frogGreen.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.frogGreen, width: 1.5),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐸', style: TextStyle(inherit: true, fontSize: 18)),
                    SizedBox(width: 6),
                    Text(
                      'Conseil',
                      style: TextStyle(inherit: true, 
                        color: AppTheme.frogGreen,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: _onFrogTapped,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: const Text('🐸', style: TextStyle(inherit: true, fontSize: 32)),
          );
        },
      ),
    );
  }
}
