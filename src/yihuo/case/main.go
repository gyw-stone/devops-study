package main

import (
	"fmt"
)

func main() {
	var money = 0
	var busy bool = true
	switch {
	case money >= 0 && money <= 20:
		fmt.Println("one: a")
		if busy {
			break
		}
	case money > 20 && money <= 200:
		fmt.Println("two: b")
	default:
		fmt.Println("three: c")
	}
	fmt.Println("end")
	const mod = 1
	fmt.Println(mod)
}
