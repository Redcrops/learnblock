// Package pow 提供工作量证明：对 base+nonce（无分隔拼接）做 SHA256，
// 直到十六进制摘要以指定个数的前导 0 开头。
package pow

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"
	"time"
)

// Mine 对 fmt.Sprintf("%s%d", base, n) 做 SHA256，直到 hex 以 leadingZeros 个 '0' 开头。
func Mine(base string, leadingZeros int) (nonce uint64, digest string, elapsed time.Duration) {
	prefix := strings.Repeat("0", leadingZeros)
	start := time.Now()
	var n uint64
	for {
		msg := fmt.Sprintf("%s%d", base, n)
		sum := sha256.Sum256([]byte(msg))
		hx := hex.EncodeToString(sum[:])
		if strings.HasPrefix(hx, prefix) {
			return n, hx, time.Since(start)
		}
		n++
	}
}
