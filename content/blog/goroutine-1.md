---
title: "Concurrency in Go - Part 1"
description: "A simple guide to concurrency in Go using wait groups"
dateString: Oct 2022
draft: false
tags: ["Go", "Backend"]
weight: 120
cover:
    image: "/blog/goroutine-1/img_1.avif"
---

Concurrency is one of the strongest tools in Go but how to use them? Well just put the keyword `go` before a function. It can't be that easy, does it? Well, not really. Let's see some concurrency patterns in Go.

## Introduction

Let's write a simple code

```go
package main 
import "fmt"

func main() {
    count("Hello")
}

func count(str string) {
    for i := 0; i < 5; i++ {
        fmt.Println(str)
    }
}
```

On running this, we get a simple output of

```plaintext
❯ go run "d:\Code\GolangProjects\go-cocurency-test\main.go"
Hello
Hello
Hello
Hello
Hello
```

Let's follow the mentioned statement and spawn a goroutine using `go` the keyword

```go
func main() {
    go count("Hello")
}
```

In the output, we get nothing, its empty???

```plaintext
❯ go run "d:\Code\GolangProjects\go-cocurency-test\main.go"
```

Well, its because it did spawn a new thread but no one told the main thread to wait for it. Let's just add a sleep after the main function to let it wait for the goroutine to complete.

```go
func main() {
    go count("Hello")
    time.Sleep(time.Second)
}
```

Now we can see all Hello getting printed properly

```plaintext
❯ go run "d:\Code\GolangProjects\go-cocurency-test\main.go"
Hello
Hello
Hello
Hello
Hello
```

## Wait Group

Now using sleep is ok but one can't expect to know when the function will get over. What we can do is use the `Sync` package and make a wait group.

```go
func main() {
	
	// to know how much time our function take
	now := time.Now()
    defer func() {
        fmt.Println(time.Since(now))
    }()

    var wg sync.WaitGroup
    
    wg.Add(1)

    names := []string{"Achintya", "Master Chief", "Solid Snake"}

	go func() {
        for _, name := range names {
            count(name)
        }
        wg.Done()
    }()
    wg.Wait()
}

func count(str string) {
    fmt.Println("Hello from ", str)
    time.Sleep(time.Second)
}
```

Lemme explain the code a little bit

*   Defer func is a function that will execute at the end of the main function.
    
*   We will initialise a variable wg which will help us track whether the function is complete and wait for it.
    
*   `wg.Add(1)` : It actually adds a delta of 1 to the waiting group and says to wait.
    
*   After the for loop, I used them `wg.Done()` to tell the runtime that the task of this anonymous function is complete. It will decrement the delta by 1.
    
*   In the end, we have `wg.Wait()`. It will wait and keep the main function running until the value of the delta becomes 0.
    
*   Also, I have added a `time.Sleep()` count function so as to make it feel like a real-world scenario.
    

Now the output would be here as

```plaintext
❯ go run "d:\Code\GolangProjects\go-cocurency-test\main.go"
Hello from  Achintya
Hello from  Master Chief
Hello from  Solid Snake
3.0329866s
```

And our code is working fine but we are just spawning 1 thread. How about spawning a new thread for every iteration of for loop? We gotta take advantage of goroutines. Let's change the code a little.

```go
var wg sync.WaitGroup

func main() {
    now := time.Now()

    defer func() {
        fmt.Println(time.Since(now))
    }()

    names := []string{"Achintya", "Master Chief", "Solid Snake"}

    for _, name := range names {
        wg.Add(1)
        go count(name)
    }
    
    wg.Wait()
}

func count(str string) {
    fmt.Println("Hello from ", str)
    time.Sleep(time.Second)
    
    defer func ()  {
        wg.Done()
    }()
}
```

Here we made a new goroutine in each iteration of for loop. I have added `wg.Add(1)` and then completed the `wg.Done()` in the function call using defer. Now even if all the function is supposed to take 3 seconds, we through goroutines have completed in almost 1 second.

```plaintext
❯ go run "d:\Code\GolangProjects\go-cocurency-test\main.go"
Hello from  Solid Snake
Hello from  Achintya
Hello from  Master Chief
1.008593s
```

This will be part 1. In later parts, we will study about channels in Go.