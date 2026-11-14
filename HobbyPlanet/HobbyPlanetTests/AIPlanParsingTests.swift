//
//  AIPlanParsingTests.swift
//  HobbyPlanetTests
//
//  大模型返回内容的解析测试：正常 JSON、带代码围栏的 JSON、字段越界、非法文本。
//

import XCTest
@testable import HobbyPlanet

final class AIPlanParsingTests: XCTestCase {

    func testParsePlainJSON() throws {
        let raw = """
        {"title":"周五夜跑","summary":"操场刷圈，配速随意。","steps":["集合","开跑","拉伸"],"materials":["运动鞋"],"tags":["夜跑","健身"],"duration_minutes":90,"capacity":16}
        """
        let draft = try AIPlanner.parse(raw)
        XCTAssertEqual(draft.title, "周五夜跑")
        XCTAssertEqual(draft.steps.count, 3)
        XCTAssertEqual(draft.durationMinutes, 90)
        XCTAssertEqual(draft.capacity, 16)
    }

    func testParseFencedJSON() throws {
        let raw = """
        ```json
        {"title":"拼豆小聚","summary":"一起做钥匙扣。","steps":["发材料","拼豆"],"materials":[],"tags":["拼豆"],"duration_minutes":120,"capacity":10}
        ```
        """
        let draft = try AIPlanner.parse(raw)
        XCTAssertEqual(draft.title, "拼豆小聚")
    }

    func testParseClampsOutOfRangeValues() throws {
        let raw = """
        {"title":"很长的标题很长的标题很长的标题很长的标题很长的标题","summary":"x","steps":[],"materials":[],"tags":["陶艺"],"duration_minutes":900,"capacity":999}
        """
        let draft = try AIPlanner.parse(raw)
        XCTAssertLessThanOrEqual(draft.title.count, 20)
        XCTAssertEqual(draft.durationMinutes, 240)
        XCTAssertEqual(draft.capacity, 50)
        XCTAssertFalse(draft.steps.isEmpty, "步骤为空时应补默认流程")
    }

    func testParseToleratesCamelCaseKeys() throws {
        let raw = """
        {"title":"探店","summary":"吃面","steps":["出发","吃"],"materials":[],"tags":["探店"],"durationMinutes":100,"capacity":8}
        """
        let draft = try AIPlanner.parse(raw)
        XCTAssertEqual(draft.durationMinutes, 100)
    }

    func testParseRejectsGarbage() {
        XCTAssertThrowsError(try AIPlanner.parse("抱歉，我无法完成这个请求。"))
    }

    func testFallbackPlannerProducesValidDraft() {
        let draft = FallbackPlanner.draft(prompt: "想去撸猫", category: .pet)
        XCTAssertFalse(draft.title.isEmpty)
        XCTAssertFalse(draft.steps.isEmpty)
        XCTAssertTrue((30...240).contains(draft.durationMinutes))
        XCTAssertTrue((4...50).contains(draft.capacity))
    }
}
