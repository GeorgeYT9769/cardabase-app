import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _onlineContent = 'Loading...';
  String _localContent = 'Loading...';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchOnlineContent();
    fetchLocalContent();
  }

  Future<void> fetchOnlineContent() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/GeorgeYT9769/cardabase-app/refs/heads/main/CHANGELOG.txt',
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          _onlineContent = response.body;
        });
      } else {
        setState(() {
          _onlineContent = 'Failed to load online content.';
        });
      }
    } catch (e) {
      setState(() {
        _onlineContent =
            'Could not load online content. Please check your internet connection and try again.';
      });
    }
  }

  Future<void> fetchLocalContent() async {
    try {
      final content = await rootBundle.loadString('CHANGELOG.txt');
      setState(() {
        _localContent = content;
      });
    } catch (e) {
      setState(() {
        _localContent = 'Could not load local content. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Changelog', style: theme.textTheme.titleLarge?.copyWith()),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: theme.colorScheme.surface,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: theme.colorScheme.secondary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
        bottom: TabBar(
          physics: const BouncingScrollPhysics(
            decelerationRate: ScrollDecelerationRate.fast,
          ),
          controller: _tabController,
          labelStyle: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.inverseSurface, fontSize: 18),
          unselectedLabelStyle: theme.textTheme.bodyLarge
              ?.copyWith(color: theme.colorScheme.tertiary, fontSize: 18),
          indicatorColor: theme.colorScheme.inverseSurface,
          splashFactory: NoSplash.splashFactory,
          tabs: const [
            Tab(text: 'Online'),
            Tab(text: 'Local'),
          ],
        ),
      ),
      body: TabBarView(
        physics: const BouncingScrollPhysics(
          decelerationRate: ScrollDecelerationRate.fast,
        ),
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: fetchOnlineContent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  _onlineContent,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.inverseSurface,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: fetchLocalContent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  _localContent,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.inverseSurface,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
