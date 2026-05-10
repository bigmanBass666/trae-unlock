package main

import (
	"fmt"
	"os"
)

func osGetEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("usage: local-stream-adapter <module>")
		fmt.Println("  module1 - LevelDB state reader")
		fmt.Println("  module2 - Chrome TLS HTTP client demo")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "module1":
		runModule1()
	case "module2":
		runModule2()
	case "server":
		runModule3()
	default:
		fmt.Fprintf(os.Stderr, "unknown module: %s\n", os.Args[1])
		os.Exit(1)
	}
}
