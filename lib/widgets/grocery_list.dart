import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_item.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  var _isLoading = false;
  String? error; //error could be null but if its not null then its a String

  @override
  void initState() {
    super
        .initState(); //the initial State of the screen is loaded with the response of the get request
    _loadItems(); // this is to load the data(send a get request to db) for the first time from db
  }

  void _loadItems() async {

    try{
      final url = Uri.https(
        'flutter-shoppinglist-6d84a-default-rtdb.firebaseio.com',  //remove .com and check handling
        'shopping-list-items.json');
    final response = await http.get(url); //the http requests could also throw errors like when there is not internet connection and this req cant be made, to handle these exceptions gracefully we use the try-catch block(else the app would be put is an undesireable state even crash the app maybe) so try-catch helps us handle exceptions and put the app in a proper state. 

    if (response.statusCode >= 400) { //these error handlings are response based (what if u dont get an response at all when a req is made hence we use try-catch to handle such errors).
      setState(() {
        //updating the UI because this condition is checked outside the build method
        error = 'Failed to fetch the data, Please try again later';
      });
    }

    if(response.body == 'null'){  //firebase sends the null message in a string(depends on the backend) 
    setState(() {
      _isLoading = false;   //if this is not handled then in a case where we dont have any items in the backend and we reload the app we are stuck in a loading screen
      //because we try to convert(decode json data) the data from backend to a map and dart tells us that null is not a subtype of type map.
    });
      return;

    }

    //final Map<String, Map<String, dynamic>> listdbItems = //sometimes this might be too specific for dart go for simplier versions
    final Map<String, dynamic> listdbItems = json.decode(response
        .body); //have to map our json response to its data structure and add that to our list
    final List<GroceryItem> toLoadItems = [];

    for (final item in listdbItems.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value; //comparing data from backend against data in memory/local data

      toLoadItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category)); //created a category object
    }

    setState(() {
      _groceryItems =
          toLoadItems; //overriding the exsting list with the updated list(getting data from backend)
      _isLoading = false;
    });
    // setState(() {
    //   _groceryItems.add());
    // });
    //print(response);
    }
    catch(err){
      setState(() {
        error = 'Something Went Wrong, Please try again later';
      });
    }
    
  }

  void _addItem() async {
    //_isLoading = true;
    //we will get this data in the future from the user
    //final newItem = in new_item.dart we are no longer passing data to this screen
    final newItem = await Navigator.of(context).push<GroceryItem>(
        //try to set the state in the same method where we get the data from screen B to screen A here .push<List/any ds>()
        MaterialPageRoute(builder: (context) => const NewItem()));

    if (newItem == null) {
      return; //return -> dont execute any further code, no need for any sort of action
    }

    setState(() {
      _groceryItems.add(
          newItem); //here we would want to re-execute the build method again as we have received new data from user and we need to display that hence we execute the build method accouring to the user data and create a new listTile for that
    });

    //Now we are waiting for the user to come to this screen and then fetch the same data from the backend

    //_loadItems(); //to get the data that was just added to the db and display it to use in this screen
    //commented out _loadItems() here because we dont need to a get request everytime to reflect the data that has just been entered(that has also been posted to backend) so we use the get req only when the widget tree is built(using initState)
  }

  void removeItemOnSwipe(GroceryItem item) async {
    //without error handling

    // final url = Uri.https('flutter-shoppinglist-6d84a-default-rtdb.firebaseio.com', 'shopping-list-items/${item.id}.json');   //there is always a chance that servers are down and requests cant be proccessed hence we have to handle this here (cant delete a item).
    // //final response =
    // http.delete(url);   // no need to use async await as we dont need to wait for the response (deletion will be done in the background and we are not using its response anywhere)
    // //we just need to hit the url with the item id
    // setState(() {
    //   _groceryItems.remove(item);
    // });

    //here we first remove the item from the list and update the UI for the same item being removed and then hit the delete endpoint and try deleting it from backend if it fails due to statuscode >=400 then revert it back i.e insert back the item in its original position

    //with error handling

    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    

    final url = Uri.https(
        'flutter-shoppinglist-6d84a-default-rtdb.firebaseio.com',
        'shopping-list-items/${item.id}.json');

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Sorry unable to process this request at the moment, Please try again later'),backgroundColor: Colors.white,));
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
        child: Text(
      'No Grocery Items Found, Try adding some using the + symbol',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    ));

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(), //to give feedback to the user
      );
    }

    if (error != null) {
      content = Center(
        child: Text(error!), //error handling
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
          itemCount: _groceryItems.length,
          itemBuilder: (context, index) => Dismissible(
                onDismissed: (direction) {
                  //till this statement represents that we have swiped in a direction and now we have to pass the logic as to what happens when it is swiped
                  removeItemOnSwipe(_groceryItems[index]);
                },
                key: ValueKey(_groceryItems[
                    index]), //can add _groceryItems[index].id as well for unique identifiers
                child: ListTile(
                  title: Text(_groceryItems[index].name),
                  leading: Container(
                    height: 24,
                    width: 24,
                    color: _groceryItems[index].category.color,
                  ),
                  trailing: Text(_groceryItems[index].quantity.toString()),
                ),
              ));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Grocery List'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
