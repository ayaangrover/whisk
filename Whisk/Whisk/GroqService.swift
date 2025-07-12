import Foundation

struct GroqAPIRequest: Codable {
    let model: String
    let messages: [GroqMessage]
    let temperature: Double?
    let max_tokens: Int?
    let top_p: Double?
    let stop: String?
}

struct GroqMessage: Codable {
    let role: String
    let content: String
}

struct GroqAPIResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
        let finish_reason: String?
    }
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
}


class GroqService {
    private let apiKey = "API_KEY"
    private let apiUrl = URL(string: "https://api.groq.com/openai/v1/chat/completions")!

    func fetchRecipeFromGroq(ocrText: String, completion: @escaping (Result<GroqRecipeOutput, Error>) -> Void) {
        if apiKey == "API_KEY" {
            print("ERROR: Groq API Key not set in GroqService.swift")
            completion(.failure(GroqServiceError.apiKeyMissing))
            return
        }

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let systemPrompt = """
        You are an expert recipe parser. Given raw text extracted from a recipe image,
        your task is to identify the recipe name, an optional description,
        a list of ingredients (each with a name and quantity), and a list of preparation steps.
        Return the information STRICTLY in the following JSON format:
        {
          "recipeName": "Name of the Recipe",
          "description": "Optional short description of the recipe.",
          "ingredients": [
            {"name": "Ingredient Name 1", "quantity": "Quantity 1"},
            {"name": "Ingredient Name 2", "quantity": "Quantity 2"}
          ],
          "steps": [
            "Step 1 description.",
            "Step 2 description."
          ]
        }
        If a description is not clearly identifiable, you can omit the "description" field or set it to null.
        Ensure all text values are properly escaped JSON strings. You can add more ingredients or steps as needed. Give nothing except the raw json. Don't acknowledge the request or provide any additional text AT ALL. Adjust as needed for accuracy and ensure that the text provided makes sense.
        """

        let messages = [
            GroqMessage(role: "system", content: systemPrompt),
            GroqMessage(role: "user", content: "Here is the OCR text from the recipe:\n\n\(ocrText)")
        ]
        
        let apiRequestPayload = GroqAPIRequest(
            model: "llama-3.3-70b-versatile",
            messages: messages,
            temperature: 0.2, 
            max_tokens: 2048, 
            top_p: 1.0,
            stop: nil
        )

        do {
            request.httpBody = try JSONEncoder().encode(apiRequestPayload)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(GroqServiceError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                var errorMessage = "Groq API Error: Status Code \(httpResponse.statusCode)"
                if let data = data, let errorBody = String(data: data, encoding: .utf8) {
                    errorMessage += "\nDetails: \(errorBody)"
                }
                print(errorMessage) 
                completion(.failure(GroqServiceError.apiError(message: errorMessage)))
                return
            }

            guard let data = data else {
                completion(.failure(GroqServiceError.noData))
                return
            }
            
            do {
                let groqApiResponse = try JSONDecoder().decode(GroqAPIResponse.self, from: data)
                guard let firstChoiceContent = groqApiResponse.choices.first?.message.content else {
                    completion(.failure(GroqServiceError.parsingError("Missing content in Groq response")))
                    return
                }

                if let jsonData = firstChoiceContent.data(using: .utf8) {
                    let recipeOutput = try JSONDecoder().decode(GroqRecipeOutput.self, from: jsonData)
                    completion(.success(recipeOutput))
                } else {
                    completion(.failure(GroqServiceError.parsingError("Could not convert Groq content string to Data for JSON parsing.")))
                }
                
            } catch {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Failed to parse Groq JSON. Raw string was: \(jsonString)")
                }
                completion(.failure(GroqServiceError.parsingError("Failed to decode Groq response: \(error.localizedDescription). Error: \(error)")))
            }
        }.resume()
    }

}

enum GroqServiceError: Error, LocalizedError {
    case apiKeyMissing
    case invalidResponse
    case noData
    case apiError(message: String)
    case parsingError(String) 
    case simulationError 

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Groq API Key is missing. Please set it in GroqService.swift."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .noData:
            return "No data received from the server."
        case .apiError(let message):
            return message
        case .parsingError(let details):
            return "Failed to parse data from the server: \(details)"
        case .simulationError:
            return "A simulation error occurred."
        }
    }
}

