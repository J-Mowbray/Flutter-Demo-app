import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../models/weather_provider.dart'; // Import WeatherProvider

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Location')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for a city...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<WeatherProvider>(
                              context,
                              listen: false,
                            ).clearSearchResults(); // Clear search results via WeatherProvider
                          },
                        )
                        : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _performSearch();
                } else {
                  Provider.of<WeatherProvider>(
                    context,
                    listen: false,
                  ).clearSearchResults(); // Clear search results via WeatherProvider
                }
              },
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    if (weatherProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (weatherProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error searching for locations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(weatherProvider.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (weatherProvider.searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.5 * 255),
              ),
              const SizedBox(height: 16),
              Text(
                'Search for a city to add',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7 * 255),
                ),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.5 * 255),
              ),
              const SizedBox(height: 16),
              Text(
                'No locations found',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7 * 255),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try a different search term',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5 * 255),
                ),
              ),
            ],
          ),
        );
      }
    }

    return ListView.builder(
      itemCount: weatherProvider.searchResults.length,
      itemBuilder: (context, index) {
        final location = weatherProvider.searchResults[index];
        return _buildLocationItem(location);
      },
    );
  }

  Widget _buildLocationItem(Location location) {
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    // Check if location already exists in saved locations
    bool isAlreadySaved = weatherProvider.savedLocations.any(
      (loc) =>
          loc.latitude == location.latitude &&
          loc.longitude == location.longitude,
    );

    return ListTile(
      leading: const Icon(Icons.location_on),
      title: Text(location.name),
      subtitle: Text(
        '${location.latitude.toStringAsFixed(2)}, ${location.longitude.toStringAsFixed(2)}',
      ),
      trailing:
          isAlreadySaved
              ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
              : IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await weatherProvider.addLocation(location);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Use min size instead of fixed height
                        children: [
                          const Text('Added to your locations:'),
                          const SizedBox(height: 4),
                          Text(
                            location.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );

              }
            },
            tooltip: 'Add to saved locations',
          ),

      onTap: () async {
        if (!isAlreadySaved) {
          await weatherProvider.addLocation(
            location,
          ); // Add via WeatherProvider
        }
        weatherProvider.selectLocation(location); // Select via WeatherProvider
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).clearSearchResults(); // Clear via WeatherProvider
      return;
    }

    Provider.of<WeatherProvider>(
      context,
      listen: false,
    ).searchLocations(query); // Search via WeatherProvider
  }
}
