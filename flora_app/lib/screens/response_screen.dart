// response_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
// Ensure PlantDetailsScreen is correctly updated from previous steps
import 'plant_details_screen.dart';

class ResponseScreen extends StatelessWidget {
  final Map<String, dynamic>
      identificationResult; // Contains PlantNet & Purchase Links
  final dynamic image;
  final bool isWebImage;

  const ResponseScreen({
    super.key,
    required this.identificationResult,
    required this.image,
    required this.isWebImage,
  });

  // Helper function to parse purchase links safely (Needed for PlantDetailsScreen)
  List<Map<String, dynamic>> _parsePurchaseLinks(Map<String, dynamic> result) {
    if (result.containsKey('purchase_links') &&
        result['purchase_links'] is List) {
      final List<dynamic> linksRaw = result['purchase_links'];
      return List<Map<String, dynamic>>.from(
          linksRaw.whereType<Map<String, dynamic>>());
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    // Extract main plant name for easier access
    final String plantName =
        identificationResult['best_match_scientific_name'] ?? 'Unknown Plant';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                plantName, // Display best match name in AppBar
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis, // Prevent overflow
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  isWebImage
                      ? Image.memory(image as Uint8List,
                          fit: BoxFit.cover) // Use Uint8List for web
                      : Image.file(image as File, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.5, 1.0], // Adjust gradient
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // This adapter holds the main content BELOW the app bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Section to Display PlantNet Main Result ---
                  _buildMainResult(), // <--- THIS DISPLAYS PLANTNET BEST MATCH INFO
                  const SizedBox(height: 24),

                  // --- Section to Display PlantNet Other Matches ---
                  _buildOtherMatches(), // <--- THIS DISPLAYS PLANTNET OTHER POSSIBILITIES
                  const SizedBox(height: 32),

                  // --- Button to navigate to Details Screen (GROQ + Links) ---
                  _buildKnowMoreButton(context, plantName),
                  const SizedBox(height: 16), // Padding at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Displays the BEST MATCH from PlantNet ---
  Widget _buildMainResult() {
    // Access data directly from the identificationResult map
    final String scientificName =
        identificationResult['best_match_scientific_name'] ?? 'Unknown';
    // Handle potential null or empty string for common names
    final String commonNamesRaw =
        identificationResult['best_match_common_names'] ?? '';
    final String commonNamesDisplay =
        commonNamesRaw.isEmpty ? 'No common names available' : commonNamesRaw;

    return Card(
      elevation: 4, // Added elevation
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)), // Consistent styling
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 28), // Icon indicating success
                SizedBox(width: 10),
                Text(
                  'Top Identification Result', // Clearer title
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(thickness: 1, height: 24), // Slightly thicker divider
            Text(
              'Scientific Name:',
              style: TextStyle(
                fontSize: 15, // Slightly smaller label
                color: Colors.grey[700], // Darker grey
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              scientificName,
              style: const TextStyle(
                fontSize: 19, // Slightly adjusted size
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Common Names:',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              commonNamesDisplay,
              style: const TextStyle(
                fontSize: 17, // Slightly adjusted size
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- End _buildMainResult ---

  // --- Displays OTHER possible matches from PlantNet ---
  Widget _buildOtherMatches() {
    // Safely access the nested list of results
    final resultsData = identificationResult['results'];
    if (resultsData == null ||
        resultsData is! Map ||
        !resultsData.containsKey('results') ||
        resultsData['results'] is! List) {
      print(
          "Warning: 'results' data structure is not as expected or missing."); // Debug print
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text("No other matches found or data error.")),
      ); // Return an informative widget if data is bad
    }
    final List results = resultsData['results'] as List;

    // Don't show this section if there are no other results
    if (results.isEmpty ||
        (results.length == 1 &&
            results[0]['scientific_name'] ==
                identificationResult['best_match_scientific_name'])) {
      // Only show if there are genuinely *other* results beyond the best match
      return const SizedBox.shrink();
    }

    // Limit the number of results shown (e.g., top 3 excluding the best match if it's repeated)
    final List displayResults = results
        .where((r) =>
            r['scientific_name'] !=
            identificationResult['best_match_scientific_name'])
        .take(3) // Take the next 3 *different* results
        .toList();

    if (displayResults.isEmpty) {
      return const SizedBox.shrink(); // Hide if filtering leaves no results
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 4, bottom: 12, top: 8), // Adjusted padding
          child: Text(
            'Other Possible Matches',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800] // Darker title
                ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true, // Essential inside Column/ScrollView
          physics:
              const NeverScrollableScrollPhysics(), // Disable inner scrolling
          itemCount: displayResults.length, // Use filtered list length
          itemBuilder: (context, index) {
            // Safely access data within each result map
            final result = displayResults[index];
            final String scientificName = result['scientific_name'] ?? 'N/A';
            final List commonNamesList =
                result['common_names'] is List ? result['common_names'] : [];
            final String commonNames = commonNamesList.join(', ');
            final double scoreRaw = result['score'] is num
                ? (result['score'] as num).toDouble()
                : 0.0;
            final String score = (scoreRaw * 100).toStringAsFixed(1);

            return Card(
              elevation: 2, // Subtle elevation
              margin:
                  const EdgeInsets.only(bottom: 10), // Spacing between cards
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                  // Visual ranking
                  radius: 16,
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  child: Text(
                    '${index + 1}', // Rank (starts from 1)
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                title: Text(
                  scientificName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  commonNames.isNotEmpty
                      ? commonNames
                      : 'No common names', // Handle empty common names
                  style: TextStyle(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  // Confidence score
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score%',
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  // --- End _buildOtherMatches ---

  // --- Button to fetch GROQ details and navigate ---
  Widget _buildKnowMoreButton(BuildContext context, String plantName) {
    // This function remains the same as the previous correct version
    // It fetches GROQ data and navigates to PlantDetailsScreen,
    // passing the GROQ data AND the purchaseLinks.

    return Center(
      child: ElevatedButton.icon(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context); // Store messenger
          messenger.showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                  SizedBox(width: 16),
                  Text('Loading plant details...'),
                ],
              ),
              duration: Duration(minutes: 1), // Keep open until dismissed
            ),
          );

          try {
            // Extract Purchase Links HERE (needed for the NEXT screen)
            final List<Map<String, dynamic>> purchaseLinks =
                _parsePurchaseLinks(identificationResult);

            // Make API request to get GROQ plant details
            final response = await http.post(
              // Ensure your API endpoint is correct
              Uri.parse('http://127.0.0.1:8000/api/plant-details/'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'plant_name': plantName}),
            );

            messenger.hideCurrentSnackBar(); // Dismiss loading indicator

            if (!context.mounted) return;

            if (response.statusCode == 200) {
              final additionalInfo =
                  jsonDecode(response.body); // This is GROQ data

              // Navigate, passing GROQ data AND Purchase Links
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlantDetailsScreen(
                    plantName: plantName,
                    additionalInfo: additionalInfo, // From GROQ
                    purchaseLinks: purchaseLinks, // From PlantNet Response
                  ),
                ),
              );
            } else {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to load details: ${response.statusCode} ${response.reasonPhrase}'),
                  backgroundColor: Colors.red.shade800,
                ),
              );
            }
          } catch (e) {
            messenger.hideCurrentSnackBar();
            if (!context.mounted) return;
            messenger.showSnackBar(
              SnackBar(
                content: Text('Error fetching details: $e'),
                backgroundColor: Colors.red.shade800,
              ),
            );
          }
        },
        icon: const Icon(Icons.info_outline),
        label: const Text('Know more about this plant'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          backgroundColor:
              Theme.of(context).colorScheme.primary, // Ensure button stands out
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
  // --- End _buildKnowMoreButton ---
}
