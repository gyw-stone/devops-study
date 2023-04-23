package main

import "fmt"

func main() {
	/*
		i := 0
		for ; i < 10; i++ {
			fmt.Println("Hello Stone!")
		}
	*/
	m := 0
	for {
		m++
		if m >= 10 {
			break
		}

		if m%2 == 0 {
			fmt.Println("continue")
			continue
		}
		fmt.Println("pass:%d\n", m)
	}
}
