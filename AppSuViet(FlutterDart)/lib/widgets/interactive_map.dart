import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

class InteractiveMap extends StatefulWidget {
  final Function(String id)? onProvinceTap;
  final String? selectedProvince;

  const InteractiveMap({
    super.key,
    this.onProvinceTap,
    this.selectedProvince,
  });

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  String svgString = '';
  List<_PathRegion> regions = [];
  double viewBoxWidth = 1000;
  double viewBoxHeight = 1000;

  @override
  void initState() {
    super.initState();
    _loadSvg();
  }

  Future<void> _loadSvg() async {
    final rawSvg = await rootBundle.loadString('assets/images/vn.svg');
    final document = xml.XmlDocument.parse(rawSvg);

    final svgTag = document.findElements('svg').first;
    final viewBox = svgTag.getAttribute('viewBox') ?? svgTag.getAttribute('viewbox');
    if (viewBox != null) {
      final parts = viewBox.split(RegExp(r'\s+'));
      if (parts.length == 4) {
        viewBoxWidth = double.tryParse(parts[2]) ?? 1000;
        viewBoxHeight = double.tryParse(parts[3]) ?? 1000;
      }
    }

    final paths = document.findAllElements('path');
    regions = paths.map((node) {
      final id = node.getAttribute('id') ?? 'Unknown';
      final d = node.getAttribute('d') ?? '';
      return _PathRegion(id, d);
    }).toList();

    setState(() => svgString = rawSvg);
  }

  @override
  Widget build(BuildContext context) {
    if (svgString.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Nếu chưa chọn tỉnh -> chỉ hiển thị SVG gốc, KHÔNG tô xanh toàn bản đồ
    if (widget.selectedProvince == null) {
      return SvgPicture.string(
        svgString,
        fit: BoxFit.contain,
      );
    }

    // Nếu đã chọn tỉnh -> tô nổi bật tỉnh đó
    return FutureBuilder<String>(
      future: _highlightSelectedProvince(widget.selectedProvince!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SvgPicture.string(snapshot.data!, fit: BoxFit.contain);
      },
    );
  }

  /// ✅ Tô sáng tỉnh được chọn
  Future<String> _highlightSelectedProvince(String id) async {
    final document = xml.XmlDocument.parse(svgString);
    final paths = document.findAllElements('path');

    for (var node in paths) {
      final nodeId = node.getAttribute('id');

      node.setAttribute('stroke', '#ffffff');
      node.setAttribute('stroke-width', '0.5');

      if (nodeId == id) {
        // Tỉnh được chọn -> đỏ đậm
        node.setAttribute('fill', '#e74c3c');
      } else {
        // Các tỉnh khác -> xanh nhạt
        node.setAttribute('fill', '#b7d4b1');
      }
    }

    return document.toXmlString(pretty: false);
  }
}

class _PathRegion {
  final String id;
  final String pathData;
  final ui.Path _path;

  _PathRegion(this.id, this.pathData) : _path = parseSvgPathData(pathData);

  bool contains(Offset scaledPoint) {
    return _path.contains(scaledPoint);
  }
}
