import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart' as semantics;

import 'dawa_localizations.dart';

export 'package:flutter/material.dart'
    hide InputDecoration, RichText, Semantics, Text, Tooltip;
export 'dawa_localizations.dart';

class Text extends material.StatelessWidget {
  const Text(
    String this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : textSpan = null;

  const Text.rich(
    material.InlineSpan this.textSpan, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  }) : data = null;

  final String? data;
  final material.InlineSpan? textSpan;
  final material.TextStyle? style;
  final material.StrutStyle? strutStyle;
  final material.TextAlign? textAlign;
  final material.TextDirection? textDirection;
  final material.Locale? locale;
  final bool? softWrap;
  final material.TextOverflow? overflow;
  final material.TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final material.TextWidthBasis? textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    final activeLocale = material.Localizations.maybeLocaleOf(context) ??
        DawaLocaleController.instance.locale;
    final localizedSemantics = DawaTranslations.maybeTranslate(
      semanticsLabel,
      activeLocale,
    );
    if (data != null) {
      return material.Text(
        DawaTranslations.translate(data!, activeLocale),
        style: style,
        strutStyle: strutStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        locale: locale,
        softWrap: softWrap,
        overflow: overflow,
        textScaler: textScaler,
        maxLines: maxLines,
        semanticsLabel: localizedSemantics,
        semanticsIdentifier: semanticsIdentifier,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
        selectionColor: selectionColor,
      );
    }
    return material.Text.rich(
      _translateSpan(textSpan!, activeLocale),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: localizedSemantics,
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

/// Localizes explicit accessibility copy while preserving the Material
/// semantics contract used throughout DawaMom.
class Semantics extends material.StatelessWidget {
  Semantics({
    super.key,
    this.child,
    this.container = false,
    this.explicitChildNodes = false,
    this.excludeSemantics = false,
    this.enabled,
    this.checked,
    this.selected,
    this.toggled,
    this.button,
    this.slider,
    this.link,
    this.header,
    this.textField,
    this.readOnly,
    this.focusable,
    this.focused,
    this.obscured,
    this.multiline,
    this.scopesRoute,
    this.namesRoute,
    this.hidden,
    this.image,
    this.liveRegion,
    this.expanded,
    this.label,
    this.value,
    this.increasedValue,
    this.decreasedValue,
    this.hint,
    this.tooltip,
    this.onTapHint,
    this.onLongPressHint,
    this.textDirection,
    this.sortKey,
    this.onTap,
    this.onLongPress,
    this.onIncrease,
    this.onDecrease,
    this.onDismiss,
  });

  final material.Widget? child;
  final bool container;
  final bool explicitChildNodes;
  final bool excludeSemantics;
  final bool? enabled;
  final bool? checked;
  final bool? selected;
  final bool? toggled;
  final bool? button;
  final bool? slider;
  final bool? link;
  final bool? header;
  final bool? textField;
  final bool? readOnly;
  final bool? focusable;
  final bool? focused;
  final bool? obscured;
  final bool? multiline;
  final bool? scopesRoute;
  final bool? namesRoute;
  final bool? hidden;
  final bool? image;
  final bool? liveRegion;
  final bool? expanded;
  final String? label;
  final String? value;
  final String? increasedValue;
  final String? decreasedValue;
  final String? hint;
  final String? tooltip;
  final String? onTapHint;
  final String? onLongPressHint;
  final material.TextDirection? textDirection;
  final semantics.SemanticsSortKey? sortKey;
  final material.VoidCallback? onTap;
  final material.VoidCallback? onLongPress;
  final material.VoidCallback? onIncrease;
  final material.VoidCallback? onDecrease;
  final material.VoidCallback? onDismiss;

  @override
  material.Widget build(material.BuildContext context) {
    final locale = material.Localizations.maybeLocaleOf(context) ??
        DawaLocaleController.instance.locale;
    String? localize(String? source) =>
        DawaTranslations.maybeTranslate(source, locale);
    return material.Semantics(
      container: container,
      explicitChildNodes: explicitChildNodes,
      excludeSemantics: excludeSemantics,
      enabled: enabled,
      checked: checked,
      selected: selected,
      toggled: toggled,
      button: button,
      slider: slider,
      link: link,
      header: header,
      textField: textField,
      readOnly: readOnly,
      focusable: focusable,
      focused: focused,
      obscured: obscured,
      multiline: multiline,
      scopesRoute: scopesRoute,
      namesRoute: namesRoute,
      hidden: hidden,
      image: image,
      liveRegion: liveRegion,
      expanded: expanded,
      label: localize(label),
      value: localize(value),
      increasedValue: localize(increasedValue),
      decreasedValue: localize(decreasedValue),
      hint: localize(hint),
      tooltip: localize(tooltip),
      onTapHint: localize(onTapHint),
      onLongPressHint: localize(onLongPressHint),
      textDirection: textDirection,
      sortKey: sortKey,
      onTap: onTap,
      onLongPress: onLongPress,
      onIncrease: onIncrease,
      onDecrease: onDecrease,
      onDismiss: onDismiss,
      child: child,
    );
  }
}

class RichText extends material.StatelessWidget {
  const RichText({
    super.key,
    required this.text,
    this.textAlign = material.TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = material.TextOverflow.clip,
    this.textScaler = material.TextScaler.noScaling,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = material.TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final material.InlineSpan text;
  final material.TextAlign textAlign;
  final material.TextDirection? textDirection;
  final bool softWrap;
  final material.TextOverflow overflow;
  final material.TextScaler textScaler;
  final int? maxLines;
  final material.Locale? locale;
  final material.StrutStyle? strutStyle;
  final material.TextWidthBasis textWidthBasis;
  final material.TextHeightBehavior? textHeightBehavior;
  final material.Color? selectionColor;

  @override
  material.Widget build(material.BuildContext context) {
    final activeLocale = material.Localizations.maybeLocaleOf(context) ??
        DawaLocaleController.instance.locale;
    return material.RichText(
      text: _translateSpan(text, activeLocale),
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      locale: locale,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}

class Tooltip extends material.StatelessWidget {
  const Tooltip({
    super.key,
    this.message,
    this.richMessage,
    this.constraints,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.textAlign,
    this.waitDuration,
    this.showDuration,
    this.exitDuration,
    this.enableTapToDismiss = true,
    this.triggerMode,
    this.enableFeedback,
    this.onTriggered,
    this.mouseCursor,
    this.ignorePointer,
    this.positionDelegate,
    this.child,
  });

  final String? message;
  final material.InlineSpan? richMessage;
  final material.BoxConstraints? constraints;
  final material.EdgeInsetsGeometry? padding;
  final material.EdgeInsetsGeometry? margin;
  final double? verticalOffset;
  final bool? preferBelow;
  final bool? excludeFromSemantics;
  final material.Decoration? decoration;
  final material.TextStyle? textStyle;
  final material.TextAlign? textAlign;
  final Duration? waitDuration;
  final Duration? showDuration;
  final Duration? exitDuration;
  final bool enableTapToDismiss;
  final material.TooltipTriggerMode? triggerMode;
  final bool? enableFeedback;
  final material.TooltipTriggeredCallback? onTriggered;
  final material.MouseCursor? mouseCursor;
  final bool? ignorePointer;
  final material.TooltipPositionDelegate? positionDelegate;
  final material.Widget? child;

  @override
  material.Widget build(material.BuildContext context) {
    final activeLocale = material.Localizations.maybeLocaleOf(context) ??
        DawaLocaleController.instance.locale;
    return material.Tooltip(
      message: DawaTranslations.maybeTranslate(message, activeLocale),
      richMessage: richMessage == null
          ? null
          : _translateSpan(richMessage!, activeLocale),
      constraints: constraints,
      padding: padding,
      margin: margin,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
      excludeFromSemantics: excludeFromSemantics,
      decoration: decoration,
      textStyle: textStyle,
      textAlign: textAlign,
      waitDuration: waitDuration,
      showDuration: showDuration,
      exitDuration: exitDuration,
      enableTapToDismiss: enableTapToDismiss,
      triggerMode: triggerMode,
      enableFeedback: enableFeedback,
      onTriggered: onTriggered,
      mouseCursor: mouseCursor,
      ignorePointer: ignorePointer,
      positionDelegate: positionDelegate,
      child: child,
    );
  }
}

class InputDecoration extends material.InputDecoration {
  InputDecoration({
    super.icon,
    super.iconColor,
    super.label,
    String? labelText,
    super.labelStyle,
    super.floatingLabelStyle,
    super.helper,
    String? helperText,
    super.helperStyle,
    super.helperMaxLines,
    String? hintText,
    super.hint,
    super.hintStyle,
    super.hintTextDirection,
    super.hintMaxLines,
    super.hintFadeDuration,
    super.maintainHintSize,
    super.maintainLabelSize,
    super.error,
    String? errorText,
    super.errorStyle,
    super.errorMaxLines,
    super.floatingLabelBehavior,
    super.floatingLabelAlignment,
    super.isCollapsed,
    super.isDense,
    super.contentPadding,
    super.prefixIcon,
    super.prefixIconConstraints,
    super.prefix,
    String? prefixText,
    super.prefixStyle,
    super.prefixIconColor,
    super.suffixIcon,
    super.suffix,
    String? suffixText,
    super.suffixStyle,
    super.suffixIconColor,
    super.suffixIconConstraints,
    super.counter,
    String? counterText,
    super.counterStyle,
    super.filled,
    super.fillColor,
    super.focusColor,
    super.hoverColor,
    super.errorBorder,
    super.focusedBorder,
    super.focusedErrorBorder,
    super.disabledBorder,
    super.enabledBorder,
    super.border,
    super.enabled,
    String? semanticCounterText,
    super.alignLabelWithHint,
    super.constraints,
    super.visualDensity,
  }) : super(
          labelText: DawaTranslations.maybeTranslate(
            labelText,
            DawaLocaleController.instance.locale,
          ),
          helperText: DawaTranslations.maybeTranslate(
            helperText,
            DawaLocaleController.instance.locale,
          ),
          hintText: DawaTranslations.maybeTranslate(
            hintText,
            DawaLocaleController.instance.locale,
          ),
          errorText: DawaTranslations.maybeTranslate(
            errorText,
            DawaLocaleController.instance.locale,
          ),
          prefixText: DawaTranslations.maybeTranslate(
            prefixText,
            DawaLocaleController.instance.locale,
          ),
          suffixText: DawaTranslations.maybeTranslate(
            suffixText,
            DawaLocaleController.instance.locale,
          ),
          counterText: DawaTranslations.maybeTranslate(
            counterText,
            DawaLocaleController.instance.locale,
          ),
          semanticCounterText: DawaTranslations.maybeTranslate(
            semanticCounterText,
            DawaLocaleController.instance.locale,
          ),
        );
}

material.InlineSpan _translateSpan(
  material.InlineSpan span,
  material.Locale locale,
) {
  if (span is! material.TextSpan) return span;
  return material.TextSpan(
    text: span.text == null
        ? null
        : DawaTranslations.translate(span.text!, locale),
    children: span.children
        ?.map((child) => _translateSpan(child, locale))
        .toList(growable: false),
    style: span.style,
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: DawaTranslations.maybeTranslate(
      span.semanticsLabel,
      locale,
    ),
    locale: span.locale,
    spellOut: span.spellOut,
  );
}
