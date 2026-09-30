import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../responsive.dart';

/// Unified AppScaffold ensuring consistent background, AppBar, SafeArea and responsive limits.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final bool useSafeArea;
  final bool constrainContentWidth;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.useSafeArea = true,
    this.constrainContentWidth = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    PreferredSizeWidget? scaffoldAppBar = appBar;
    if (scaffoldAppBar == null && (title != null || titleWidget != null || leading != null || actions != null)) {
      scaffoldAppBar = AppBar(
        title: titleWidget ??
            (title != null
                ? Text(
                    title!,
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                  )
                : null),
        leading: leading,
        actions: actions,
        centerTitle: true,
      );
    }

    Widget content = body;
    if (constrainContentWidth) {
      content = MaxWidthContainer(child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? colors.bg,
      appBar: scaffoldAppBar,
      body: content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}
