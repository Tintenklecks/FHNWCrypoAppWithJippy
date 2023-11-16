// Created 09.11.2023 

import SwiftUI

// Models
struct Coin: Decodable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let current_price: Double
}

import Foundation

// Networking
protocol NetworkServiceProtocol {
    func fetchCoins() async throws -> [Coin]
}

class NetworkService: NetworkServiceProtocol {
    func fetchCoins() async throws -> [Coin] {
        guard let url = URL(string: Endpoints.coinsMarkets.rawValue) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let coins = try JSONDecoder().decode([Coin].self, from: data)
        return coins
    }
}

// ViewModel using the async method
class CoinListViewModel: ObservableObject {
    @Published var coins: [Coin] = []

    private let service: NetworkServiceProtocol

    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
        Task {
            await loadData()
        }
    }

    func loadData() async {
        do {
            let coins = try await service.fetchCoins()
            DispatchQueue.main.async {
                self.coins = coins
            }
        } catch {
            // Handle error
            print(error.localizedDescription)
        }
    }

    func refreshData() async {
        await loadData()
    }
}

// Views
struct CoinListView: View {
    @StateObject var viewModel = CoinListViewModel()

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.coins) { coin in
                    CoinRowView(coin: coin)
                    
                    
                    
                    
                        .onTapGesture {
                            // Handle tap to show CoinDetailView
                        }
                }
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

struct CoinRowView: View {
    let coin: Coin

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: coin.image)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 50, height: 50)
            .cornerRadius(25)

            VStack(alignment: .leading) {
                Text(coin.name)
                    .font(.headline)
                    .bold()
                Text(coin.symbol.uppercased())
                    .font(.subheadline)
                    .bold()
            }

            Spacer()

            Text("\(coin.current_price, format: .currency(code: "USD"))")
                .font(.headline)
                .bold()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding()
    }
}

struct CoinDetailView: View {
    let coin: Coin

    var body: some View {
        VStack {
            AsyncImage(url: URL(string: coin.image)) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 100, height: 100)
            .cornerRadius(50)
            .padding()

            Text(coin.name)
                .font(.title)
                .bold()

            Text(coin.symbol.uppercased())
                .font(.title2)
                .bold()
                .foregroundColor(.gray)
                .padding(.bottom)

            Text("\(coin.current_price, format: .currency(code: "USD"))")
                .font(.largeTitle)
                .bold()

            Spacer() // Use Spacer to push all content to the top
        }
        .padding()
        .navigationTitle("Coin Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

class MockNetworkService: NetworkServiceProtocol {
    func fetchCoins() async throws -> [Coin] {
        // Simulate a network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // Delays for 1 second

        // Return mock data
        return [
            Coin(id: "bitcoin", symbol: "btc", name: "Bitcoin", image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png?1547033579", current_price: 20000.00),
            Coin(id: "ethereum", symbol: "eth", name: "Ethereum", image: "https://assets.coingecko.com/coins/images/279/large/ethereum.png?1595348880", current_price: 1500.00),
            // Add more mock coins as needed
        ]
    }
}




// Enums and Extensions
enum Endpoints: String {
    case coinsMarkets = "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=100&page=1&sparkline=true&price_change_percentage=24h,1h"
}

// Use this enum to construct URLs and parameters for network calls

