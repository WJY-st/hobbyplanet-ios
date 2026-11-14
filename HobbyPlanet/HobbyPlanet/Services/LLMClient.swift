//
//  LLMClient.swift
//  HobbyPlanet
//
//  大模型 HTTP 客户端。只做三件事：组装请求、发请求、把响应解成字符串。
//  业务侧的降级、重试、结构化解析都不放在这里，保持网络层单纯。
//

import Foundation

struct LLMClient {
    let settings: SettingsStore

    init(settings: SettingsStore) {
        self.settings = settings
    }

    /// 发送一轮对话，返回模型输出的纯文本
    func chat(messages: [LLMMessage],
              temperature: Double = 0.7,
              maxTokens: Int = 900) async throws -> String {

        guard settings.hasKey else { throw LLMError.missingKey }

        guard let url = URL(string: settings.baseURL),
              let scheme = url.scheme,
              scheme == "http" || scheme == "https" else {
            throw LLMError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(settings.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("HobbyPlanet/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        let payload = ChatRequest(model: settings.model,
                                  messages: messages,
                                  temperature: temperature,
                                  maxTokens: maxTokens)
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw LLMError.decoding
        }

        let result: (data: Data, response: URLResponse)
        do {
            result = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw LLMError.cancelled
        } catch let error as URLError where error.code == .timedOut {
            throw LLMError.network("请求超时，请检查网络后重试")
        } catch {
            throw LLMError.network(error.localizedDescription)
        }

        let data = result.data

        guard let http = result.response as? HTTPURLResponse else {
            throw LLMError.network("服务器返回了无法识别的响应")
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw LLMError.server(http.statusCode, "密钥无效或没有权限")
        case 429:
            throw LLMError.rateLimited
        default:
            let message = (try? JSONDecoder().decode(APIErrorBody.self, from: data))?
                .error?.message ?? "未知错误"
            throw LLMError.server(http.statusCode, message)
        }

        let decoded: ChatResponse
        do {
            decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            throw LLMError.decoding
        }

        guard let text = decoded.firstText, !text.isEmpty else {
            throw LLMError.emptyResponse
        }
        return text
    }
}
