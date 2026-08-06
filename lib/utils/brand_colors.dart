import 'package:flutter/material.dart';

/// Brand blues used for the top bar, primary buttons and their gradients.
///
/// In dark mode a darker shade of the same blue is used so the surfaces stay
/// recognizable but deeper.
Color brandAppBarBlue(Brightness brightness) =>
    brightness == Brightness.dark
        ? Colors.blue.shade900
        : Colors.blue.shade700;

Color brandButtonBlue(Brightness brightness) =>
    brightness == Brightness.dark
        ? Colors.blue.shade800
        : Colors.blue.shade600;

/// Darker end color for brand gradients.
Color brandGradientEndBlue(Brightness brightness) =>
    brightness == Brightness.dark
        ? Colors.blue.shade900
        : Colors.blue.shade800;
