import SwiftUI

struct Move: Codable, Identifiable, Equatable {
    var id: UUID = UUID() // Not in JSON
    let move: String
    let hint: String

    enum CodingKeys: String, CodingKey {
        case move, hint
    }

    init(move: String, hint: String) {
        self.move = move
        self.hint = hint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.move = try container.decode(String.self, forKey: .move)
        self.hint = try container.decode(String.self, forKey: .hint)
        self.id = UUID()
    }
}

struct CubeResponse: Codable {
    let solution: [Move]
}

struct ContentView: View {
    @State private var cubeString = ""
    @State private var solution: [Move] = []
    @State private var errorMessage = ""
    @State private var loading = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    inputField
                    solveButton

                    if loading {
                        ProgressView("Solving...")
                            .padding()
                    }

                    if !errorMessage.isEmpty {
                        Label(errorMessage, systemImage: "xmark.octagon.fill")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }

                    if !solution.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(solution) { move in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("👉 Move: \(move.move)")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("💡 \(move.hint)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 1)
                            }
                        }
                        .padding(.horizontal)
                        .transition(.slide)
                        .animation(.easeInOut, value: solution)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Cube Solver Pro")
        }
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enter 54-character cube string:")
                .font(.headline)
            TextField("Enter String Here", text: $cubeString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disableAutocorrection(true)
                .textInputAutocapitalization(.characters)
        }
        .padding(.horizontal)
    }

    private var solveButton: some View {
        Button(action: solveCube) {
            HStack {
                Image(systemName: "bolt.fill")
                Text("Solve Cube").bold()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(radius: 4)
        }
        .padding(.horizontal)
    }

    func solveCube() {
        guard cubeString.count == 54 else {
            errorMessage = "Cube string must be 54 characters long."
            solution = []
            return
        }

        errorMessage = ""
        loading = true
        solution = []

        guard let url = URL(string: "https://rubiks-cube-solver-xojx.onrender.com/solve") else {
            errorMessage = "Invalid server URL."
            loading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["cube": cubeString]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            errorMessage = "Failed to encode request."
            loading = false
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                loading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }

                print(String(data: data, encoding: .utf8) ?? "❌ No data or unreadable format")

                do {
                    let decoded = try JSONDecoder().decode(CubeResponse.self, from: data)
                    self.solution = decoded.solution
                } catch {
                    self.errorMessage = "Invalid response format."
                }
            }
        }.resume()
    }
}
