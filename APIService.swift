import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

enum ApiError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case apiError(String)
    case invalidResponse(statusCode: Int, body: String)
}

class MastermindAPIService {
    private let baseURL = "https://mastermind.darkube.app"

    /// Starts a new game by calling the /game endpoint.
    func startNewGame() async throws -> String {
        // Corrected endpoint from "/new_game" to "/game"
        guard let url = URL(string: "\(baseURL)/game") else {
            throw ApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse(statusCode: 0, body: "Not an HTTP response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let bodyString = String(data: data, encoding: .utf8) ?? "Could not read response body"
            throw ApiError.invalidResponse(statusCode: httpResponse.statusCode, body: bodyString)
        }

        do {
            let apiResponse = try JSONDecoder().decode(CreateGameResponse.self, from: data)
            return apiResponse.game_id
        } catch {
            throw ApiError.decodingError(error)
        }
    }

    /// Submits a guess for a given game.
    func submitGuess(gameId: String, userGuess: String) async throws -> GuessResponse {
        guard let url = URL(string: "\(baseURL)/guess") else {
            throw ApiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = GuessRequest(game_id: gameId, guess: userGuess)
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApiError.invalidResponse(statusCode: 0, body: "Not an HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ApiError.apiError(errorResponse.error)
            }
            let bodyString = String(data: data, encoding: .utf8) ?? "Could not read response body"
            throw ApiError.invalidResponse(statusCode: httpResponse.statusCode, body: bodyString)
        }
        
        do {
            let apiResponse = try JSONDecoder().decode(GuessResponse.self, from: data)
            return apiResponse
        } catch {
            throw ApiError.decodingError(error)
        }
    }
}
