import 'package:flutter/material.dart';

class ProductListScreen extends StatelessWidget {
  ProductListScreen({super.key});

  final List<Map<String, String>> products = [
    {
      "name": "Basmati Rice",
      "stock": "3 Bags (25kg)",
      "price": "Rs. 3,500",
      "category": "GRAINS & RICE"
    },
    {
      "name": "Red Lentils",
      "stock": "42 kg",
      "price": "Rs. 140/kg",
      "category": "LENTILS & DALS"
    },
    {
      "name": "Turmeric Powder",
      "stock": "18 pkts",
      "price": "Rs. 250/pkt",
      "category": "SPICES"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "SmartShelf",
          style: TextStyle(
            color: Color(0xFF1E2A78),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_outline),
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(12),

        child: Column(
          children: [

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: "Search inventory...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category Buttons
            Row(
              children: [
                categoryButton("ALL ITEMS", true),
                const SizedBox(width: 8),
                categoryButton("GRAIN & RICE", false),
              ],
            ),

            const SizedBox(height: 16),

            // Product List
            Expanded(
              child: ListView.builder(
                itemCount: products.length,

                itemBuilder: (context, index) {

                  final product = products[index];

                  return productCard(product);
                },
              ),
            ),
          ],
        ),
      ),

      // Floating Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E2A78),
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Products",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: "Analytics",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: "Settings",
          ),
        ],
      ),
    );
  }

  Widget categoryButton(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: selected
            ? Colors.amber
            : Colors.grey.shade200,

        borderRadius: BorderRadius.circular(8),
      ),

      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget productCard(Map<String, String> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            product["category"]!,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            product["name"]!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Stock: ${product["stock"]}",
            style: const TextStyle(
              color: Colors.red,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              Text(
                product["price"]!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          )
        ],
      ),
    );
  }
}