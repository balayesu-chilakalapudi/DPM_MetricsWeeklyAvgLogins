# Process high volume of data with an apex batch class batch wise

Usually processing high volume of data takes long time. To improve accuray and speed of processing below steps need to remember.
1) Do not add scope wise list of records inside execute method instead create a global map and process scope wise batch of records and reuse this map in finish method.
2) Always avoid nested for-loops inside execute method of batch class.
3) Avoid lists inside maps and adding items to lists inside maps. Instead maintain a number to size the list inside maps.
4) Use wrapper classes to hold data.
5) Use finish method to send email and other final tasks.

