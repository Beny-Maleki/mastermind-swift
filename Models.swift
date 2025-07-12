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