import 'package:flutter/material.dart';

class NumericKeypad extends StatefulWidget {
  final Function(String) onInput;
  final VoidCallback onSubmit;

  const NumericKeypad({
    super.key,
    required this.onInput,
    required this.onSubmit,
  });

  @override
  State<NumericKeypad> createState() => _NumericKeypadState();
}

class _NumericKeypadState extends State<NumericKeypad> {
  String _currentValue = '';

  void _onKeyPressed(String key) {
    setState(() {
      if (key == 'backspace') {
        if (_currentValue.isNotEmpty) {
          _currentValue = _currentValue.substring(0, _currentValue.length - 1);
        }
      } else if (key == 'submit') {
        widget.onSubmit();
        _currentValue = '';
      } else {
        // 限制最多3位数字
        if (_currentValue.length < 3) {
          _currentValue += key;
        }
      }
    });

    widget.onInput(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 数字行 1-3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 12),
          // 数字行 4-6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 12),
          // 数字行 7-9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 12),
          // 底部行: 退格, 0, 确认
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('backspace', isSpecial: true),
              _buildKey('0'),
              _buildKey('submit', isSpecial: true, isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String key, {bool isSpecial = false, bool isPrimary = false}) {
    IconData icon;
    String label;
    Color bgColor;

    if (key == 'backspace') {
      icon = Icons.backspace_outlined;
      label = '';
      bgColor = Colors.white.withValues(alpha: 0.3);
    } else if (key == 'submit') {
      icon = Icons.check;
      label = '';
      bgColor = isPrimary ? Colors.green.shade400 : Colors.white.withValues(alpha: 0.3);
    } else {
      icon = Icons.abc; // placeholder, won't be shown
      label = key;
      bgColor = Colors.white.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: () => _onKeyPressed(key),
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Center(
          child: icon == Icons.abc
              ? Text(
                  label,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  icon,
                  size: 28,
                  color: key == 'submit' ? Colors.white : Colors.white,
                ),
        ),
      ),
    );
  }
}
