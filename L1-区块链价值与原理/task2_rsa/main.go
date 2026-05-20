// 任务二：实践 RSA —— 生成公私钥；对满足 POW（4 个前导 0）的「昵称+nonce」
// 用私钥签名，公钥验证。
package main

import (
	"crypto"
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"crypto/x509"
	"encoding/pem"
	"fmt"

	"learnblock/l1-blockchain-intro/pow"
)

// 与 POW 条件一致：「昵称 + nonce」为无分隔拼接，如 "Alice12345"
const nickname = "Alice"

func main() {
	// 1) 生成 RSA 公私钥（2048 位）
	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		panic(err)
	}
	pub := &priv.PublicKey

	fmt.Println("=== RSA 密钥对（PEM 预览）===")
	privPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(priv)})
	pubPEM := pem.EncodeToMemory(&pem.Block{Type: "RSA PUBLIC KEY", Bytes: x509.MarshalPKCS1PublicKey(pub)})
	fmt.Printf("私钥长度: %d 字节\n", len(privPEM))
	fmt.Printf("公钥长度: %d 字节\n\n", len(pubPEM))

	// 2) POW：找到使 SHA256(昵称+nonce) 以 4 个十六进制 0 开头的 nonce
	nonce, hashHex, powTime := pow.Mine(nickname, 4)
	message := fmt.Sprintf("%s%d", nickname, nonce)
	fmt.Println("=== POW（4 个前导 0）===")
	fmt.Printf("昵称: %q\n", nickname)
	fmt.Printf("nonce: %d\n", nonce)
	fmt.Printf("待签名的原文 message = 昵称+nonce: %q\n", message)
	fmt.Printf("SHA256(message) hex: %s\n", hashHex)
	fmt.Printf("POW 耗时: %v\n\n", powTime)

	// 3) 私钥签名：对原文 message 做 SHA-256，再 RSA-PKCS1-v1.5 签名
	msgHash := sha256.Sum256([]byte(message))
	sig, err := rsa.SignPKCS1v15(rand.Reader, priv, crypto.SHA256, msgHash[:])
	if err != nil {
		panic(err)
	}
	fmt.Printf("签名长度: %d 字节\n\n", len(sig))

	// 4) 公钥验证
	err = rsa.VerifyPKCS1v15(pub, crypto.SHA256, msgHash[:], sig)
	if err != nil {
		fmt.Println("公钥验证: 失败 —", err)
	} else {
		fmt.Println("公钥验证: 成功（签名与原文、公钥一致）")
	}

	// 演示篡改后验签失败
	tampered := message + "!"
	badHash := sha256.Sum256([]byte(tampered))
	err = rsa.VerifyPKCS1v15(pub, crypto.SHA256, badHash[:], sig)
	if err != nil {
		fmt.Println("篡改原文后验证: 失败（符合预期） —", err)
	}
}
