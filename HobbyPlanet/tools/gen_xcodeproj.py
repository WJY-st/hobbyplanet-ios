#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
生成 HobbyPlanet.xcodeproj/project.pbxproj（Xcode 15/16 的经典工程格式）。

用法：python tools/gen_xcodeproj.py <工程根目录>
默认根目录为脚本上一级目录（即 HobbyPlanet 工程目录）。

约定：
- 所有 Swift 源文件放在 HobbyPlanet/ 下，按子目录分组成 PBXGroup；
- 测试源文件放在 HobbyPlanetTests/ 下；
- 资源只有 Assets.xcassets；
- 对象 UUID 由路径的 MD5 派生，保证每次生成的工程文件稳定、可 diff。
"""

import hashlib
import os
import sys

APP = "HobbyPlanet"
TESTS = "HobbyPlanetTests"
BUNDLE_ID = "com.hobbyplanet.app"


def uid(key: str) -> str:
    return hashlib.md5(key.encode("utf-8")).hexdigest()[:24].upper()


def quote(value: str) -> str:
    """pbxproj 的字符串引号规则：包含特殊字符时需要加引号。"""
    if value == "":
        return '""'
    safe = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_$/.")
    if all(ch in safe for ch in value):
        return value
    if "\\" in value or '"' in value:
        value = value.replace("\\", "\\\\").replace('"', '\\"')
    return '"%s"' % value


class FileItem:
    def __init__(self, path, name=None):
        self.path = path                      # 相对工程根目录的路径
        self.name = name or os.path.basename(path)
        self.uuid = uid("file:" + path)
        self.build_uuid = uid("build:" + path)


def collect(groups_root):
    """返回 {group_path: [FileItem, ...]}，group_path 用 '/' 分隔。"""
    result = {}
    for current, dirs, files in os.walk(groups_root):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        rel = os.path.relpath(current, groups_root).replace("\\", "/")
        if rel == ".":
            rel = ""
        swift = sorted(f for f in files if f.endswith(".swift"))
        if not swift:
            continue
        result[rel] = [FileItem(os.path.join(current, f).replace("\\", "/")) for f in swift]
    return result


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    root = os.path.abspath(root)

    app_src = collect(os.path.join(root, APP))
    test_src = collect(os.path.join(root, TESTS))

    app_files = [f for items in app_src.values() for f in items]
    test_files = [f for items in test_src.values() for f in items]

    assets = FileItem(os.path.join(root, APP, "Assets.xcassets").replace("\\", "/"))

    project_uuid = uid("project")
    main_group_uuid = uid("group:main")
    products_group_uuid = uid("group:products")
    app_group_uuid = uid("group:app")
    tests_group_uuid = uid("group:tests")

    app_target_uuid = uid("target:app")
    tests_target_uuid = uid("target:tests")

    app_product_uuid = uid("product:app")
    tests_product_uuid = uid("product:tests")

    app_sources_phase = uid("phase:app:sources")
    app_frameworks_phase = uid("phase:app:frameworks")
    app_resources_phase = uid("phase:app:resources")

    tests_sources_phase = uid("phase:tests:sources")
    tests_frameworks_phase = uid("phase:tests:frameworks")
    tests_resources_phase = uid("phase:tests:resources")

    project_config_list = uid("config:project")
    app_config_list = uid("config:app")
    tests_config_list = uid("config:tests")

    project_debug = uid("config:project:debug")
    project_release = uid("config:project:release")
    app_debug = uid("config:app:debug")
    app_release = uid("config:app:release")
    tests_debug = uid("config:tests:debug")
    tests_release = uid("config:tests:release")

    container_proxy = uid("proxy:tests")
    target_dependency = uid("dependency:tests")

    out = []
    add = out.append

    add("// !$*UTF8*$!")
    add("{")
    add("\tarchiveVersion = 1;")
    add("\tclasses = {")
    add("\t};")
    add("\tobjectVersion = 56;")
    add("\tobjects = {")
    add("")

    # ---- PBXBuildFile ----
    add("/* Begin PBXBuildFile section */")
    for item in app_files:
        add("\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };"
            % (item.build_uuid, item.name, item.uuid, item.name))
    add("\t\t%s /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = %s /* Assets.xcassets */; };"
        % (uid("build:assets"), assets.uuid))
    for item in test_files:
        add("\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };"
            % (item.build_uuid, item.name, item.uuid, item.name))
    add("/* End PBXBuildFile section */")
    add("")

    # ---- PBXContainerItemProxy ----
    add("/* Begin PBXContainerItemProxy section */")
    add("\t\t%s /* PBXContainerItemProxy */ = {" % container_proxy)
    add("\t\t\tisa = PBXContainerItemProxy;")
    add("\t\t\tcontainerPortal = %s /* Project object */;" % project_uuid)
    add("\t\t\tproxyType = 1;")
    add("\t\t\tremoteGlobalIDString = %s;" % app_target_uuid)
    add("\t\t\tremoteInfo = %s;" % APP)
    add("\t\t};")
    add("/* End PBXContainerItemProxy section */")
    add("")

    # ---- PBXFileReference ----
    add("/* Begin PBXFileReference section */")
    add("\t\t%s /* %s.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = %s.app; sourceTree = BUILT_PRODUCTS_DIR; };"
        % (app_product_uuid, APP, APP))
    add("\t\t%s /* %s.xctest */ = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = %s.xctest; sourceTree = BUILT_PRODUCTS_DIR; };"
        % (tests_product_uuid, TESTS, TESTS))
    add("\t\t%s /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; };"
        % assets.uuid)
    for item in app_files + test_files:
        add("\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = %s; sourceTree = \"<group>\"; };"
            % (item.uuid, item.name, item.name))
    add("/* End PBXFileReference section */")
    add("")

    # ---- PBXFrameworksBuildPhase ----
    add("/* Begin PBXFrameworksBuildPhase section */")
    for phase_uuid, comment in ((app_frameworks_phase, APP), (tests_frameworks_phase, TESTS)):
        add("\t\t%s /* Frameworks */ = {" % phase_uuid)
        add("\t\t\tisa = PBXFrameworksBuildPhase;")
        add("\t\t\tbuildActionMask = 2147483647;")
        add("\t\t\tfiles = (")
        add("\t\t\t);")
        add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
        add("\t\t};")
    add("/* End PBXFrameworksBuildPhase section */")
    add("")

    # ---- PBXGroup ----
    add("/* Begin PBXGroup section */")

    add("\t\t%s = {" % main_group_uuid)
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add("\t\t\t\t%s /* %s */," % (app_group_uuid, APP))
    add("\t\t\t\t%s /* %s */," % (tests_group_uuid, TESTS))
    add("\t\t\t\t%s /* Products */," % products_group_uuid)
    add("\t\t\t);")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add("")

    add("\t\t%s /* Products */ = {" % products_group_uuid)
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    add("\t\t\t\t%s /* %s.app */," % (app_product_uuid, APP))
    add("\t\t\t\t%s /* %s.xctest */," % (tests_product_uuid, TESTS))
    add("\t\t\t);")
    add("\t\t\tname = Products;")
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add("")

    # App 组：根层文件 + 子目录组
    add("\t\t%s /* %s */ = {" % (app_group_uuid, APP))
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    top_level = app_src.get("", [])
    for item in top_level:
        add("\t\t\t\t%s /* %s */," % (item.uuid, item.name))
    subdirs = sorted(k for k in app_src.keys() if k)
    for sub in subdirs:
        add("\t\t\t\t%s /* %s */," % (uid("group:" + APP + "/" + sub), sub.replace("/", "/")))
    add("\t\t\t\t%s /* Assets.xcassets */," % assets.uuid)
    add("\t\t\t);")
    add("\t\t\tpath = %s;" % APP)
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add("")

    for sub in subdirs:
        group_uuid = uid("group:" + APP + "/" + sub)
        add("\t\t%s /* %s */ = {" % (group_uuid, sub))
        add("\t\t\tisa = PBXGroup;")
        add("\t\t\tchildren = (")
        for item in app_src[sub]:
            add("\t\t\t\t%s /* %s */," % (item.uuid, item.name))
        add("\t\t\t);")
        add("\t\t\tpath = %s;" % quote(os.path.basename(sub)))
        add("\t\t\tsourceTree = \"<group>\";")
        add("\t\t};")
        add("")

    add("\t\t%s /* %s */ = {" % (tests_group_uuid, TESTS))
    add("\t\t\tisa = PBXGroup;")
    add("\t\t\tchildren = (")
    for item in test_src.get("", []):
        add("\t\t\t\t%s /* %s */," % (item.uuid, item.name))
    add("\t\t\t);")
    add("\t\t\tpath = %s;" % TESTS)
    add("\t\t\tsourceTree = \"<group>\";")
    add("\t\t};")
    add("/* End PBXGroup section */")
    add("")

    # ---- PBXNativeTarget ----
    add("/* Begin PBXNativeTarget section */")
    add("\t\t%s /* %s */ = {" % (app_target_uuid, APP))
    add("\t\t\tisa = PBXNativeTarget;")
    add("\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"%s\" */;" % (app_config_list, APP))
    add("\t\t\tbuildPhases = (")
    add("\t\t\t\t%s /* Sources */," % app_sources_phase)
    add("\t\t\t\t%s /* Frameworks */," % app_frameworks_phase)
    add("\t\t\t\t%s /* Resources */," % app_resources_phase)
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add("\t\t\t);")
    add("\t\t\tname = %s;" % APP)
    add("\t\t\tproductName = %s;" % APP)
    add("\t\t\tproductReference = %s /* %s.app */;" % (app_product_uuid, APP))
    add("\t\t\tproductType = \"com.apple.product-type.application\";")
    add("\t\t};")
    add("")

    add("\t\t%s /* %s */ = {" % (tests_target_uuid, TESTS))
    add("\t\t\tisa = PBXNativeTarget;")
    add("\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXNativeTarget \"%s\" */;" % (tests_config_list, TESTS))
    add("\t\t\tbuildPhases = (")
    add("\t\t\t\t%s /* Sources */," % tests_sources_phase)
    add("\t\t\t\t%s /* Frameworks */," % tests_frameworks_phase)
    add("\t\t\t\t%s /* Resources */," % tests_resources_phase)
    add("\t\t\t);")
    add("\t\t\tbuildRules = (")
    add("\t\t\t);")
    add("\t\t\tdependencies = (")
    add("\t\t\t\t%s /* PBXTargetDependency */," % target_dependency)
    add("\t\t\t);")
    add("\t\t\tname = %s;" % TESTS)
    add("\t\t\tproductName = %s;" % TESTS)
    add("\t\t\tproductReference = %s /* %s.xctest */;" % (tests_product_uuid, TESTS))
    add("\t\t\tproductType = \"com.apple.product-type.bundle.unit-test\";")
    add("\t\t};")
    add("/* End PBXNativeTarget section */")
    add("")

    # ---- PBXProject ----
    add("/* Begin PBXProject section */")
    add("\t\t%s /* Project object */ = {" % project_uuid)
    add("\t\t\tisa = PBXProject;")
    add("\t\t\tattributes = {")
    add("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    add("\t\t\t\tLastSwiftUpdateCheck = 1620;")
    add("\t\t\t\tLastUpgradeCheck = 1620;")
    add("\t\t\t\tTargetAttributes = {")
    add("\t\t\t\t\t%s = {" % app_target_uuid)
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;")
    add("\t\t\t\t\t};")
    add("\t\t\t\t\t%s = {" % tests_target_uuid)
    add("\t\t\t\t\t\tCreatedOnToolsVersion = 16.2;")
    add("\t\t\t\t\t\tTestTargetID = %s;" % app_target_uuid)
    add("\t\t\t\t\t};")
    add("\t\t\t\t};")
    add("\t\t\t};")
    add("\t\t\tbuildConfigurationList = %s /* Build configuration list for PBXProject \"%s\" */;" % (project_config_list, APP))
    add("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    add("\t\t\tdevelopmentRegion = \"zh-Hans\";")
    add("\t\t\thasScannedForEncodings = 0;")
    add("\t\t\tknownRegions = (")
    add("\t\t\t\t\"zh-Hans\",")
    add("\t\t\t\ten,")
    add("\t\t\t\tBase,")
    add("\t\t\t);")
    add("\t\t\tmainGroup = %s;" % main_group_uuid)
    add("\t\t\tproductRefGroup = %s /* Products */;" % products_group_uuid)
    add("\t\t\tprojectDirPath = \"\";")
    add("\t\t\tprojectRoot = \"\";")
    add("\t\t\ttargets = (")
    add("\t\t\t\t%s /* %s */," % (app_target_uuid, APP))
    add("\t\t\t\t%s /* %s */," % (tests_target_uuid, TESTS))
    add("\t\t\t);")
    add("\t\t};")
    add("/* End PBXProject section */")
    add("")

    # ---- PBXResourcesBuildPhase ----
    add("/* Begin PBXResourcesBuildPhase section */")
    add("\t\t%s /* Resources */ = {" % app_resources_phase)
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t\t%s /* Assets.xcassets in Resources */," % uid("build:assets"))
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("")
    add("\t\t%s /* Resources */ = {" % tests_resources_phase)
    add("\t\t\tisa = PBXResourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXResourcesBuildPhase section */")
    add("")

    # ---- PBXSourcesBuildPhase ----
    add("/* Begin PBXSourcesBuildPhase section */")
    add("\t\t%s /* Sources */ = {" % app_sources_phase)
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for item in app_files:
        add("\t\t\t\t%s /* %s in Sources */," % (item.build_uuid, item.name))
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("")
    add("\t\t%s /* Sources */ = {" % tests_sources_phase)
    add("\t\t\tisa = PBXSourcesBuildPhase;")
    add("\t\t\tbuildActionMask = 2147483647;")
    add("\t\t\tfiles = (")
    for item in test_files:
        add("\t\t\t\t%s /* %s in Sources */," % (item.build_uuid, item.name))
    add("\t\t\t);")
    add("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    add("\t\t};")
    add("/* End PBXSourcesBuildPhase section */")
    add("")

    # ---- PBXTargetDependency ----
    add("/* Begin PBXTargetDependency section */")
    add("\t\t%s /* PBXTargetDependency */ = {" % target_dependency)
    add("\t\t\tisa = PBXTargetDependency;")
    add("\t\t\ttarget = %s /* %s */;" % (app_target_uuid, APP))
    add("\t\t\ttargetProxy = %s /* PBXContainerItemProxy */;" % container_proxy)
    add("\t\t};")
    add("/* End PBXTargetDependency section */")
    add("")

    # ---- XCBuildConfiguration ----
    add("/* Begin XCBuildConfiguration section */")

    def project_config(uuid_value, name, extra):
        add("\t\t%s /* %s */ = {" % (uuid_value, name))
        add("\t\t\tisa = XCBuildConfiguration;")
        add("\t\t\tbuildSettings = {")
        for key, value in extra:
            add("\t\t\t\t%s = %s;" % (key, value))
        add("\t\t\t};")
        add("\t\t\tname = %s;" % name)
        add("\t\t};")
        add("")

    project_common = [
        ("ALWAYS_SEARCH_USER_PATHS", "NO"),
        ("ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS", "YES"),
        ("CLANG_ANALYZER_NONNULL", "YES"),
        ("CLANG_ENABLE_MODULES", "YES"),
        ("CLANG_ENABLE_OBJC_ARC", "YES"),
        ("CLANG_WARN_BOOL_CONVERSION", "YES"),
        ("CLANG_WARN_DOCUMENTATION_COMMENTS", "YES"),
        ("COPY_PHASE_STRIP", "NO"),
        ("ENABLE_STRICT_OBJC_MSGSEND", "YES"),
        ("GCC_C_LANGUAGE_STANDARD", "gnu17"),
        ("GCC_NO_COMMON_BLOCKS", "YES"),
        ("IPHONEOS_DEPLOYMENT_TARGET", "16.0"),
        ("LOCALIZATION_PREFERS_STRING_CATALOGS", "YES"),
        ("MTL_FAST_MATH", "YES"),
        ("SDKROOT", "iphoneos"),
        ("SWIFT_EMIT_LOC_STRINGS", "YES"),
    ]

    project_config(project_debug, "Debug", project_common + [
        ("DEBUG_INFORMATION_FORMAT", "dwarf"),
        ("ENABLE_TESTABILITY", "YES"),
        ("GCC_DYNAMIC_NO_PIC", "NO"),
        ("GCC_OPTIMIZATION_LEVEL", "0"),
        ("GCC_PREPROCESSOR_DEFINITIONS", '(\n\t\t\t\t\t"DEBUG=1",\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t)'),
        ("MTL_ENABLE_DEBUG_INFO", "INCLUDE_SOURCE"),
        ("ONLY_ACTIVE_ARCH", "YES"),
        ("SWIFT_ACTIVE_COMPILATION_CONDITIONS", '"DEBUG $(inherited)"'),
        ("SWIFT_OPTIMIZATION_LEVEL", '"-Onone"'),
    ])

    project_config(project_release, "Release", project_common + [
        ("DEBUG_INFORMATION_FORMAT", '"dwarf-with-dsym"'),
        ("ENABLE_NS_ASSERTIONS", "NO"),
        ("MTL_ENABLE_DEBUG_INFO", "NO"),
        ("SWIFT_COMPILATION_MODE", "wholemodule"),
        ("VALIDATE_PRODUCT", "YES"),
    ])

    app_common = [
        ("ASSETCATALOG_COMPILER_APPICON_NAME", "AppIcon"),
        ("ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME", "AccentColor"),
        ("CODE_SIGN_STYLE", "Automatic"),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("ENABLE_PREVIEWS", "YES"),
        ("GENERATE_INFOPLIST_FILE", "YES"),
        ("INFOPLIST_KEY_CFBundleDisplayName", quote("同好星球")),
        ("INFOPLIST_KEY_LSApplicationCategoryType", quote("public.app-category.social-networking")),
        ("INFOPLIST_KEY_UIApplicationSceneManifest_Generation", "YES"),
        ("INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents", "YES"),
        ("INFOPLIST_KEY_UILaunchScreen_Generation", "YES"),
        ("INFOPLIST_KEY_UIStatusBarStyle", "UIStatusBarStyleDefault"),
        ("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad",
         quote("UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight")),
        ("INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone", quote("UIInterfaceOrientationPortrait")),
        ("LD_RUNPATH_SEARCH_PATHS", '(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t)'),
        ("MARKETING_VERSION", "1.0"),
        ("PRODUCT_BUNDLE_IDENTIFIER", BUNDLE_ID),
        ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
        ("SWIFT_EMIT_LOC_STRINGS", "YES"),
        ("SWIFT_VERSION", "5.0"),
        ("TARGETED_DEVICE_FAMILY", '"1,2"'),
    ]

    project_config(app_debug, "Debug", app_common)
    project_config(app_release, "Release", app_common)

    tests_common = [
        ("BUNDLE_LOADER", '"$(TEST_HOST)"'),
        ("CODE_SIGN_STYLE", "Automatic"),
        ("CURRENT_PROJECT_VERSION", "1"),
        ("GENERATE_INFOPLIST_FILE", "YES"),
        ("LD_RUNPATH_SEARCH_PATHS", '(\n\t\t\t\t\t"$(inherited)",\n\t\t\t\t\t"@executable_path/Frameworks",\n\t\t\t\t\t"@loader_path/Frameworks",\n\t\t\t\t)'),
        ("MARKETING_VERSION", "1.0"),
        ("PRODUCT_BUNDLE_IDENTIFIER", BUNDLE_ID + ".tests"),
        ("PRODUCT_NAME", '"$(TARGET_NAME)"'),
        ("SWIFT_EMIT_LOC_STRINGS", "NO"),
        ("SWIFT_VERSION", "5.0"),
        ("TARGETED_DEVICE_FAMILY", '"1,2"'),
        ("TEST_HOST", '"$(BUILT_PRODUCTS_DIR)/HobbyPlanet.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/HobbyPlanet"'),
    ]

    project_config(tests_debug, "Debug", tests_common)
    project_config(tests_release, "Release", tests_common)

    add("/* End XCBuildConfiguration section */")
    add("")

    # ---- XCConfigurationList ----
    add("/* Begin XCConfigurationList section */")
    for list_uuid, label, debug_uuid, release_uuid in (
        (project_config_list, "PBXProject \"%s\"" % APP, project_debug, project_release),
        (app_config_list, "PBXNativeTarget \"%s\"" % APP, app_debug, app_release),
        (tests_config_list, "PBXNativeTarget \"%s\"" % TESTS, tests_debug, tests_release),
    ):
        add("\t\t%s /* Build configuration list for %s */ = {" % (list_uuid, label))
        add("\t\t\tisa = XCConfigurationList;")
        add("\t\t\tbuildConfigurations = (")
        add("\t\t\t\t%s /* Debug */," % debug_uuid)
        add("\t\t\t\t%s /* Release */," % release_uuid)
        add("\t\t\t);")
        add("\t\t\tdefaultConfigurationIsVisible = 0;")
        add("\t\t\tdefaultConfigurationName = Release;")
        add("\t\t};")
        add("")
    add("/* End XCConfigurationList section */")

    add("\t};")
    add("\trootObject = %s /* Project object */;" % project_uuid)
    add("}")

    target = os.path.join(root, APP + ".xcodeproj")
    os.makedirs(target, exist_ok=True)
    pbxproj = os.path.join(target, "project.pbxproj")
    with open(pbxproj, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")

    # 共享 scheme，保证 clone 下来就能直接 Run
    scheme_dir = os.path.join(target, "xcshareddata", "xcschemes")
    os.makedirs(scheme_dir, exist_ok=True)
    with open(os.path.join(scheme_dir, APP + ".xcscheme"), "w", encoding="utf-8", newline="\n") as handle:
        handle.write(scheme_xml(app_target_uuid, tests_target_uuid, project_uuid))

    print("生成完成: %s" % pbxproj)
    print("Swift 文件: %d 个（App） + %d 个（Tests）" % (len(app_files), len(test_files)))


def scheme_xml(app_target, tests_target, project_uuid):
    return """<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1620"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "%(app)s"
               BuildableName = "HobbyPlanet.app"
               BlueprintName = "HobbyPlanet"
               ReferencedContainer = "container:HobbyPlanet.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "%(tests)s"
               BuildableName = "HobbyPlanetTests.xctest"
               BlueprintName = "HobbyPlanetTests"
               ReferencedContainer = "container:HobbyPlanet.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "%(app)s"
            BuildableName = "HobbyPlanet.app"
            BlueprintName = "HobbyPlanet"
            ReferencedContainer = "container:HobbyPlanet.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "%(app)s"
            BuildableName = "HobbyPlanet.app"
            BlueprintName = "HobbyPlanet"
            ReferencedContainer = "container:HobbyPlanet.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
""" % {"app": app_target, "tests": tests_target}


if __name__ == "__main__":
    main()
