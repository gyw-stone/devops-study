package main

import (
	"fmt"
	"reflect"
)

func main() {
	a1 := "hello"
	fmt.Println(reflect.TypeOf(a1))
	a2 := &a1
	fmt.Println(reflect.TypeOf(a2))
}
