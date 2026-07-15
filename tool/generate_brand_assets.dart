import 'dart:io';

import 'package:image/image.dart' as image;

const _assetsDirectory = 'assets/images';

void main() {
  final cross = _prepareLogo('$_assetsDirectory/dawa_cross2.png');
  final wordmark = _prepareLogo('$_assetsDirectory/dawa_text2.png');
  final full = _prepareLogo('$_assetsDirectory/Logos-06.png');

  _writePng('$_assetsDirectory/dawa_mom_cross.png', cross);
  _writePng('$_assetsDirectory/dawa_mom_wordmark.png', wordmark);
  _writePng('$_assetsDirectory/dawa_mom_full.png', full);

  final appIcon = image.Image(width: 1024, height: 1024, numChannels: 4);
  image.fill(appIcon, color: image.ColorRgba8(255, 255, 255, 255));
  final fittedCross = image.copyResize(
    cross,
    width: 760,
    maintainAspect: true,
    interpolation: image.Interpolation.cubic,
  );
  image.compositeImage(
    appIcon,
    fittedCross,
    dstX: (appIcon.width - fittedCross.width) ~/ 2,
    dstY: (appIcon.height - fittedCross.height) ~/ 2,
  );
  _writePng('$_assetsDirectory/dawa_mom_app_icon.png', appIcon);
}

image.Image _prepareLogo(String path) {
  final decoded = image.decodeImage(File(path).readAsBytesSync());
  if (decoded == null) throw StateError('Could not decode $path');

  var minX = decoded.width;
  var minY = decoded.height;
  var maxX = -1;
  var maxY = -1;

  for (final pixel in decoded) {
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final maximum = [red, green, blue].reduce((a, b) => a > b ? a : b);
    final minimum = [red, green, blue].reduce((a, b) => a < b ? a : b);
    final neutralWhite = minimum >= 238 && maximum - minimum <= 16;
    if (neutralWhite) {
      pixel.setRgba(red, green, blue, 0);
      continue;
    }
    if (pixel.a.toInt() > 8) {
      final x = pixel.x.toInt();
      final y = pixel.y.toInt();
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }

  if (maxX < minX || maxY < minY) {
    throw StateError('No visible logo content found in $path');
  }

  final contentWidth = maxX - minX + 1;
  final contentHeight = maxY - minY + 1;
  final padding =
      ((contentWidth > contentHeight ? contentWidth : contentHeight) * 0.025)
          .round();
  final cropX = (minX - padding).clamp(0, decoded.width - 1);
  final cropY = (minY - padding).clamp(0, decoded.height - 1);
  final cropRight = (maxX + padding).clamp(0, decoded.width - 1);
  final cropBottom = (maxY + padding).clamp(0, decoded.height - 1);

  return image.copyCrop(
    decoded,
    x: cropX,
    y: cropY,
    width: cropRight - cropX + 1,
    height: cropBottom - cropY + 1,
  );
}

void _writePng(String path, image.Image value) {
  File(path).writeAsBytesSync(image.encodePng(value, level: 9));
}
