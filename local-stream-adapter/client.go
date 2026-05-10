package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"time"

	utls "github.com/refraction-networking/utls"
)

// NewChromeClient 创建一个模拟 Chrome 浏览器 TLS 指纹的 HTTP Client。
// 使用 utls.HelloChrome_Auto 进行 TLS 握手，以通过内网 WAF 设备检测。
func NewChromeClient() *http.Client {
	transport := &http.Transport{
		DialTLSContext: func(ctx context.Context, network, addr string) (net.Conn, error) {
			return dialTLSWithUTLS(ctx, network, addr, &utls.HelloChrome_Auto)
		},
		// 标准 HTTP/1.1 传输配置
		MaxIdleConns:        100,
		IdleConnTimeout:     90 * time.Second,
		TLSHandshakeTimeout: 15 * time.Second,
		// 禁用 HTTP/2 以确保指纹一致性
		ForceAttemptHTTP2: false,
	}

	return &http.Client{
		Transport: transport,
		Timeout:   30 * time.Second,
	}
}

// dialTLSWithUTLS 使用 utls 建立带有自定义 ClientHello 指纹的 TLS 连接。
func dialTLSWithUTLS(ctx context.Context, network, addr string, helloID *utls.ClientHelloID) (net.Conn, error) {
	dialer := &net.Dialer{
		Timeout:   15 * time.Second,
		KeepAlive: 30 * time.Second,
	}

	conn, err := dialer.DialContext(ctx, network, addr)
	if err != nil {
		return nil, fmt.Errorf("dial failed: %w", err)
	}

	host, _, err := net.SplitHostPort(addr)
	if err != nil {
		conn.Close()
		return nil, fmt.Errorf("split host port failed: %w", err)
	}

	tlsConn := utls.UClient(conn, &utls.Config{
		ServerName:         host,
		InsecureSkipVerify: false,
		MinVersion:         tls.VersionTLS12,
	}, *helloID)

	if err := tlsConn.HandshakeContext(ctx); err != nil {
		conn.Close()
		return nil, fmt.Errorf("utls handshake failed: %w", err)
	}

	return tlsConn, nil
}

// DoRequest 使用指定的 HTTP Client 向目标 URL 发起 GET 请求，
// 并附加自定义 Header。返回响应体字符串。
func DoRequest(client *http.Client, targetURL string, headers map[string]string) (string, error) {
	req, err := http.NewRequest("GET", targetURL, nil)
	if err != nil {
		return "", fmt.Errorf("create request failed: %w", err)
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response body failed: %w", err)
	}

	return string(body), nil
}

// DoPostRequest 使用指定的 HTTP Client 向目标 URL 发起 POST 请求，
// 并附加自定义 Header。用于后续 SSE 模块与上游通信。
func DoPostRequest(client *http.Client, targetURL string, headers map[string]string, body io.Reader) (*http.Response, error) {
	req, err := http.NewRequest("POST", targetURL, body)
	if err != nil {
		return nil, fmt.Errorf("create request failed: %w", err)
	}

	for k, v := range headers {
		req.Header.Set(k, v)
	}

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}

	return resp, nil
}

// runModule2 是模块2的入口，演示 Chrome Client 的使用。
func runModule2() {
	client := NewChromeClient()

	targetURL := osGetEnv("TARGET_URL", "https://api.internal.com/v1/stream")

	headers := map[string]string{
		"Accept":          "text/event-stream",
		"Cache-Control":   "no-cache",
		"Connection":      "keep-alive",
		"X-Client-Type":   "local-adapter",
	}

	parsed, err := url.Parse(targetURL)
	if err != nil {
		fmt.Fprintf(os.Stderr, "invalid URL: %v\n", err)
		return
	}
	fmt.Printf("requesting %s with chrome TLS fingerprint...\n", parsed.Host)

	result, err := DoRequest(client, targetURL, headers)
	if err != nil {
		fmt.Fprintf(os.Stderr, "request error: %v\n", err)
		return
	}

	fmt.Printf("response length: %d bytes\n", len(result))
	fmt.Println("response preview (first 500 chars):")
	if len(result) > 500 {
		fmt.Println(result[:500])
	} else {
		fmt.Println(result)
	}
}
