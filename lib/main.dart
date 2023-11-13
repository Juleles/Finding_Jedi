// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter API',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List _items = [];
  List _filteredItems = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    readJson();
  }

  Future<void> readJson() async {
    final String response = await rootBundle.loadString('assets/sample.json');
    final data = await json.decode(response);
    setState(() {
     _items = data["items"].map((item) {
    item['rating'] = 0.0; // Initially setting the rating to 0
    return item;
  }).toList();
  _filteredItems = List.from(_items); // Update filtered items too
    });
  }

  void filterItems(String query) {
    // Filtering items based on the query
    setState(() {
      _filteredItems = _items
          .where((item) =>
              item["name"]
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              item["gender"]
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              item["species"]
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  void showItemDetails(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetails(item: _filteredItems[index]),
      ),
    );
  }

  void filterSearchResults(String query) {
    List dummySearchList = [];
    dummySearchList.addAll(_items);
    if (query.isNotEmpty) {
      List dummyListData = [];
      dummySearchList.forEach((item) {
        if (item['name'].toLowerCase().contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        _filteredItems = dummyListData;
      });
      return;
    } else {
      setState(() {
        _filteredItems = _items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: const Text("FINDING JEDI", style: TextStyle(color: Color.fromRGBO(191, 150, 2, 1), fontWeight: FontWeight.bold),),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/picture.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  style: TextStyle(color: Color.fromRGBO(191, 150, 2, 1), fontWeight: FontWeight.bold),
                  controller: _searchController,
                  onChanged: (value) {
                    filterSearchResults(value);
                  },
                  decoration: const InputDecoration(
                    //labelText: 'Search your character here',
                    hintText: 'Search your Jedi here',
                    hintStyle: TextStyle(color: Color.fromRGBO(191, 150, 2, 1), fontWeight: FontWeight.bold)
                  ),
                ),
              ),
              _filteredItems.isNotEmpty
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              showItemDetails(index);
                            },
                            child: Card(
                              key: ValueKey(_filteredItems[index]["id"]),
                              margin: const EdgeInsets.all(10),
                              color: Colors.amber,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                      _filteredItems[index]["image"]),
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_filteredItems[index]["name"]),
                                    Text(_filteredItems[index]["gender"]),
                                    Text(_filteredItems[index]["species"]),
                                    
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      child: Text("No results"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemDetails extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetails({Key? key, required this.item}) : super(key: key);

  @override
  _ItemDetailsState createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  late SharedPreferences _prefs;
  late double _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  _loadRating() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentRating = _prefs.getDouble('${widget.item["id"]}_rating') ?? 0.0;
    });
  }

  _saveRating(double rating) async {
    setState(() {
      _currentRating = rating;
    });
    await _prefs.setDouble('${widget.item["id"]}_rating', rating);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item["name"]),
      ),
      body: Stack(
        children: [
          Center(
            child: AnimatedBackground(), // Add the moving background
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(padding: EdgeInsets.only(top: 140)),
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.item["image"]),
                  radius: 50,
                ),
                const SizedBox(height: 20),
                Text("Name: ${widget.item["name"]}".toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Gender: ${widget.item["gender"]}".toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Species: ${widget.item["species"]}".toUpperCase(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: _currentRating,
                  minRating: 0,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 10,
                  itemSize: 30,
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.purple,
                  ),
                  unratedColor: Colors.grey,
                  onRatingUpdate: (rating) {
                    _saveRating(rating);
                  },
                ),
                Text('Rating: $_currentRating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({Key? key}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 20), // Adjust the duration for speed
    )..repeat();
  }

@override
Widget build(BuildContext context) {
  return Stack(
    children: [
      // Background Color
      Container(
        color: Colors.black, // Set your desired background color
        width: double.infinity,
        height: double.infinity,
      ),
      // Centered AnimatedBuilder
      Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.1415, // Rotates the background
              child: Transform.scale(
                scale: 0.5, // Change this value to resize the image
                child: Image.asset('assets/blackhole.png'),
              ),
            );
          },
        ),
      ),
    ],
  );
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
