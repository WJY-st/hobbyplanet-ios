#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
校验 project.pbxproj 里的文件引用是否都能在磁盘上找到。

背景：Xcode 的 PBXGroup 用「父组的 path + 子组的 path」拼出真实路径。
如果生成器把 "Views/Assistant" 这种嵌套目录平铺成顶层组、只写 path = Assistant，
Xcode 会解析成 HobbyPlanet/Assistant/...，本地看不出来，但 xcodebuild 会报
"Build input files cannot be found"。这个脚本就是用来提前发现这类问题的。

用法：python tools/verify_project.py
"""

import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(HERE)
PBXPROJ = os.path.join(PROJECT_ROOT, "HobbyPlanet.xcodeproj", "project.pbxproj")

OBJECT_RE = re.compile(r"^\t\t([0-9A-F]{24})(?: /\* (.+?) \*/)? = \{\n\t\t\tisa = (\w+);(.*?)\n\t\t\};",
                       re.S | re.M)
LINE_OBJECT_RE = re.compile(r"^\t\t([0-9A-F]{24})(?: /\* (.+?) \*/)? = \{isa = (\w+);(.*?)\};$", re.M)


def parse(text):
    objects = {}
    for match in LINE_OBJECT_RE.finditer(text):
        uid, name, isa, body = match.groups()
        objects[uid] = {"isa": isa, "body": body, "name": name}
    for match in OBJECT_RE.finditer(text):
        uid, name, isa, body = match.groups()
        objects.setdefault(uid, {"isa": isa, "body": body, "name": name})

    groups = {}
    for uid, obj in objects.items():
        if obj["isa"] != "PBXGroup":
            continue
        body = obj["body"]
        children = []
        children_block = re.search(r"children = \((.*?)\);", body, re.S)
        if children_block:
            children = re.findall(r"([0-9A-F]{24})", children_block.group(1))
        path_match = re.search(r"path = ([^;]+);", body)
        path = path_match.group(1).strip().strip('"') if path_match else None
        groups[uid] = {"children": children, "path": path, "name": obj["name"]}

    files = {}
    for uid, obj in objects.items():
        if obj["isa"] != "PBXFileReference":
            continue
        body = obj["body"]
        path_match = re.search(r"path = ([^;]+);", body)
        if not path_match:
            continue
        path = path_match.group(1).strip().strip('"')
        tree_match = re.search(r"sourceTree = ([^;]+);", body)
        tree = tree_match.group(1).strip().strip('"') if tree_match else "<group>"
        files[uid] = {"path": path, "tree": tree}

    project_match = re.search(r"mainGroup = ([0-9A-F]{24});", text)
    main_group = project_match.group(1) if project_match else None
    return groups, files, main_group


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
    if not os.path.exists(PBXPROJ):
        print("找不到 project.pbxproj：%s" % PBXPROJ)
        return 1

    text = open(PBXPROJ, encoding="utf-8").read()
    groups, files, main_group = parse(text)

    resolved = []
    missing = []

    def walk(group_id, base):
        group = groups.get(group_id)
        if group is None:
            return
        current = base
        if group["path"]:
            current = os.path.join(base, group["path"]) if base else group["path"]
        for child in group["children"]:
            if child in groups:
                walk(child, current)
            elif child in files:
                info = files[child]
                if info["tree"] != "<group>":
                    continue          # 例如 BUILT_PRODUCTS_DIR 里的产物，不校验
                full = os.path.join(current, info["path"])
                resolved.append(full)
                if not os.path.exists(os.path.join(PROJECT_ROOT, full)):
                    missing.append(full)

    if main_group:
        walk(main_group, "")

    sources = re.search(r"isa = PBXSourcesBuildPhase;\n\t\t\tbuildActionMask = \d+;\n\t\t\tfiles = \((.*?)\);", text, re.S)
    source_count = len(re.findall(r"[0-9A-F]{24}", sources.group(1))) if sources else 0

    print("组数量：%d，文件引用：%d" % (len(groups), len(files)))
    print("按组路径解析出的文件：%d 个" % len(resolved))
    print("Sources 构建阶段里的文件：%d 个" % source_count)

    if missing:
        print("\n以下文件在磁盘上找不到（工程路径错了）:")
        for item in missing:
            print("  [MISSING] %s" % item)
        return 1

    print("\n[OK] 所有文件引用都能在磁盘上找到")
    return 0


if __name__ == "__main__":
    sys.exit(main())
