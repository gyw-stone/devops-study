package main

import (
	"fmt"
	"time"
)

func producer(message chan<- int) {
	for i := 0; i < 10; i++ {
		message <- i
		time.Sleep(1 * time.Second)
		fmt.Printf("producer data:%d\n", i)
	}

}

func consumer(message chan int) {
	done := make(chan bool)
	defer close(message)
	select {
	case <-done:
		fmt.Println("child process interrupt...")
		return
	default:
		for i := range message {
			fmt.Printf("get data:%d\n", i)
		}
	}
	time.Sleep(11 * time.Second)
	close(done)
}

func main() {
	message := make(chan int, 10)
	go producer(message)
	consumer(message)

}
