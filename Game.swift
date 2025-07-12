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
