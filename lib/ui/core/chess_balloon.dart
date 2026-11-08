import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'chess_theme.dart';

enum BalloonType {
  neutral,
  coach,
  success,
  error,
  hint,
}

enum BubbleTail {
  none,
  top,
  bottom,
  left,
}

/// Balão de Caixa Padronizado no estilo Chess.com
/// Resolve de forma canônica os problemas de espaçamento, padding, alinhamento
/// e apresentação visual de feedback, dicas pedagógicas e comentários de treinador.
class ChessBalloonCard extends StatelessWidget {
  final String? title;
  final Widget? content;
  final String? message;
  final Widget? avatar;
  final Widget? badge;
  final Widget? action;
  final BalloonType type;
  final BubbleTail tail;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;

  const ChessBalloonCard({
    super.key,
    this.title,
    this.content,
    this.message,
    this.avatar,
    this.badge,
    this.action,
    this.type = BalloonType.neutral,
    this.tail = BubbleTail.none,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.onTap,
  });

  Color _getBorderColor(ThemeController theme) {
    switch (type) {
      case BalloonType.coach:
        return theme.accentColor.withOpacity(0.6);
      case BalloonType.success:
        return AppColors.accentEmerald;
      case BalloonType.error:
        return AppColors.moveBlunder;
      case BalloonType.hint:
        return AppColors.secondaryAmber;
      case BalloonType.neutral:
        return theme.borderColor;
    }
  }

  Color _getBackgroundColor(ThemeController theme) {
    switch (type) {
      case BalloonType.coach:
        return theme.isDark ? const Color(0xFF131D2E) : const Color(0xFFF0FDF4);
      case BalloonType.success:
        return theme.isDark ? AppColors.accentEmerald.withOpacity(0.12) : const Color(0xFFDCFCE7);
      case BalloonType.error:
        return theme.isDark ? AppColors.moveBlunder.withOpacity(0.14) : const Color(0xFFFEE2E2);
      case BalloonType.hint:
        return theme.isDark ? AppColors.secondaryAmber.withOpacity(0.12) : const Color(0xFFFEF3C7);
      case BalloonType.neutral:
        return theme.surfaceColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final theme = ThemeController.instance;
        final bgColor = _getBackgroundColor(theme);
        final borderColor = _getBorderColor(theme);

        return Container(
          margin: margin,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cauda superior do balão de fala
              if (tail == BubbleTail.top)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: CustomPaint(
                    size: const Size(14, 8),
                    painter: _BubbleTailPainter(
                      color: bgColor,
                      borderColor: borderColor,
                      pointsUp: true,
                    ),
                  ),
                ),

              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: padding,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(theme.isDark ? 0.25 : 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Cabeçalho do balão: Avatar + Título + Badge
                      if (avatar != null || title != null || badge != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (avatar != null) ...[
                              avatar!,
                              const SizedBox(width: 12),
                            ],
                            if (title != null)
                              Expanded(
                                child: Text(
                                  title!,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              badge!,
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Mensagem em texto ou Conteúdo customizado
                      if (message != null)
                        Text(
                          message!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: theme.textPrimary,
                            height: 1.45,
                          ),
                        ),
                      ?content,

                      // Ações inferiores (botões, dicas adicionais)
                      if (action != null) ...[
                        const SizedBox(height: 12),
                        action!,
                      ],
                    ],
                  ),
                ),
              ),

              // Cauda inferior do balão de fala
              if (tail == BubbleTail.bottom)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: CustomPaint(
                    size: const Size(14, 8),
                    painter: _BubbleTailPainter(
                      color: bgColor,
                      borderColor: borderColor,
                      pointsUp: false,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointsUp;

  _BubbleTailPainter({
    required this.color,
    required this.borderColor,
    required this.pointsUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointsUp) {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}
