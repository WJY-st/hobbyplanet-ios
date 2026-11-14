//
//  SeedData.swift
//  HobbyPlanet
//
//  首次启动时的示例活动。真实产品会从服务端拉取，
//  这里用本地种子数据保证“断网也能把整个流程走通”，也方便答辩时演示。
//

import Foundation

enum SeedData {
    /// 以“今天”为基准的某天某时
    static func date(offsetDays: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar.current
        let base = calendar.date(byAdding: .day, value: offsetDays, to: Date()) ?? Date()
        var components = calendar.dateComponents([.year, .month, .day], from: base)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components) ?? base
    }

    static func participants(_ names: [String]) -> [Participant] {
        names.enumerated().map { index, name in
            Participant(name: name,
                        symbol: HobbyLibrary.avatarSymbols[index % HobbyLibrary.avatarSymbols.count],
                        joinedAt: Date().addingTimeInterval(Double(-index) * 3600))
        }
    }

    static func activities() -> [HobbyActivity] {
        [
            HobbyActivity(
                title: "陶艺体验：捏一只自己的马克杯",
                summary: "校外一家小陶艺工作室，老板会手把手教拉坯和修坯。两小时做一只杯子，烧制后一周可取。零基础也能上手，做完直接拍照发朋友圈。",
                category: .handcraft,
                tags: ["陶艺", "手作", "周末"],
                startAt: date(offsetDays: 2, hour: 14),
                durationMinutes: 120,
                location: "南门 · 山丘陶艺工作室",
                capacity: 10,
                hostName: "林小满",
                coverSymbol: "scissors",
                steps: ["认识泥料与工具", "拉坯定型", "修坯与装饰", "登记烧制"],
                materials: ["围裙", "湿巾", "旧衣服"],
                participants: participants(["周禾", "陈嘉", "李一诺", "王雨桐"]),
                createdAt: Date().addingTimeInterval(-3 * 3600)
            ),
            HobbyActivity(
                title: "猫咖下午茶：带本书去撸猫",
                summary: "学校东门新开的猫咖，工作日人少。点一杯饮品就可以待一下午，店里有七只猫。适合想安静看会儿书又想有猫陪着的人。",
                category: .pet,
                tags: ["猫咖", "咖啡", "安静"],
                startAt: date(offsetDays: 1, hour: 15, minute: 30),
                durationMinutes: 90,
                location: "东门 · 三花猫咖",
                capacity: 8,
                hostName: "苏晓",
                coverSymbol: "pawprint.fill",
                steps: ["集合签到", "自由撸猫", "合照与交流"],
                materials: ["一本书", "湿巾"],
                participants: participants(["赵一", "孙萌", "何田"]),
                createdAt: Date().addingTimeInterval(-26 * 3600)
            ),
            HobbyActivity(
                title: "校园周边探店：五家小众面馆连吃",
                summary: "把校外三公里内评分高但人少的面馆串成一条线，每家只点一份招牌分着吃。边走边聊，最后投票选出一家“本学期最佳”。",
                category: .food,
                tags: ["探店", "面食", "夜宵"],
                startAt: date(offsetDays: 3, hour: 18),
                durationMinutes: 150,
                location: "西门集合 · 步行路线",
                capacity: 12,
                hostName: "黄子航",
                coverSymbol: "fork.knife",
                steps: ["西门集合", "按路线依次探店", "记录评分", "投票总结"],
                materials: ["现金零钱", "充电宝"],
                participants: participants(["吴桐", "郑好", "冯野", "许清", "邓一鸣"]),
                createdAt: Date().addingTimeInterval(-2 * 86_400)
            ),
            HobbyActivity(
                title: "话剧社开放排练：来当一次观众",
                summary: "话剧社下周公演，这次排练对外开放。可以坐在台下看完整走位，结束后有十分钟交流，想加入社团的可以直接现场报名。",
                category: .club,
                tags: ["话剧社", "社团招新", "开放日"],
                startAt: date(offsetDays: 4, hour: 19),
                durationMinutes: 120,
                location: "大学生活动中心 302",
                capacity: 30,
                hostName: "话剧社 · 沈亦",
                coverSymbol: "person.3.fill",
                steps: ["入场就座", "观看连排", "演后交流", "社团报名"],
                materials: [],
                participants: participants(["顾言", "白露", "唐果", "秦岭", "谢遥", "程一"]),
                createdAt: Date().addingTimeInterval(-5 * 86_400)
            ),
            HobbyActivity(
                title: "夜跑搭子：操场 5 公里配速 6'30\"",
                summary: "固定周四晚上的操场刷圈，配速 6 分 30 左右，跑完一起拉伸。新人可以只跑两公里，全程有人带。",
                category: .sport,
                tags: ["夜跑", "操场", "搭子"],
                startAt: date(offsetDays: 0, hour: 21),
                durationMinutes: 60,
                location: "田径场东看台下",
                capacity: 20,
                hostName: "方正",
                coverSymbol: "figure.run",
                steps: ["热身五分钟", "分组开跑", "拉伸放松"],
                materials: ["运动鞋", "水"],
                participants: participants(["孟然", "曹阳", "钱多"]),
                createdAt: Date().addingTimeInterval(-40 * 3600)
            ),
            HobbyActivity(
                title: "吉他弹唱小聚：三首歌就够了",
                summary: "会三个和弦就能加入。地点在北区草坪，带琴来最好，没琴也可以来听。曲目以民谣为主，想唱什么现场点。",
                category: .music,
                tags: ["吉他", "街唱", "草坪"],
                startAt: date(offsetDays: 2, hour: 19, minute: 30),
                durationMinutes: 100,
                location: "北区草坪 · 大榕树下",
                capacity: 15,
                hostName: "许星",
                coverSymbol: "music.note",
                steps: ["调音", "轮流弹唱", "合唱收尾"],
                materials: ["吉他", "拨片", "地垫"],
                participants: participants(["宋雨", "林岸", "夏至", "顾北"]),
                createdAt: Date().addingTimeInterval(-9 * 3600)
            ),
            HobbyActivity(
                title: "拼豆钥匙扣：做十个送给室友",
                summary: "材料费 AA，一人十块钱。图纸有现成的也可以自己画，熨烫我来。做完可以带走，多出来的放在社团当公共物资。",
                category: .handcraft,
                tags: ["拼豆", "手作", "低预算"],
                startAt: date(offsetDays: 5, hour: 16),
                durationMinutes: 90,
                location: "图书馆研讨间 A2",
                capacity: 10,
                hostName: "叶青",
                coverSymbol: "scissors",
                steps: ["分发材料", "按图纸拼豆", "熨烫定型", "装扣"],
                materials: ["拼豆", "镊子", "熨斗"],
                participants: participants(["李知", "王念"]),
                createdAt: Date().addingTimeInterval(-30 * 3600)
            ),
            HobbyActivity(
                title: "宠物救助站义工：周日半天",
                summary: "和校外救助站约好的固定义工活动，帮忙打扫、喂食、遛狗，顺便给待领养的狗拍照写文案。有车接送，名额有限。",
                category: .pet,
                tags: ["救助站", "志愿活动", "领养"],
                startAt: date(offsetDays: 6, hour: 9),
                durationMinutes: 180,
                location: "西门集合 · 车接",
                capacity: 8,
                hostName: "沈舟",
                coverSymbol: "pawprint.fill",
                steps: ["集合出发", "打扫与喂食", "遛狗", "拍照记录"],
                materials: ["旧衣服", "手套"],
                participants: participants(["宋知", "许愿", "程雨"]),
                createdAt: Date().addingTimeInterval(-6 * 86_400)
            ),
            HobbyActivity(
                title: "露天电影：带张垫子来草坪",
                summary: "投影仪 + 白床单，天黑就开场。这次放的是《海上钢琴师》，看完随便聊。自带零食，垃圾自己带走。",
                category: .club,
                tags: ["电影", "草坪", "夜"],
                startAt: date(offsetDays: 1, hour: 19, minute: 30),
                durationMinutes: 140,
                location: "南区草坪",
                capacity: 25,
                hostName: "影协 · 陆之",
                coverSymbol: "person.3.fill",
                steps: ["布置幕布", "开场", "放映", "映后闲聊"],
                materials: ["地垫", "外套"],
                participants: participants(["夏木", "江白", "路遥", "温言", "叶知", "沈青"]),
                createdAt: Date().addingTimeInterval(-12 * 3600)
            ),
            HobbyActivity(
                title: "飞盘新手局：规则十分钟讲完",
                summary: "没有基础也能来，前十分钟讲规则和手势，之后分组打。草坪有固定场地，跑动多，记得穿运动鞋。",
                category: .sport,
                tags: ["飞盘", "新手", "草坪"],
                startAt: date(offsetDays: 3, hour: 16, minute: 30),
                durationMinutes: 90,
                location: "东区草坪",
                capacity: 16,
                hostName: "贺川",
                coverSymbol: "figure.run",
                steps: ["热身", "规则讲解", "分组对抗", "合影"],
                materials: ["运动鞋", "防晒"],
                participants: participants(["齐飞", "白杨", "谷雨", "宋别"]),
                createdAt: Date().addingTimeInterval(-4 * 86_400)
            )
        ]
    }
}
