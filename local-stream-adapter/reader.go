package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/syndtr/goleveldb/leveldb"
	"github.com/syndtr/goleveldb/leveldb/util"
)

// CopyDir 将源目录递归复制到目标目录，用于绕过 LevelDB 文件锁。
// 当数据库被其他进程占用时，先复制到临时目录再读取。
func CopyDir(src, dst string) error {
	info, err := os.Stat(src)
	if err != nil {
		return fmt.Errorf("source dir stat failed: %w", err)
	}
	if err := os.MkdirAll(dst, info.Mode()); err != nil {
		return fmt.Errorf("create dst dir failed: %w", err)
	}

	entries, err := os.ReadDir(src)
	if err != nil {
		return fmt.Errorf("read source dir failed: %w", err)
	}

	for _, entry := range entries {
		srcPath := filepath.Join(src, entry.Name())
		dstPath := filepath.Join(dst, entry.Name())

		if entry.IsDir() {
			if err := CopyDir(srcPath, dstPath); err != nil {
				return err
			}
			continue
		}

		if err := copyFile(srcPath, dstPath); err != nil {
			return fmt.Errorf("copy file %s failed: %w", srcPath, err)
		}
	}
	return nil
}

func copyFile(src, dst string) error {
	srcFile, err := os.Open(src)
	if err != nil {
		return err
	}
	defer srcFile.Close()

	dstFile, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer dstFile.Close()

	if _, err := io.Copy(dstFile, srcFile); err != nil {
		return err
	}

	srcInfo, err := os.Stat(src)
	if err != nil {
		return err
	}
	return os.Chmod(dst, srcInfo.Mode())
}

// KV 表示一个从 LevelDB 中读取的键值对。
type KV struct {
	Key   string
	Value string
}

// ExtractKeys 从指定路径的 LevelDB 中读取匹配任一前缀的键值对。
// 如果 useTemp 为 true，则先将数据库复制到临时目录再读取，以避免文件锁冲突。
func ExtractKeys(dbPath string, prefixes []string, useTemp bool) ([]KV, error) {
	readPath := dbPath

	if useTemp {
		tmpDir, err := os.MkdirTemp("", "leveldb-read-*")
		if err != nil {
			return nil, fmt.Errorf("create temp dir failed: %w", err)
		}
		defer os.RemoveAll(tmpDir)

		if err := CopyDir(dbPath, tmpDir); err != nil {
			return nil, fmt.Errorf("copy db to temp failed: %w", err)
		}
		readPath = tmpDir
	}

	db, err := leveldb.OpenFile(readPath, nil)
	if err != nil {
		return nil, fmt.Errorf("open leveldb failed: %w", err)
	}
	defer db.Close()

	var results []KV

	for _, prefix := range prefixes {
		iter := db.NewIterator(&util.Range{Start: []byte(prefix), Limit: []byte(prefix + "\xff")}, nil)
		for iter.Next() {
			results = append(results, KV{
				Key:   string(iter.Key()),
				Value: string(iter.Value()),
			})
		}
		if err := iter.Error(); err != nil {
			iter.Release()
			return nil, fmt.Errorf("iterate prefix %q failed: %w", prefix, err)
		}
		iter.Release()
	}

	return results, nil
}

// PrintResults 将提取的键值对格式化输出到标准输出。
func PrintResults(results []KV) {
	for _, kv := range results {
		fmt.Printf("%s = %s\n", kv.Key, kv.Value)
	}
	if len(results) == 0 {
		fmt.Println("no matching keys found")
	}
}

// runModule1 是模块1的入口，供 main 调用。
func runModule1() {
	dbPath := os.Getenv("LEVELDB_PATH")
	if dbPath == "" {
		homeDir, _ := os.UserHomeDir()
		dbPath = filepath.Join(homeDir, ".config", "MyApp", "Local Storage", "leveldb")
	}

	prefixStr := os.Getenv("LEVELDB_PREFIX")
	if prefixStr == "" {
		prefixStr = "auth_,session_"
	}
	prefixes := strings.Split(prefixStr, ",")

	useTemp := os.Getenv("LEVELDB_USE_TEMP") != "false"

	fmt.Printf("reading LevelDB from: %s\n", dbPath)
	fmt.Printf("prefixes: %v\n", prefixes)
	fmt.Printf("use temp copy: %v\n", useTemp)

	results, err := ExtractKeys(dbPath, prefixes, useTemp)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	PrintResults(results)
}
