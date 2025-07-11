import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - API Data Models
// In a larger project, these would go into their own file, e.g., "Models.swift"

struct CreateGameResponse: Codable {
    let game_id: String
}

struct GuessRequest: Codable {
    let game_id: String
    let guess: String // Corrected from "code" to "guess"
}

struct GuessResponse: Codable {
    let black: Int
    let white: Int
}

struct ErrorResponse: Codable {
    let error: String
}


// MARK: - API Service
// In a larger project, this class would go into its own file, e.g., "APIService.swift"

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

// MARK: - Game Logic & UI
// In a larger project, this logic would go into its own file, e.g., "Game.swift"

/// Validates the player's guess.
private func isValid(guess: String) -> Bool {
    guard guess.count == 4 else { return false }
    for char in guess {
        guard let digit = Int(String(char)), (1...6).contains(digit) else {
            return false
        }
    }
    return true
}

/// Prints a user-friendly message for a given error.
private func handleError(_ error: Error) {
    print("\n--- An Error Occurred ---")
    switch error {
    case ApiError.invalidURL:
        print("Error: The API URL is invalid.")
    case ApiError.networkError(let underlyingError):
        print("Network Error: Could not connect to the server. Please check your internet connection.")
        print("Details: \(underlyingError.localizedDescription)")
    case ApiError.decodingError(let decodingError):
        print("Error: Failed to process the response from the server.")
        print("Details: \(decodingError)")
    case ApiError.apiError(let message):
        print("API Error: \(message)")
    case ApiError.invalidResponse(let statusCode, let body):
        print("Error: Received an unexpected response from the server.")
        print("Status Code: \(statusCode)")
        print("Response Body: \(body)")
    default:
        print("An unexpected error occurred: \(error.localizedDescription)")
    }
    print("-------------------------\n")
}

/// The main entry point for the game.
func runGame() async {
    let apiService = MastermindAPIService()
    var gameId: String?

    print("--- Welcome to Mastermind ---")
    print("Guess the 4-digit code. Each digit is between 1 and 6.")
    print("Type 'exit' at any time to quit the game.")
    print("-----------------------------")

    do {
        print("Starting a new game...")
        gameId = try await apiService.startNewGame()
        print("Success! A new game has started. Game ID: \(gameId!)")
    } catch {
        handleError(error)
        return
    }

    guard let currentGameId = gameId else {
        print("Error: Could not retrieve a valid game ID.")
        return
    }
    
    var attempts = 10 // The API doesn't provide this, so we'll track it locally.
    while attempts > 0 {
        print("\nEnter your 4-digit guess (Attempts remaining: \(attempts)):")
        guard let input = readLine() else { continue }

        if input.lowercased() == "exit" {
            print("Thanks for playing!")
            break
        }

        guard isValid(guess: input) else {
            print("Invalid input. Please enter exactly 4 digits, each between 1 and 6.")
            continue
        }

        do {
            let response = try await apiService.submitGuess(gameId: currentGameId, userGuess: input)
            
            print("\n--- Feedback ---")
            print("Correct value and position (B): \(response.black)")
            print("Correct value, wrong position (W): \(response.white)")
            print("----------------")

            if response.black == 4 {
                print("\n🎉 Congratulations! You guessed the code! 🎉")
                break
            }
            
            attempts -= 1
            
        } catch {
            handleError(error)
        }
    }
    
    if attempts == 0 {
        print("\nGame over! You've run out of attempts.")
    }
}

// MARK: - Main Entry Point
// This would be the content of "main.swift"

await runGame()
