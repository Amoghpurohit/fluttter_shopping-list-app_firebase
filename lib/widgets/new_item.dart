import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list_app/data/categories.dart';
import 'package:shopping_list_app/models/category.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/models/grocery_item.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {

  final _formKey = GlobalKey<FormState>();  //globalkey is a generic class here we state that the globalkey is connected to form widget 
  var enteredItemName = '';
  var enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;
  var _isSending = false;

  void _saveItem() async {
    if(_formKey.currentState!.validate()){   //formkey used to validate the given input (used as ta condition as validate() returns a boolean)
      _formKey.currentState!.save();
      
      setState(() {
        _isSending = true;  //update UI(disable buttons)
      });

      final url = Uri.https('flutter-shoppinglist-6d84a-default-rtdb.firebaseio.com', 'shopping-list-items.json'); //.json just creates a sub-folder or a node within the db // the second part of this https is the path comes after the domain
      final response = await http.post(url, headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({           //body requires since we have specified that the content-type will be sent in json format , so we encode our map to json 
        'name':enteredItemName,
        'quantity':enteredQuantity,
        'category': _selectedCategory.title,
      })
      );
      // Navigator.of(context).pop(GroceryItem(
      //   id: DateTime.now().toString(),
      //   name: enteredItemName, 
      //   quantity: enteredQuantity, 
      //   category: _selectedCategory));

      if(!context.mounted){   //check if context has not been mounted/present on the screen    //here context.mounted yeilds true if the same ui/widget/context is present and yields false if the context has changes i.e new screen new widget on top of previous one sp since flutter doesnt know whether a new context has been set or not during the await call we need to handle this
        return;  //if context has changed then return and dont execute rest of the code.
      }

      //print(response.body);
      //print(response.statusCode);
      final Map<String, dynamic> respId = json.decode(response.body); // response.body is of type String(json format now we decode it to a map and extract the value(id assigned by firebase) associated with key 'name')
      Navigator.of(context).pop(
        GroceryItem(id: respId['name'], name: enteredItemName, quantity: enteredQuantity, category: _selectedCategory)

      );   //we make sure that after the form is saved the body is posted to backend first and then we pop out of there and show the previous screen
    }  
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new Item'),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,   // very important as the entire state of the form is maintained by this globalKey , if suppose the build method is executed again and the state changes the form key maintains the previous state, and its this internal state that'll determine whether to show validation errors
              child: Column(
            children: [
              TextFormField(
                maxLength: 100,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  label: Text('Item/Name'),
                ),
                validator: (value) {
                  if(value == null || value.isEmpty || value.trim().length <=1 || value.trim().length > 50){
                    return 'Please enter input between 1 and 50';  //error to be displayed for incorrect input
                  }
                  return null; // no errors in the validation of the input
                },
                onSaved: (value){      //when validations are done and submit button is clicked we extract the values to a new variable
                  enteredItemName = value!;  //here we have to tell flutter that the value received will not be null as onSaved() wouldnt be called if the values were null.
                },
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(       //TextFormField is also (just like Row) unconstrained horizontally hence we need to add Expanded widget
                      //maxLength: 10,
                      initialValue: '1',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty || int.tryParse(value) == null || int.tryParse(value)!<=0){
                          return 'Please Enter a Valid Positive Quantity';
                        }
                        return null;
                      },
                      onSaved: (value){
                        enteredQuantity = int.parse(value!); //difference btw parse and tryParse is that parse throws an error if it fails to convert String to int but tryParse returns null if it fails to convert 
                      },
                    ),
                  ),
                  const SizedBox(width: 7,),
                  Expanded(
                    child: DropdownButtonFormField(
                      value: _selectedCategory,  //initial value in the dropdownMenu
                      items: [    //DropDownButtonFormField is also unconstrained horizontally

                      //here we need to render all the categories hence we can use a for loop and use entries to make the map k-v as items as display them
                      for (final category in categories.entries)  //converted map to iterable for it to be used in a for loop 
                        DropdownMenuItem(
                          value: category.value,  //value assigned to the dropdownMenu item
                            child: Row(
                          children: [
                            Container(
                              height: 16,
                              width: 16,
                              color: category.value.color,
                            ),
                            const SizedBox(width: 9,),
                            Text(category.value.title),
                          ],
                        ))
                    ], onChanged: (value) {
                      setState(() {
                        _selectedCategory = value!;
                      });
                        //on change value and it cannot be null as there is a initial value and you cannot not select a value
                    }),
                  )
                ],
              ),
              const SizedBox(height: 12,),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _isSending ? null : (){
                    _formKey.currentState!.reset();  //how useful is this!!
                  }, child: const Text('Reset')),
                  ElevatedButton(
                    onPressed: _isSending ? null : _saveItem, //null value on a button disables it.
                    child: _isSending ? 
                    const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(),) 
                      : 
                      const Text('Add Item')),
                ],  // onPressed -> not executing the function but just giving the reference so that it gets executed after the click/press of the button
              )
            ],
          ))),
    );
  }
}
