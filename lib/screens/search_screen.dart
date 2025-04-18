import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../models/weather_provider.dart';

/// Screen for searching and adding new locations.
///
/// Provides a searchable interface for finding geographical locations
/// that can be added to the user's saved locations list for weather tracking.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  /// Controller for the search input field.
  final _searchController = TextEditingController();

  @override
  void dispose() {
    /// Properly dispose of the text controller to prevent memory leaks.
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Location')),
      body: Column(
        children: [
          /// Search input field with real-time search functionality.
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

                /// Display clear button only when text is present.
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<WeatherProvider>(
                              context,
                              listen: false,
                            ).clearSearchResults();
                          },
                        )
                        : null,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),

              /// Trigger search as the user types for immediate feedback.
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _performSearch();
                } else {
                  Provider.of<WeatherProvider>(
                    context,
                    listen: false,
                  ).clearSearchResults();
                }
              },
            ),
          ),

          /// Results area - expands to fill available space.
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  /// Builds the search results area with appropriate visual states.
  ///
  /// Handles multiple display states:
  /// - Loading indicator during active searches
  /// - Error state with retry option
  /// - Empty state with guidance text
  /// - Results list when locations are found
  Widget _buildSearchResults() {
    final weatherProvider = Provider.of<WeatherProvider>(context);

    /// Display loading spinner during active search.
    if (weatherProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    /// Display error state with retry button.
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

    /// Handle empty results with contextual messaging.
    if (weatherProvider.searchResults.isEmpty) {
      /// Show search prompt when search box is empty.
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
        /// Show 'no results' message when search yields no locations.
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

    /// Display the list of search results.
    return ListView.builder(
      itemCount: weatherProvider.searchResults.length,
      itemBuilder: (context, index) {
        final location = weatherProvider.searchResults[index];
        return _buildLocationItem(location);
      },
    );
  }

  /// Builds a list item for a single location result.
  ///
  /// Includes location details and appropriate action buttons based on
  /// whether the location is already saved or not.
  Widget _buildLocationItem(Location location) {
    final weatherProvider = Provider.of<WeatherProvider>(
      context,
      listen: false,
    );

    /// Determine if this location is already in the user's saved list.
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

      /// Show check icon if already saved, or add button if not.
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
                    /// Show confirmation message when a location is added.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Added to your locations:'),
                              const SizedBox(height: 4),
                              Text(
                                location.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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

      /// Tapping a location adds it (if not already saved) and selects it.
      onTap: () async {
        if (!isAlreadySaved) {
          await weatherProvider.addLocation(location);
        }
        weatherProvider.selectLocation(location);
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  /// Initiates a location search using the current query text.
  ///
  /// Clears results if the search box is empty.
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      Provider.of<WeatherProvider>(context, listen: false).clearSearchResults();
      return;
    }

    Provider.of<WeatherProvider>(context, listen: false).searchLocations(query);
  }
}
