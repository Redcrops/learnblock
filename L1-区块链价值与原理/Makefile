# 本目录包含两个独立任务，源码分别保留在 task1_pow、task2_rsa；共享 PoW 逻辑在 pow/
# 需要已安装 Go，以及可用的 make（MinGW、Git Bash、WSL、MSYS2 等）

.PHONY: run pow rsa fmt vet clean help all

# 默认：列出帮助
.DEFAULT_GOAL := help

# 依次运行任务一、任务二（仅 PoW 或带 RSA 可分开执行）
run: all

all: pow rsa

# 任务一：helloworld + nonce，4/5 个前导 0 与耗时
pow:
	go run ./task1_pow

# 任务二：RSA + 昵称 PoW + 签名验证
rsa:
	go run ./task2_rsa

fmt:
	go fmt ./...

vet:
	go vet ./...

clean:
	go clean -cache

help:
	@echo "make pow      - 任务一：POW（helloworld，4 与 5 个前导 0）"
	@echo "make rsa      - 任务二：RSA 签名 + 昵称 POW + 验签"
	@echo "make run/all  - 先 pow 再 rsa"
	@echo "make fmt      - go fmt 整个模块"
	@echo "make vet      - go vet"
