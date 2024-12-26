import 'package:flutter/material.dart';
import 'joke_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joke App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const JokeListPage(title: 'Joke App'),
    );
  }
}

class JokeListPage extends StatefulWidget {
  const JokeListPage({super.key, required this.title});

  final String title;

  @override
  State<JokeListPage> createState() => _JokeListPageState();
}

class _JokeListPageState extends State<JokeListPage> {
  final JokeService _jokeService = JokeService();
  List<Map<String, dynamic>> jokes = [];
  List<Map<String, dynamic>> filteredJokes = [];
  bool isLoading = false;
  String searchQuery = '';

  Future<void> fetchJokes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedJokes = await _jokeService.fetchJokesRaw();
      setState(() {
        jokes = fetchedJokes;
        filteredJokes = jokes; // Initially display all jokes
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching jokes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void updateSearchQuery(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredJokes = jokes.where((joke) {
        final setup = (joke['setup'] ?? joke['joke'] ?? '').toLowerCase();
        final delivery = (joke['delivery'] ?? '').toLowerCase();
        return setup.contains(searchQuery) || delivery.contains(searchQuery);
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchJokes(); // Fetch jokes on startup
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade50, Colors.pink.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              backgroundColor: Colors.pink,
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search jokes...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: fetchJokes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      minimumSize: const Size(350, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fetch jokes',
                      style: TextStyle(fontSize: 23, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              )
            else if (filteredJokes.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'No jokes found!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final joke = filteredJokes[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              joke.containsKey('setup') ? joke['setup']! : joke['joke']!,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (joke.containsKey('delivery'))
                              Text(
                                joke['delivery']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filteredJokes.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
