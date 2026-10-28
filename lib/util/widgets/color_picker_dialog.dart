import 'package:material_ui/material_ui.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum _InputMode { hex, rgb, hsv, hsl }

class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, required this.cardColor});

  final Color cardColor;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  static const List<Color> _presets = [
    Color(0xFFF44336), Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7),
    Color(0xFF3F51B5), Color(0xFF2196F3), Color(0xFF03A9F4), Color(0xFF00BCD4),
    Color(0xFF009688), Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39),
    Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722),
    Color(0xFF795548), Color(0xFF9E9E9E), Color(0xFF607D8B), Color(0xFF000000),
    Color(0xFFFFFFFF),
  ];

  late HSVColor _hsv; // source of truth, keeps hue stable on gray colors
  late final TextEditingController _hexController;
  final FocusNode _hexFocus = FocusNode();
  _InputMode _mode = _InputMode.hex;
  final List<Color> _recent = [];

  Color get _color => _hsv.toColor();

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(_opaque(widget.cardColor));
    _hexController = TextEditingController(text: _toHex(_color));
  }

  @override
  void dispose() {
    _hexController.dispose();
    _hexFocus.dispose();
    super.dispose();
  }

  Color _opaque(Color c) => Color.fromARGB(
    255,
    (c.r * 255).round(),
    (c.g * 255).round(),
    (c.b * 255).round(),
  );

  int _ch(double v) => (v * 255).round();

  String _toHex(Color c) =>
      '${_ch(c.r).toRadixString(16).padLeft(2, '0')}'
          '${_ch(c.g).toRadixString(16).padLeft(2, '0')}'
          '${_ch(c.b).toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();

  void _setHsv(HSVColor hsv, {bool updateHex = true}) {
    setState(() {
      _hsv = hsv;
      if (updateHex && !_hexFocus.hasFocus) {
        _hexController.text = _toHex(_color);
      }
    });
  }

  void _setColor(Color c, {bool updateHex = true}) {
    var hsv = HSVColor.fromColor(_opaque(c));
    // keep the previous hue when the new color has no meaningful hue
    if (hsv.saturation == 0 || hsv.value == 0) {
      hsv = hsv.withHue(_hsv.hue);
    }
    _setHsv(hsv, updateHex: updateHex);
    if (updateHex) _hexController.text = _toHex(_color);
  }

  void _onHexChanged(String text) {
    var h = text.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (h.length == 3) {
      h = h.split('').map((e) => '$e$e').join();
    }
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) _setColor(Color(0xFF000000 | v), updateHex: false);
    }
  }

  void _remember(Color c) {
    _recent.removeWhere((e) => e.toARGB32() == c.toARGB32());
    _recent.insert(0, c);
    if (_recent.length > 8) _recent.removeLast();
  }

  Color _onColor(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Card color'),
      scrollable: true,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColorPicker(
              labelTypes: const [],
              hexInputBar: false,
              displayThumbColor: true,
              pickerAreaBorderRadius: BorderRadius.circular(12),
              paletteType: PaletteType.hsv,
              enableAlpha: false,
              pickerColor: _color,
              portraitOnly: true,
              onColorChanged: (value) => _setColor(value),
            ),
            const SizedBox(height: 16),
            _buildPreview(),
            const SizedBox(height: 16),
            Center(
              child: SegmentedButton<_InputMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: _InputMode.hex, label: Text('HEX')),
                  ButtonSegment(value: _InputMode.rgb, label: Text('RGB')),
                  ButtonSegment(value: _InputMode.hsv, label: Text('HSV')),
                  ButtonSegment(value: _InputMode.hsl, label: Text('HSL')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
            ),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              alignment: Alignment.topCenter,
              child: _buildInputs(),
            ),
            const SizedBox(height: 16),
            _sectionLabel('Presets', scheme),
            const SizedBox(height: 8),
            _swatches(_presets),
            if (_recent.isNotEmpty) ...[
              const SizedBox(height: 16),
              _sectionLabel('Recent', scheme),
              const SizedBox(height: 8),
              _swatches(_recent),
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _remember(_color);
            Navigator.pop(context, _color);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text, ColorScheme scheme) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: scheme.onSurfaceVariant,
    ),
  );

  Widget _buildPreview() {
    final old = _opaque(widget.cardColor);
    final now = _color;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: old,
                alignment: Alignment.center,
                child: Text('Current',
                    style: TextStyle(color: _onColor(old), fontSize: 12)),
              ),
            ),
            Expanded(
              child: Container(
                color: now,
                alignment: Alignment.center,
                child: Text('New  #${_toHex(now)}',
                    style: TextStyle(
                        color: _onColor(now),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    switch (_mode) {
      case _InputMode.hex:
        return TextField(
          key: const ValueKey('hex'),
          controller: _hexController,
          focusNode: _hexFocus,
          maxLength: 7,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Hex code',
            prefixText: '#',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: _onHexChanged,
          onEditingComplete: () {
            _hexFocus.unfocus();
            _hexController.text = _toHex(_color);
          },
        );
      case _InputMode.rgb:
        final c = _color;
        Color rgb(double r, double g, double b) =>
            Color.from(alpha: 1, red: r, green: g, blue: b);
        return Column(
          key: const ValueKey('rgb'),
          children: [
            _ChannelSlider(
              label: 'R',
              value: _ch(c.r).toDouble(),
              max: 255,
              activeColor: Colors.red,
              onChanged: (v) => _setColor(rgb(v / 255, c.g, c.b)),
            ),
            _ChannelSlider(
              label: 'G',
              value: _ch(c.g).toDouble(),
              max: 255,
              activeColor: Colors.green,
              onChanged: (v) => _setColor(rgb(c.r, v / 255, c.b)),
            ),
            _ChannelSlider(
              label: 'B',
              value: _ch(c.b).toDouble(),
              max: 255,
              activeColor: Colors.blue,
              onChanged: (v) => _setColor(rgb(c.r, c.g, v / 255)),
            ),
          ],
        );
      case _InputMode.hsv:
        return Column(
          key: const ValueKey('hsv'),
          children: [
            _ChannelSlider(
              label: 'H',
              value: _hsv.hue,
              max: 360,
              suffix: '°',
              activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
              onChanged: (v) => _setHsv(_hsv.withHue(v)),
            ),
            _ChannelSlider(
              label: 'S',
              value: _hsv.saturation * 100,
              max: 100,
              suffix: '%',
              activeColor: _color,
              onChanged: (v) => _setHsv(_hsv.withSaturation(v / 100)),
            ),
            _ChannelSlider(
              label: 'V',
              value: _hsv.value * 100,
              max: 100,
              suffix: '%',
              activeColor: _color,
              onChanged: (v) => _setHsv(_hsv.withValue(v / 100)),
            ),
          ],
        );
      case _InputMode.hsl:
        final hsl = HSLColor.fromColor(_color);
        void apply(HSLColor n) => _setColor(n.toColor());
        return Column(
          key: const ValueKey('hsl'),
          children: [
            _ChannelSlider(
              label: 'H',
              value: _hsv.hue,
              max: 360,
              suffix: '°',
              activeColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
              onChanged: (v) => _setHsv(_hsv.withHue(v)),
            ),
            _ChannelSlider(
              label: 'S',
              value: hsl.saturation * 100,
              max: 100,
              suffix: '%',
              activeColor: _color,
              onChanged: (v) => apply(hsl.withSaturation(v / 100)),
            ),
            _ChannelSlider(
              label: 'L',
              value: hsl.lightness * 100,
              max: 100,
              suffix: '%',
              activeColor: _color,
              onChanged: (v) => apply(hsl.withLightness(v / 100)),
            ),
          ],
        );
    }
  }

  Widget _swatches(List<Color> colors) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colors)
          GestureDetector(
            onTap: () => _setColor(c),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.toARGB32() == _color.toARGB32()
                      ? scheme.primary
                      : scheme.outlineVariant,
                  width: c.toARGB32() == _color.toARGB32() ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ChannelSlider extends StatelessWidget {
  const _ChannelSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.activeColor,
    required this.onChanged,
    this.suffix = '',
  });

  final String label;
  final double value;
  final double max;
  final String suffix;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600),),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0, max).toDouble(),
            min: 0,
            max: max,
            activeColor: activeColor,
            onChanged: onChanged,
            year2023: false,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '${value.round()}$suffix',
            textAlign: TextAlign.end,
            style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          ),
        ),
      ],
    );
  }
}