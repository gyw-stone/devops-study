package main

import (
	"fmt"
	"strconv"
	"sync"
	"time"
)

// 暂停标志
var bStop = false

// 模拟异常/超时等使程序停止
func makeStop() {
	time.Sleep(time.Second * 4)
	bStop = true
}

// 生产者
func producer(threadId int, wg *sync.WaitGroup, ch chan string) {
	count := 0

	//标志位为false，不断写入数据
	for !bStop {
		//模拟生产数据的耗时
		time.Sleep(time.Second * 2)
		count++
		data := strconv.Itoa(threadId) + "+++++++++" + strconv.Itoa(count)
		fmt.Println("producer:", data)
		ch <- data
	}

	wg.Done()
}

// 消费者
func consumer(wg *sync.WaitGroup, ch chan string) {

	//不断读取，直到通道关闭
	for data := range ch {
		time.Sleep(time.Second * 2)
		fmt.Println("consumer:", data)
	}

	wg.Done()
}

func main() {
	//缓存：模拟生产者完成生产，消费者未完成消费
	chanStream := make(chan string, 30)

	//生产者和消费者计数器
	wgPd := new(sync.WaitGroup)
	wgCs := new(sync.WaitGroup)

	//producer
	for i := 0; i < 3; i++ {
		wgPd.Add(1)
		go producer(i, wgPd, chanStream)
	}

	//consumer
	for j := 0; j < 2; j++ {
		wgCs.Add(1)
		go consumer(wgCs, chanStream)
	}

	go makeStop()

	wgPd.Wait()

	//生产完成，关闭通道
	close(chanStream)
	wgCs.Wait()
}
