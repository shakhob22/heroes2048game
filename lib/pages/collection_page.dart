
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:heroes2048game/services/grid-properties.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text("Select heroes"/*, style: TextStyle(color: Colors.deepOrange),*/),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, color: Colors.white, size: 32,),
          )
        ],
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,),
        itemCount: 10,
        itemBuilder: (context, index) {
          return itemsOfHeroes();
        },
      ),
    );
  }

  Widget itemsOfHeroes() {
    return Container(
      height: 100,
      width: 100,
      clipBehavior: Clip.hardEdge,
      margin: EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.orange, blurRadius: 10, offset: Offset(2, 2),),
        ]
      ),
      child: Stack(
        children: [
          Image(
            height: double.maxFinite,
            width: double.maxFinite,
            fit: BoxFit.cover,
            image: AssetImage("assets/images/clashofclanstroops/2.png"),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Text("Naruto", style: TextStyle(fontSize: 24, color: Colors.orange),),
          ),
          Center(
            child: Container(
              margin: EdgeInsets.symmetric( vertical: 50),
              width: double.maxFinite,
              color: Colors.orange.withOpacity(.9),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.live_tv, color: Colors.white, size: 42, ),
                  Text("View AD to receive", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold,),),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
