# Mastermind Game & API Documentation

This project is a command-line implementation of the classic code-breaking game, Mastermind. It is written in Swift and interacts with a backend API to manage the game state and validate guesses.

## Game Context: Mastermind

Mastermind is a code-breaking game where a player attempts to guess a secret code. The rules are as follows:

* The secret code consists of 4 digits.
* Each digit can be a number from 1 to 6.
* After each guess, the system provides feedback using two types of clues:
    * **Black Peg (B):** Represents a digit that is correct in both value and position.
    * **White Peg (W):** Represents a digit that is correct in value but is in the wrong position.

### Example

If the secret code is `1234`:

* A guess of `1235` would yield a response of **3B** (three black pegs), because the digits 1, 2, and 3 are correct and in their proper positions.
* A guess of `4321` would yield a response of **4W** (four white pegs), because all four digits are present in the code but are in the wrong positions.

---

## API Documentation

The API allows you to programmatically play the Mastermind game. It is a simple RESTful API with three main endpoints.

### Endpoints

#### 1. Create a New Game

Starts a new game session and returns a unique ID for that game.

* **Endpoint:** `POST /game`
* **Description:** Creates a new game instance on the server.
* **Successful Response (`200 OK`):** A JSON object containing the new game's ID.
    ```json
    {
      "game_id": "some-unique-game-id"
    }
    ```

#### 2. Make a Guess

Submits a guess for a specific game and receives feedback.

* **Endpoint:** `POST /guess`
* **Description:** Allows a player to submit a 4-digit code as a guess for an active game.
* **Request Body:** A JSON object specifying the `game_id` and the `guess` string.
    ```json
    {
      "game_id": "some-unique-game-id",
      "guess": "1234"
    }
    ```
* **Successful Response (`200 OK`):** A JSON object containing the number of black and white pegs.
    ```json
    {
      "black": 1,
      "white": 2
    }
    ```

#### 3. Delete a Game

Deletes a game session from the server.

* **Endpoint:** `DELETE /game/{gameID}`
* **Description:** Removes a game instance using its ID. This is useful for cleanup.
* **URL Parameter:**
    * `gameID` (string): The unique identifier of the game to be deleted.
* **Successful Response (`204 No Content`):** An empty response indicating the game was successfully deleted.
