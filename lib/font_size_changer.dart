import 'package:flutter/material.dart';

class FontSizeChanger extends StatefulWidget {
  final double initialFontSize;
  final double minFontSize;
  final double maxFontSize;
  final double step;
  final ValueChanged<double> onFontSizeChanged;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool showSlider;
  final bool showButtons;
  final bool showValue;
  final String? label;

  const FontSizeChanger({
    Key? key,
    this.initialFontSize = 16.0,
    this.minFontSize = 8.0,
    this.maxFontSize = 32.0,
    this.step = 1.0,
    required this.onFontSizeChanged,
    this.primaryColor,
    this.backgroundColor,
    this.showSlider = true,
    this.showButtons = true,
    this.showValue = true,
    this.label,
  }) : super(key: key);

  @override
  State<FontSizeChanger> createState() => _FontSizeChangerState();
}

class _FontSizeChangerState extends State<FontSizeChanger> {
  late double _currentFontSize;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.initialFontSize.clamp(
      widget.minFontSize,
      widget.maxFontSize,
    );
  }

  void _updateFontSize(double newSize) {
    final clampedSize = newSize.clamp(widget.minFontSize, widget.maxFontSize);
    if (_currentFontSize != clampedSize) {
      setState(() {
        _currentFontSize = clampedSize;
      });
      widget.onFontSizeChanged(clampedSize);
    }
  }

  void _increaseFontSize() {
    _updateFontSize(_currentFontSize + widget.step);
  }

  void _decreaseFontSize() {
    _updateFontSize(_currentFontSize - widget.step);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final backgroundColor = widget.backgroundColor ?? theme.cardColor;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Button controls
          if (widget.showButtons) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.remove,
                  onPressed:
                      _currentFontSize > widget.minFontSize
                          ? _decreaseFontSize
                          : null,
                  primaryColor: primaryColor,
                ),
                if (widget.showValue) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_currentFontSize.toInt()}px',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                _buildControlButton(
                  icon: Icons.add,
                  onPressed:
                      _currentFontSize < widget.maxFontSize
                          ? _increaseFontSize
                          : null,
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ],

          // Slider control
          if (widget.showSlider) ...[
            if (widget.showButtons) const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: primaryColor,
                inactiveTrackColor: primaryColor.withOpacity(0.3),
                thumbColor: primaryColor,
                overlayColor: primaryColor.withOpacity(0.2),
                valueIndicatorColor: primaryColor,
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Slider(
                value: _currentFontSize,
                min: widget.minFontSize,
                max: widget.maxFontSize,
                divisions:
                    ((widget.maxFontSize - widget.minFontSize) / widget.step)
                        .round(),
                label: '${_currentFontSize.toInt()}px',
                onChanged: _updateFontSize,
              ),
            ),
          ],

          // Preview text
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: primaryColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Sample Text',
              style: TextStyle(
                fontSize: _currentFontSize,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: onPressed != null ? primaryColor : Colors.grey[300],
          foregroundColor: onPressed != null ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}

// Example usage widget
class FontSizeChangerExample extends StatefulWidget {
  @override
  State<FontSizeChangerExample> createState() => _FontSizeChangerExampleState();
}

class _FontSizeChangerExampleState extends State<FontSizeChangerExample> {
  double _fontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Font Size Changer Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FontSizeChanger(
              initialFontSize: _fontSize,
              minFontSize: 10.0,
              maxFontSize: 28.0,
              step: 2.0,
              label: 'Adjust Font Size',
              onFontSizeChanged: (newSize) {
                setState(() {
                  _fontSize = newSize;
                });
              },
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This is a sample text that will change size based on the font size changer above. '
                  'You can see how the text scales as you adjust the font size using either the buttons or the slider.',
                  style: TextStyle(fontSize: _fontSize),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
