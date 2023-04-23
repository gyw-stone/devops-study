package main

import (
	"fmt"
	"runtime/debug"
	calc "yihuo/calc"
)

func getMaterialsFromInput() (float64, float64, int, int, string) {
	var name string
	fmt.Print("姓名: ")
	fmt.Scanln(&name)

	var weight float64
	fmt.Print("体重(kg): ")
	fmt.Scanln(&weight)

	var sexWeight int
	sex := "男"
	fmt.Print("性别(男/女): ")
	fmt.Scanln(&sex)

	if sex == "男" {
		sexWeight = 1
	} else {
		sexWeight = 0
	}

	var height float64
	fmt.Print("身高(m): ")
	fmt.Scanln(&height)

	var age int
	fmt.Print("年龄: ")
	fmt.Scanln(&age)

	return weight, height, age, sexWeight, sex
}

func init() {
	fmt.Println("我是init函数--1")
}

func main() {
	for {
		mainFatRateBody()
		if cont := whetherContinue(); !cont {
			break
		}
	}

}

func init() {
	fmt.Println("我是init函数--2")
}

func recoverMainBody() {
	if re := recover(); re != nil {
		fmt.Println("warning: catch critical error: %v\n", re)
		debug.PrintStack()
	}
}

func mainFatRateBody() {
	defer recoverMainBody() //成功捕获
	weight, height, age, _, sex := getMaterialsFromInput()

	fatRate, err := calcFatRate(weight, height, age, sex)
	if err != nil {
		fmt.Println("warning: 计算体脂率出错,不能再继续", err)
		return
	}
	if fatRate <= 0 {
		panic("fat rate is not allowed to be negative")
	}
	var CheckHealthinessFunc func(age int, fatRate float64)
	if sex == "男" {
		CheckHealthinessFunc = getHealthinessSuggestionsForMale
	} else {
		CheckHealthinessFunc = getHealthinessSuggestionsForFeMale
	}
	getHealthinessSuggestions(age, fatRate, CheckHealthinessFunc)
}

func getHealthinessSuggestions(age int, fatRate float64, getSuggestion func(age int, fatRate float64)) {
	getSuggestion(age, fatRate)
}

func generateCheckHealthinessForMale() func(age int, fatRate float64) {
	//定制功能
	return func(age int, fatRate float64) {

	}
}

func getHealthinessSuggestionsForMale(age int, fatRate float64) {
	// 编写男性的体脂率与体脂状态码
	if age >= 18 && age <= 39 {
		if fatRate <= 0.1 {
			fmt.Println("结果是：偏瘦")
		} else if fatRate > 0.1 && fatRate <= 0.16 {
			fmt.Println("结果是: Normal")
		} else if fatRate > 0.16 && fatRate <= 0.21 {
			fmt.Println("结果是: little fat")
		} else {
			fmt.Println("结果是: fat")
		}
	} else if age >= 40 && age <= 59 {
		//todo
	} else if age >= 60 {
		//todo
	} else {
		fmt.Println("未成年人暂不提供计算")
	}
}

func getHealthinessSuggestionsForFeMale(age int, fatRate float64) {
	// 编写男性的体脂率与体脂状态码
	if age >= 18 && age <= 39 {
		if fatRate <= 0.1 {
			fmt.Println("结果是：偏瘦")
		} else if fatRate > 0.1 && fatRate <= 0.16 {
			fmt.Println("结果是: Normal")
		} else if fatRate > 0.16 && fatRate <= 0.21 {
			fmt.Println("结果是: little fat")
		} else {
			fmt.Println("结果是: fat")
		}
	} else if age >= 40 && age <= 59 {
		//todo
	} else if age >= 60 {
		//todo
	} else {
		fmt.Println("未成年人暂不提供计算")
	}
}
func calcFatRate(weight float64, height float64, age int, sex string) (fatRate float64, err error) {
	// 计算体脂率
	bmi, err := calc.CalcBMI(height, weight)
	if err != nil {
		return 0, err
	}
	fatRate = calc.CalcFatRate(bmi, age, sex)
	fmt.Println("体脂率为: ", fatRate)
	return
}

func whetherContinue() bool {
	var whetherContinue string
	fmt.Print("是否继续录入(y/n)?")
	fmt.Scanln(&whetherContinue)
	if whetherContinue != "y" {
		return false
	}
	return true

}
