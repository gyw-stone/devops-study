package main

import "fmt"

func main() {
	a := [3]int{1, 2, 3}
	fmt.Println(a)
	for i := 0; i < 3; i++ {
		fmt.Print(a[i])

	}
	for i, val := range a {
		fmt.Printf("%d\t%d\n", i, val)
	}

	// 多维数组，支持动态添加
	newPersonInfos := [...][3]string{
		{"xiaoq", "man", "on work"},
		{"aq", "woman", "on work"},
		{"stone", "woman", "left work"},
		{"aa", "man", "on work"},
	}
	for _, val := range newPersonInfos {
		fmt.Println(val)
	}

	fmt.Println("用降维方式输出: ")
	for d1, d1val := range newPersonInfos {
		for d2, d2val := range d1val {
			fmt.Println(d1, d1val, d2, "val: ", d2val)
		}
	}
}
