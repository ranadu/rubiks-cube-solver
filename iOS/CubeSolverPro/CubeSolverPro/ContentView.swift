import SwiftUI

struct Move: Codable, Identifiable {
    var id: UUID = UUID()
    let move: String
    let hint: String
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
            VStack(spacing: 20) {
                TextField("Enter cube string...", text: $cubeString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button(action: solveCube) {
                    Text("Solve Cube")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                if loading {
                    ProgressView("Solving...")
                } else if !errorMessage.isEmpty {
                    Text("❌ \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else if !solution.isEmpty {
                    List(solution) { move in
                        VStack(alignment: .leading) {
                            Text("👉 Move: \(move.move)")
                                .font(.headline)
                            Text("💡 \(move.hint)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Cube Solver Pro")
            .padding()
        }
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

        guard let url = URL(string: "http://127.0.0.1:8000/solve") else {
            errorMessage = "Invalid server URL."
            loading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ["cube": cubeString]

        do {
            request.httpBody = try JSONEncoder().encode(payload)
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
