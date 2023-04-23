package main

import "fmt"

func main() {
	var totalFatRate float64
	name := [3]string{}
	sex := [3]string{}
	height := [3]float64{}
	weight := [3]float64{}
	age := [3]int{}
	bmis := [3]float64{}
	fateRate := [3]float64{}
	for i := 0; i < 3; i++ {
		//var name string
		fmt.Print("姓名: ")
		fmt.Scanln(&name[i])

		//var weight float64
		fmt.Print("体重(kg): ")
		fmt.Scanln(&weight[i])

		//var height float64
		fmt.Print("身高(m): ")
		fmt.Scanln(&height[i])

		//var age = 30
		fmt.Print("年龄: ")
		fmt.Scanln(&age[i])

		//var sex string
		fmt.Print("性别(男/女):")
		fmt.Scanln(&sex[i])

		var sexWeight int
		bmis[i] = weight[i] / (height[i] * height[i])
		if sex[i] == "男" {
			sexWeight = 1
		} else {
			sexWeight = 0
		}
		fateRate[i] = (1.2*bmis[i] + 0.23*float64(age[i]) - 5.4 - 10.8*float64(sexWeight)) / 100
		fmt.Printf("fateRate is:%.2f", fateRate)

		if sex[i] == "男" {
			//编写男性的体脂率与体脂状态表
			if age[i] >= 18 && age[i] <= 39 {
				if fateRate[i] <= 0.1 {
					fmt.Println("结果是：偏瘦")
				} else if fateRate[i] > 0.1 && fateRate[i] <= 0.16 {
					fmt.Println("结果是: Normal")
				} else if fateRate[i] > 0.16 && fateRate[i] <= 0.21 {
					fmt.Println("结果是: little fat")
				} else {
					fmt.Println("结果是: fat")
				}
			} else if age[i] >= 40 && age[i] <= 59 {
				//todo
			} else if age[i] >= 60 {
				//todo
			} else {
				fmt.Println("未成年人暂不提供计算")
			}
		} else {
			//todo 编写woman性的体脂率与体脂状态表
		}
		/*
			var whetherContinue string
			fmt.Print("是否继续录入(y/n)?")
			fmt.Scanln(&whetherContinue)
			if whetherContinue != "y" {
				break
			}
		*/
	}
	for i := 0; i < 3; i++ {
		totalFatRate += fateRate[i]
		fmt.Println("姓名: %s,体脂率: %s,状态: %s", name[i], bmis[i], fateRate[i])
	}
	fmt.Println(totalFatRate / 3)

}
