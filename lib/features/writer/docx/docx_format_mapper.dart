import 'package:xml/xml.dart';

class DocxFormatMapper {
  /// Converts Quill Delta operation attributes to OpenXML Run Properties (<w:rPr>)
  static void applyRunAttributes(XmlBuilder builder, Map<String, dynamic> attributes) {
    builder.element('w:rPr', nest: () {
      if (attributes.containsKey('bold') && attributes['bold'] == true) {
        builder.element('w:b');
      }
      if (attributes.containsKey('italic') && attributes['italic'] == true) {
        builder.element('w:i');
      }
      if (attributes.containsKey('underline') && attributes['underline'] == true) {
        builder.element('w:u', attributes: {'w:val': 'single'});
      }
      if (attributes.containsKey('strike') && attributes['strike'] == true) {
        builder.element('w:strike');
      }
      if (attributes.containsKey('color')) {
        final color = attributes['color'].toString().replaceFirst('#', '');
        builder.element('w:color', attributes: {'w:val': color.length == 8 ? color.substring(2) : color});
      }
      if (attributes.containsKey('background')) {
        final color = attributes['background'].toString().replaceFirst('#', '');
        builder.element('w:highlight', attributes: {'w:val': _mapHighlightColor(color)});
      }
      if (attributes.containsKey('size')) {
         // Quill uses sizes like 'small', 'large', 'huge' or numbers. Word uses half-points.
         final size = attributes['size'];
         if (size == 'small') builder.element('w:sz', attributes: {'w:val': '20'});
         else if (size == 'large') builder.element('w:sz', attributes: {'w:val': '36'});
         else if (size == 'huge') builder.element('w:sz', attributes: {'w:val': '48'});
      }
    });
  }

  /// Converts Quill Delta line attributes to OpenXML Paragraph Properties (<w:pPr>)
  static void applyParagraphAttributes(XmlBuilder builder, Map<String, dynamic> attributes) {
    builder.element('w:pPr', nest: () {
      if (attributes.containsKey('header')) {
        final level = attributes['header'];
        builder.element('w:pStyle', attributes: {'w:val': 'Heading$level'});
      }
      if (attributes.containsKey('align')) {
        final align = attributes['align'];
        builder.element('w:jc', attributes: {'w:val': align == 'justify' ? 'both' : align});
      }
      if (attributes.containsKey('list')) {
        final listType = attributes['list'];
        builder.element('w:numPr', nest: () {
          builder.element('w:ilvl', attributes: {'w:val': '0'});
          builder.element('w:numId', attributes: {'w:val': listType == 'ordered' ? '1' : '2'});
        });
      }
    });
  }

  static String _mapHighlightColor(String hexColor) {
    // Word highlight colors are restricted to a specific set of strings.
    // We do a basic mapping here.
    hexColor = hexColor.toUpperCase();
    if (hexColor.contains('FFFF00')) return 'yellow';
    if (hexColor.contains('00FF00')) return 'green';
    if (hexColor.contains('00FFFF')) return 'cyan';
    if (hexColor.contains('FF00FF')) return 'magenta';
    if (hexColor.contains('0000FF')) return 'blue';
    if (hexColor.contains('FF0000')) return 'red';
    if (hexColor.contains('000000')) return 'black';
    if (hexColor.contains('FFFFFF')) return 'white';
    return 'yellow'; // default fallback
  }

  /// Extracts Quill Delta attributes from an OpenXML Run (<w:r>) element
  static Map<String, dynamic> extractRunAttributes(XmlElement rElement) {
    final attributes = <String, dynamic>{};
    final rPr = rElement.findElements('w:rPr').firstOrNull;
    if (rPr != null) {
      if (rPr.findElements('w:b').isNotEmpty) attributes['bold'] = true;
      if (rPr.findElements('w:i').isNotEmpty) attributes['italic'] = true;
      if (rPr.findElements('w:u').isNotEmpty) attributes['underline'] = true;
      if (rPr.findElements('w:strike').isNotEmpty) attributes['strike'] = true;

      final colorNode = rPr.findElements('w:color').firstOrNull;
      if (colorNode != null) {
        final val = colorNode.getAttribute('w:val');
        if (val != null && val != 'auto') {
           attributes['color'] = '#FF$val'; // Ensure 8 chars for Quill
        }
      }

      final highlightNode = rPr.findElements('w:highlight').firstOrNull;
      if (highlightNode != null) {
        final val = highlightNode.getAttribute('w:val');
        if (val == 'yellow') attributes['background'] = '#FFFFFF00';
        else if (val == 'red') attributes['background'] = '#FFFF0000';
        else if (val == 'green') attributes['background'] = '#FF00FF00';
        else if (val == 'blue') attributes['background'] = '#FF0000FF';
      }
    }
    return attributes;
  }

  /// Extracts Quill Delta attributes from an OpenXML Paragraph (<w:p>) element
  static Map<String, dynamic> extractParagraphAttributes(XmlElement pElement) {
    final attributes = <String, dynamic>{};
    final pPr = pElement.findElements('w:pPr').firstOrNull;
    if (pPr != null) {
      final pStyle = pPr.findElements('w:pStyle').firstOrNull;
      if (pStyle != null) {
        final val = pStyle.getAttribute('w:val');
        if (val != null && val.startsWith('Heading')) {
          final levelStr = val.replaceAll('Heading', '');
          final level = int.tryParse(levelStr);
          if (level != null && level >= 1 && level <= 6) {
            attributes['header'] = level;
          }
        }
      }

      final jc = pPr.findElements('w:jc').firstOrNull;
      if (jc != null) {
        final val = jc.getAttribute('w:val');
        if (val == 'both') attributes['align'] = 'justify';
        else if (val == 'center' || val == 'right') attributes['align'] = val;
      }

      final numPr = pPr.findElements('w:numPr').firstOrNull;
      if (numPr != null) {
         // Naive interpretation for basics
         attributes['list'] = 'bullet'; // Fallback to bullet if any numPr exists
      }
    }
    return attributes;
  }
}
