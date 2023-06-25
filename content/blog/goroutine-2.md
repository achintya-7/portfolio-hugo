---
title: "Concurrency in Go - Part 2"
description: "A simple guide to concurrency in Go using channels"
dateString: Oct 2022
draft: false
tags: ["Go", "Backend"]
weight: 110
cover:
    image: "/blog/goroutine-2/img_1.avif"
---

## Channels

In the Go language, a channel is a medium through which a goroutine communicates with another goroutine and this communication is lock-free. Or in other words, a channel is a technique that allows one goroutine to send data to another.

Let’s make a simple program with a channel

```go
func main() {
    now := time.Now()
    defer func () {
        fmt.Println(time.Since(now))
    }()

    channel := make(chan string)
		go count("Hello", channel)
		response := <-channel
		fmt.Println(response)
}

func count(str string, channel chan string) {
    time.Sleep(time.Second * 1)
    channel <- str

}
```

A channel is like a pipe through which you can talk among go routines. We also don't need to use concepts of wait group here and the function will execute properly.

```go
Hello
1.0133863s
```

A very good way to understand is to compare it with async await from other programming languages.

`channel <- str` is just like `return str` after an async await block

`response := <-channel` is also just like `response = await count(”Hello”)`

Let’s use this as a practical example to get a better understanding of it.

```go
func main() {
	now := time.Now()

	defer func () {
		fmt.Println(time.Since(now))
	}()

	channel0 := make(chan string)
	channel1 := make(chan string)
	channel2 := make(chan string)
	
	go dataFromSQL("query", channel0)
	go dataFromMongo("query", channel1)
	go dataFromAPI("parameters", channel2)

	fmt.Println(<-channel0)
	fmt.Println(<-channel1)
	fmt.Println(<-channel2)
}

func dataFromSQL(query string, c chan string) {
	time.Sleep(time.Second * 2)
	c <- "response from SQL"
}

func dataFromMongo(query string, c chan string) {
	time.Sleep(time.Second)
	c <- "response from MongoDB"
}

func dataFromAPI(params string, c chan string) {
	time.Sleep(time.Second)
	c <- "json from api"
}
```

This will give an output in almost 2 seconds as following

```plaintext
response from SQL
response from MongoDB
json from api
2.0094258s
```

## Closing Channels

There might be a case where we want to close the channel and tell the receiver function that its work is done and the channel can be closed so the receiver can stop listening to it. It also prevents deadlock conditions where the receiver has stopped listening but the sender is still trying to send in something.

```go
func main() {
	c := make(chan string)

	go count("Hello", c)

	for {
		msg, open := <-c

		if !open {
			break
		}
		
		fmt.Println(msg)
	}
}

func count(str string, c chan string) {
	for i := 0; i < 5; i++ {
		c <- str
		time.Sleep(time.Microsecond * 200)
	}

	close(c)
}
```

Here we are getting two responses from the channel `msg` and `open` (Boolean}. Open will us that if the channel is closed. We can check the status from `open` and break out from the loop.

There is still a better way to do this. More like a syntactical sugar.

```go
for msg := range c {
	fmt.Println(msg)
}
```

## Buffered Channels

By default, channels are unbuffered, which means that they only accept sends `chan <-` if there is a corresponding `<- chan`.

Buffered channels allow a limited number of values without corresponding receivers for those values. Buffered channels are blocked only when the buffer is full.

Making a buffered channel is quite similar to creating a simple channel.

`chan := make(chan string, 3)` where *chan string* is a type of value and 3 is the number of values it can hold.

Let’s write a code where we try to feed 2 values to an unbuffered channel.

```go
func main() {
	c := make(chan string)

	c <- "Hello"
	c <- "World"

	fmt.Println(<-c)
}
```

```plaintext
fatal error: all goroutines are asleep - deadlock!

goroutine 1 [chan send]:
main.main()
        d:/Code/GolangProjects/go-cocurency-test/main.go:10 +0x37
exit status 2
```

So here we experienced something very dangerous, deadlock. A channel can only hold 1 value but we are just feeding it more than it can handle.

Let's try to do the same using buffered channels.

```go
func main() {
	c := make(chan string, 2)

	c <- "Hello"
	c <- "World"

	fmt.Println(<-c)
}
```

```plaintext
Hello
```

Now, we are getting a proper output as our channel is able to hold 2 values.

## Select while consuming channels

Now, let’s say a scenario is there where you are consuming values continuously and printing it out in the console. Let’s code it out and see the behaviour of the program.

```go
func main() {
	c1 := make(chan string)
	c2 := make(chan string)

	go func() {
		for {
			fastResponse(c1)
		}
	}()

	go func() {
		for {
			slowResponse(c2)
		}
	}() 
	
	for {
		fmt.Println(<-c1)
		fmt.Println(<-c2)
	}
}

func fastResponse(c chan string) {
	time.Sleep(time.Millisecond * 200)
	c <- "Response in 200ms"
}

func slowResponse(c chan string) {
	time.Sleep(time.Millisecond * 800)
	c <- "Response in 800ms"
}
```

Here I have spawned 2 go routines via anonymous functions and is continuously calling the 2 functions using for loop. In the 3rd for loop, we will print out the values and observe

```plaintext
Response in 200ms
Response in 800ms
Response in 200ms
Response in 800ms
Response in 200ms
Response in 800ms
```

There is something wrong here, the response is coming fine but shouldn’t we get the 200ms response more frequently? Let’s use Select to get the faster response more frequently.

```go
func main() {
	c1 := make(chan string)
	c2 := make(chan string)

	go func() {
		for {
			fastResponse(c1)
		}
	}()

	go func() {
		for {
			slowResponse(c2)
		}
	}() 
	
	for {
	select {

		case msg := <- c1:
			fmt.Println(msg)
		
		case msg := <- c2:
			fmt.Println(msg)
		
		}
	}
}

func fastResponse(c chan string) {
	time.Sleep(time.Millisecond * 200)
	c <- "Response in 200ms"
}

func slowResponse(c chan string) {
	time.Sleep(time.Millisecond * 800)
	c <- "Response in 800ms"
}
```

Here, we have wrapped the inner content of for loop in a select block. Whenever one of the goroutines is sending a value back, the block inside that case executes.

This yields a much better response from our functions

```plaintext
Response in 200ms
Response in 200ms
Response in 200ms
Response in 800ms
Response in 200ms
Response in 200ms
Response in 200ms
Response in 200ms
Response in 800ms
Response in 200ms
Response in 200ms
Response in 200ms
Response in 200ms
Response in 800ms
```

Now, we are getting 3 responses from `fastResponse` before getting 1 response from `slowResponse`. This a much better approach than the previous code snippet

This is the end of Part 2 of Concurrency in Go. There will probably be a part 3 as well and I will publish them after grasping the concepts.