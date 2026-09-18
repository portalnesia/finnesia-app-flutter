/*
 * Copyright (c) Portalnesia - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Putu Aditya <aditya@portalnesia.com>
 */

// Writes `windows/runner/resources/app_icon.ico` from the owner's artwork.
//
// Run: `./dev icons` (this runs as part of it), or
// `cd apps/pos && dart run tool/generate_windows_icon.dart`.
//
// Why this exists instead of leaving it to `flutter_launcher_icons`: that tool writes a
// SINGLE-size `.ico` (`windows/windows_icon_generator.dart` calls `encodeIco` on one resized
// image, default `icon_size: 48`). A single-size `.ico` is wrong on Windows — the shell picks a
// different size for the taskbar, the Alt-Tab switcher, Explorer's list and detail views, and
// the 256 px tile, and it scales the one you gave it for all of them. This writes all six.
//
// `package:image`'s `IcoEncoder.encodeImages` takes a list, so the multi-size part is the
// library's; only the "which sizes" decision is ours.
//
// The artwork is the full-bleed `icon.png`, not the transparent `icon_only.png`. Windows does
// not mask app icons the way Android's adaptive icons do, so a bare white glyph on a
// transparent field would be white-on-white in the light theme. `icon.png` carries its own
// amber field, which is what `site.webmanifest` uses for the installed web app.

import 'dart:io';

import 'package:image/image.dart' as img;

/// The sizes inside the `.ico`.
///
/// 16 and 32 are the taskbar and Explorer list; 48 is Explorer's medium icons and the default
/// icon size in Windows' own dialogs; 24 is the small taskbar mode; 64 and 256 cover the large
/// tiles and the Alt-Tab switcher. Every one is a size Windows actually asks for, so the shell
/// never has to rescale — which is where icons go blurry.
///
/// 256 is the `.ico` format's ceiling (`IcoEncoder` throws above it).
const sizes = [16, 24, 32, 48, 64, 256];

const source = 'assets/icon/icon.png';
const destination = 'windows/runner/resources/app_icon.ico';

void main() {
  final file = File(source);
  if (!file.existsSync()) {
    stderr.writeln(
      'missing $source — it is generated from the owner\'s artwork',
    );
    exitCode = 1;
    return;
  }

  final art = img.decodePng(file.readAsBytesSync());
  if (art == null) {
    stderr.writeln('$source is not a readable PNG');
    exitCode = 1;
    return;
  }

  // `average` and not `nearest`/`cubic`: every size here is a large downscale from 1080 px, and
  // averaging is the interpolation meant for that. Nearest drops whole rows of pixels and
  // makes the glyph's diagonal edge step; cubic overshoots on high-contrast edges.
  final frames = [
    for (final size in sizes)
      img.copyResize(
        art,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      ),
  ];

  File(destination)
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.IcoEncoder().encodeImages(frames));

  stdout.writeln('$destination — ${sizes.join(', ')} px');
}
