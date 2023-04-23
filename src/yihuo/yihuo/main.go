package main

import (
	"fmt"
)

func main() {
	arr := []int{4, 3, 2, 1, 2, 5, 6, 3, 7, 4, 6}
	result := -1
	for _, item := range arr {
		if result < 0 {
			result = item
		} else {
			result = result ^ item
		}

	}
	fmt.Println(result)
}
