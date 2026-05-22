import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinBoxesInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int pinLength;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const PinBoxesInput({
    super.key,
    required this.controller,
    required this.focusNode,
    this.pinLength = 6,
    this.autofocus = false,
    this.onChanged,
    this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(focusNode),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final text = controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (index) {
                  final isFilled = index < text.length;
                  final isActive = index == text.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    // MARGINI E DIMENSIONI RIDOTTE PER EVITARE OVERFLOW
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 40,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isFilled
                          ? primary.withValues(alpha: isDark ? 0.2 : 0.08)
                          : isDark
                          ? const Color(0xFF1F2937)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFilled
                            ? primary
                            : isActive
                            ? primary.withValues(alpha: 0.6)
                            : isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFD1D5DB),
                        width: isFilled || isActive ? 2 : 1.5,
                      ),
                      boxShadow: isFilled
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: isFilled
                          ? Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: primary,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              );
            },
          ),
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: autofocus,
              keyboardType: TextInputType.number,
              maxLength: pinLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(counterText: ''),
              onChanged: (value) {
                onChanged?.call(value);
                if (value.length == pinLength) {
                  onCompleted?.call(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
