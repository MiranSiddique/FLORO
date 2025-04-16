// plant_details_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PlantDetailsScreen extends StatelessWidget {
  final String plantName;
  final Map<String, dynamic> additionalInfo; // From GROQ
  final List<Map<String, dynamic>> purchaseLinks; // From initial identification

  const PlantDetailsScreen({
    super.key,
    required this.plantName,
    required this.additionalInfo, 
    required this.purchaseLinks, 
  });

  // --- Helper function to launch URL ---
  Future<void> _launchUrl(String urlString, BuildContext context) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Show error to user if launch fails
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
      print('Could not launch $urlString');
    }
  }
  // --- End Helper function ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(plantName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        // Ensures content is scrollable
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildIntroduction(), // Display GROQ Intro
            const SizedBox(height: 16),
            _buildHistory(), // Display GROQ History
            const SizedBox(height: 16),
            _buildFacts(), // Display GROQ Facts
            const SizedBox(height: 16),
            _buildUsage(), // Display GROQ Usage
            const SizedBox(height: 24), // Add spacing before the new section
            // --- Add the purchase links section ---
            _buildPurchaseLinks(context),
            const SizedBox(height: 16), // Optional padding at the bottom
          ],
        ),
      ),
    );
  }

  // --- Build methods for GROQ data ---

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            plantName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Learn more about this plant',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIntroduction() {
    if (!additionalInfo.containsKey('introduction') ||
        additionalInfo['introduction'] == null ||
        (additionalInfo['introduction'] as String).isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Introduction',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              additionalInfo['introduction'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    if (!additionalInfo.containsKey('history') ||
        additionalInfo['history'] == null ||
        (additionalInfo['history'] as String).isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              additionalInfo['history'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacts() {
    if (!additionalInfo.containsKey('facts') ||
        !(additionalInfo['facts'] is List) ||
        (additionalInfo['facts'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Interesting Facts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(
              (additionalInfo['facts'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        additionalInfo['facts'][index].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsage() {
    if (!additionalInfo.containsKey('usage') ||
        !(additionalInfo['usage'] is List) ||
        (additionalInfo['usage'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.eco, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Usage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...List.generate(
              (additionalInfo['usage'] as List).length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        additionalInfo['usage'][index].toString(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- method for Purchase Links ---
  Widget _buildPurchaseLinks(BuildContext context) {
    if (purchaseLinks.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if no links
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              // Consistent styling with other sections
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: Colors.deepOrange[
                        600]), 
                const SizedBox(width: 8),
                Text(
                  'Where to Buy (Online Search)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange[700], 
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true, // Important inside SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
              itemCount: purchaseLinks.length,
              itemBuilder: (context, index) {
                final linkData = purchaseLinks[index];
                final String siteName = linkData['site_name'] ?? 'Unknown Site';
                final String url = linkData['url'] ?? '';

                return ListTile(
                  leading: const Icon(Icons.storefront),
                  title: Text('Search on $siteName'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: url.isNotEmpty ? () => _launchUrl(url, context) : null,
                  enabled: url.isNotEmpty,
                  dense: true,
                );
              },
              separatorBuilder: (context, index) => const Divider(height: 1),
            ),
          ],
        ),
      ),
    );
  }
  // --- End Purchase Links Method ---
}
