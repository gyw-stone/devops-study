package main

import (
	"fmt"
)

func main() {
	myString := [5]string{"I","am","stupid","and","weak"}
	myString[2] = "smart"
	fmt.Println("myString %v\n",myString)
}

