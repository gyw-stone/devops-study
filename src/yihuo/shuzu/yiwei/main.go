package main

import "fmt"

func main() {
	a := [...]int{1, 2, 3, 4}
	fmt.Println(a)
	for i, j := 0, 0; i < len(a)-1; i, j = i+1, j-1 {
		a[i] = a[j]
	}
	fmt.Println(a)
}
