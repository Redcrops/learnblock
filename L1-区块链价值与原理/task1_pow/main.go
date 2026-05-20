// 任务一：实践 POW —— "helloworld" + nonce，不断 SHA256，
// 直到满足 4 个 0 开头、再 5 个 0 开头，分别打印耗时。
package main

import (
	"fmt"

	"learnblock/l1-blockchain-intro/pow"
)

func main() {
	fmt.Println(`POW: SHA256("helloworld" + nonce)，十六进制哈希以 N 个 0 开头`)
	fmt.Println()

	n, hash, d := pow.Mine("helloworld", 4)
	fmt.Printf("4 个 0 开头: nonce=%d\n", n)
	fmt.Printf("  hash: %s\n", hash)
	fmt.Printf("  耗时: %v\n", d)
	fmt.Println()

	n, hash, d = pow.Mine("helloworld", 5)
	fmt.Printf("5 个 0 开头: nonce=%d\n", n)
	fmt.Printf("  hash: %s\n", hash)
	fmt.Printf("  耗时: %v\n", d)
}
