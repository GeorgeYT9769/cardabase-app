import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_new_shapes/material_new_shapes.dart';

import '../util/expressive_loading_indicator.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: FutureBuilder<String>(
        future: rootBundle.loadString('TermsOfService.txt'),
        builder: (context, snapshot) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              decelerationRate: ScrollDecelerationRate.fast,
            ),
            slivers: [
              SliverAppBar(
                title: Text(
                  'TOS',
                  style: theme.textTheme.titleLarge,
                ),
                centerTitle: true,
                elevation: 0,
                backgroundColor: theme.colorScheme.surface,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: theme.colorScheme.secondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                floating: true,
                snap: true,
              ),
              if (snapshot.hasData)
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: SelectableText(
                      snapshot.data!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                )
              else if (snapshot.hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Error loading Terms of Service',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ),
                )
              else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ExpressiveLoadingIndicator(
                      color: Theme.of(context).colorScheme.tertiary,
                      constraints: const BoxConstraints(
                        minWidth: 64.0,
                        minHeight: 64.0,
                        maxWidth: 64.0,
                        maxHeight: 64.0,
                      ),
                      polygons: [
                        MaterialShapes.softBurst,
                        MaterialShapes.pentagon,
                        MaterialShapes.pill,
                      ],
                      semanticsLabel: 'Loading',
                      semanticsValue: 'In progress',
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 50),
              ),
            ],
          );
        },
      ),
    );
  }
}
