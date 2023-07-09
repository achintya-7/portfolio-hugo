---
title: "Flutter Isolates 101"
description: "How to use isolates in Flutter to run computationally intensive tasks in the background."
dateString: July 2023
draft: false
tags: ["Flutter", "Isolates"]
weight: 90
cover:
    image: "/blog/flutter-isolates/img-1.jpg"
---

## What are Isolates?
* In Flutter Isolates are a way to run computationally intensive tasks in the background. Isolates are independent and do not share memory. 
* They communicate with each other by sending messages. This is a very important concept to understand. Isolates are not threads and they do not share memory. 
* This means that you cannot access variables from the main isolate in a background isolate. You can only send messages to the main isolate and vice versa. 

## Where to use Isolates?
* Isolates are useful when you have to perform a computationally intensive task in the background. For example, if you have to perform a heavy calculation or you have to download a large file from the internet, you can use isolates to perform these tasks in the background. 
* For this blog, we will run a function which will find the count of prime numbers between 1 and 200000. This is a computationally intensive task of about O(n^2)

Here is the code for the function:
```dart
Future<List<int>> getPrimes() async {
  bool isPrime(int n) {
    if (n <= 1) {
      return false;
    }
    for (var i = 2; i < n / 2; i++) {
      if (n % i == 0) {
        return false;
      }
    }
    return true;
  }

  final List<int> primes = [];
  for (var i = 0; i < 200000; i++) {
    if (isPrime(i)) {
      primes.add(i);
    }
  }

  log("No. Of Primes: ${primes.length}");

  return primes;
}
``` 

Lets run this function without isolates. I have a simple page with one `CircularProgressIndicator` and one `Button` widget. We will observe the UI when we click the button. 
Here is the code for it.
```dart
{
    const SizedBox(height: 20),
    const CircularProgressIndicator(),
    const SizedBox(height: 20),
    FilledButton.tonal(
        child: const Text("Get Primes"),
        onPressed: () async => await getPrimes(),
    ),
}
```
![](/blog/flutter-isolates/gif-1.gif)
We can see that the UI is blocked while the function is running.

## How to use Isolates?
You can spawn a new isolate by calling the `Isolate.spawn()` method. Lets see how to use it.
![](/blog/flutter-isolates/img-2.png)
* Now, firstly we will modify our functions a bit. Firstly we will modify our getPrimes() function. A function to be used in an isolate should be an void function and it cant return any value like a normal function. It will also accept one parameter as SendPort.
```dart
void getPrimes(SendPort sendPort) {
  bool isPrime(int n) {
    if (n <= 1) {
      return false;
    }
    for (var i = 2; i < n / 2; i++) {
      if (n % i == 0) {
        return false;
      }
    }
    return true;
  }

  final List<int> primes = [];
  for (var i = 0; i < 200000; i++) {
    if (isPrime(i)) {
      primes.add(i);
    }
  }

  sendPort.send(primes);
}
```
* Here we will return our list of primes using the sendPort. Think of sendPort like a pipe which will be used to transfer data from one isolate to another. Remember, all isolates as the name suggests are isolated and do not share memory. If you are familiar with Go, think of SendPort as a channels.

* Now we will modify the onPressed method of our button such that it will spawn a new isolate and run our getPrimes() function in it.
```dart
FilledButton.tonal(
    child: const Text("Get Primes"),
    onPressed: () async {
        final receivePort = ReceivePort();
        await Isolate.spawn(getPrimes, receivePort.sendPort);
        final List<int> primes = await receivePort.first;
        Fluttertoast.showToast(msg: "Primes: ${primes.length}");
    },
),
```
* We build a receivePort object and use it to spawn a new isolate. Then we will get the first value from receivePort after it completes its task. Then we will show it out using `FlutterToast`.

![](/blog/flutter-isolates/gif-2.gif)
* We can see that the UI is not blocked anymore. We can interact with the UI while the function is running in the background.

## Sending Additional Data to Isolates
* In the previous example, you can see that we were using a constant value of 200000. But what if we want to send a variable value to the isolate?
* For that we can send a `Map` object to the isolate. Lets see how to do it. You can send any type of object T here so if you have a custom data object. You can send it too.
* First lets modify the onPressed method of our button.
```dart
FilledButton.tonal(
    child: const Text("Get Primes"),
    onPressed: () async {
        final receivePort = ReceivePort();
        Map<String, dynamic> args = {
            "sendPort": receivePort.sendPort, 
            "n": 100000,
        };
        await Isolate.spawn(getPrimes, args);
        final List<int> primes = await receivePort.first;
        Fluttertoast.showToast(msg: "Primes: ${primes.length}");
    },
),
```
* Here we are sending a Map object with two keys. One is the sendPort and the other is the value of n. Now lets modify our getPrimes() function to accept this Map object.
```dart
void getPrimes(Map<String, dynamic> args) {
  final int n = args["n"];
  final SendPort sendPort = args["sendPort"];

  bool isPrime(int n) {
    if (n <= 1) {
      return false;
    }
    for (var i = 2; i < n / 2; i++) {
      if (n % i == 0) {
        return false;
      }
    }
    return true;
  }

  final List<int> primes = [];
  for (var i = 0; i < n; i++) {
    if (isPrime(i)) {
      primes.add(i);
    }
  }

  sendPort.send(primes);
}
```
* Here we are getting the value of n and the sendPort from the Map object. Now we can use the value of n in our function.
* And thats it. Now we can send any type of object to our isolate.

## The Better Way
* Well what we have done previously can be considered the Boomer way but its a better way to understand the concept and understand how isolates * work. 
* There is a better way to call isolates using the `compute()` method. Lets see how to use it.
* The onPressed button can be reduced to this.
```dart
FilledButton.tonal(
    child: const Text("Get Primes"),
    onPressed: () async {
        final List<int> primes = await compute(getPrimes, 100000);
        Fluttertoast.showToast(msg: "Primes: ${primes.length}");
    },
),
```
* Similarly there will be some changes to the getPrimes() function.
```dart
List<int> getPrimes(int n) {
  bool isPrime(int n) {
    if (n <= 1) {
      return false;
    }
    for (var i = 2; i < n / 2; i++) {
      if (n % i == 0) {
        return false;
      }
    }
    return true;
  }

  final List<int> primes = [];
  for (var i = 0; i < n; i++) {
    if (isPrime(i)) {
      primes.add(i);
    }
  }

  return primes;
}
```
* Now, we have written it as a normal function. This indeed is the better way to call isolates.

## Conclusion
Isolates are a great way to run computationally intensive tasks in the background. Here we saw 2 ways to call isolates. One is the normal way and the other is the better way. I hope you liked this blog and you learned something new.





