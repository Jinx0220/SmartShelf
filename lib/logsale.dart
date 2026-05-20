import 'package:flutter/material.dart';

class LogSaleScreen extends StatefulWidget {
  const LogSaleScreen({super.key});

  @override
  State<LogSaleScreen> createState() => _LogSaleScreenState();
}

class _LogSaleScreenState extends State<LogSaleScreen> {

  int quantity = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Log Sale",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Search Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const TextField(
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search product...",
                    icon: Icon(Icons.search),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Product Card
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Aashirvaad Atta 5kg",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Current Stock: 12",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "Quantity Sold",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quantity Buttons
                    Row(
                      children: [

                        // Minus Button
                        IconButton(
                          onPressed: () {

                            if(quantity > 1){
                              setState(() {
                                quantity--;
                              });
                            }

                          },

                          icon: const Icon(Icons.remove),
                        ),

                        Text(
                          quantity.toString(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Plus Button
                        IconButton(
                          onPressed: () {

                            setState(() {
                              quantity++;
                            });

                          },

                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton(
                        onPressed: () {

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Sale Logged Successfully"),
                            ),
                          );

                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),

                        child: const Text(
                          "Confirm Sale",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}