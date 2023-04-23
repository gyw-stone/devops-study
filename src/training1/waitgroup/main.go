package main

import (
	"fmt"
	"sync"
	"time"
)

func main() {
	waitByWG()
}

func waitBySleep() {
	for i := 0; i < 100; i++ {
		go fmt.Println(i)
	}
	time.Sleep(time.Second)
}

func waitByChannel() {
	c := make(chan bool, 100)
	for i := 0; i < 100; i++ {
		go func(i int) {
			fmt.Println(i)
			c <- true
		}(i)
	}

	for i := 0; i < 100; i++ {
		<-c
	}
}

func waitByWG() {
	wg := sync.WaitGroup{}
	wg.Add(100) // 初始化定义100个线程
	for i := 0; i < 100; i++ {
		go func(i int) {
			fmt.Println(i)
			wg.Done()
		}(i)
	}
	wg.Wait() // 100个Done后才会执行
}
