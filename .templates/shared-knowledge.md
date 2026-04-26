---
module: <示例: status>
description: <一句话说明>
read_priority: P0|P1|P2
read_when: <何时读>
write_when: <何时写>
format: registry|log|reference
single_source_of_truth_for:
  - <信息类别1>
  - <信息类别2>
sync_with: <引用的其他权威文件>
last_reviewed: <YYYY-MM-DD>
---

# <文件标题>

> **定位**: 这个文件在项目中的角色？
> **更新频率**: 多久更新一次？谁负责？

## 核心内容区

<!-- 此区域的结构由 format 决定 -->
<!-- format=registry → 表格为主 -->
<!-- format=log → 时间戳章节为主 -->
<!-- format=reference → 说明性文字为主 -->

## 交叉引用

- 相关域: [Domain](path/to/file)
- 数据来源: 如适用
