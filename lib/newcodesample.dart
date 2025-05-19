import 'package:flutter/material.dart';

class FlutterWidgetList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Widget List"),
      ),
      body: ListView(
        padding: EdgeInsets.all(10),
        children: [
          // GestureDetector
          GestureDetector(
            onTap: () {
              print("Tapped on GestureDetector!");
            },
            child: Container(
              color: Colors.green,
              padding: EdgeInsets.all(20),
              child: Text("GestureDetector - Tap Me!"),
            ),
          ),
          SizedBox(height: 10),

          // TextButton
          TextButton(
            onPressed: () {
              print("Text Button Pressed");
            },
            child: Text("TextButton - Press Me"),
          ),
          SizedBox(height: 10),

          // IconButton
          IconButton(
            icon: Icon(Icons.favorite),
            onPressed: () {
              print("IconButton Tapped!");
            },
          ),
          SizedBox(height: 10),

          // InkResponse
          InkResponse(
            onTap: () {
              print("Tapped with InkResponse!");
            },
            child: Container(
              color: Colors.orange,
              padding: EdgeInsets.all(20),
              child: Text("InkResponse - Tap Me!"),
            ),
          ),
          SizedBox(height: 10),

          // LongPressGestureRecognizer
          GestureDetector(
            onLongPress: () {
              print("Long press detected");
            },
            child: Container(
              color: Colors.purple,
              padding: EdgeInsets.all(20),
              child: Text("GestureDetector - Long Press Me!"),
            ),
          ),
          SizedBox(height: 10),

          // PopupMenuButton
          PopupMenuButton<String>(
            onSelected: (String result) {
              print(result);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Option 1',
                child: Text('Option 1'),
              ),
              const PopupMenuItem<String>(
                value: 'Option 2',
                child: Text('Option 2'),
              ),
            ],
            child: Container(
              color: Colors.blue,
              padding: EdgeInsets.all(20),
              child: Text("PopupMenuButton - Tap Me!"),
            ),
          ),
          SizedBox(height: 10),

          // Dismissible
          Dismissible(
            key: Key('item1'),
            onDismissed: (direction) {
              print("Item dismissed!");
            },
            child: ListTile(
              title: Text('Swipe to dismiss'),
            ),
          ),
          SizedBox(height: 10),

          // Draggable
          Draggable<String>(
            data: 'Dragged Item',
            child: Container(
              color: Colors.blue,
              padding: EdgeInsets.all(20),
              child: Text('Drag Me'),
            ),
            feedback: Material(
              child: Container(
                color: Colors.red,
                padding: EdgeInsets.all(20),
                child: Text('Being dragged'),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Slider
          Slider(
            value: 0.5,
            onChanged: (newValue) {
              print("Slider Value: $newValue");
            },
          ),
        ],
      ),
    );
  }
}
