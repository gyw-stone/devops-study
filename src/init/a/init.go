package a

import (
	"fmt"
	_ "init/b"
)

func init() {
	fmt.Println("init from a")
}
