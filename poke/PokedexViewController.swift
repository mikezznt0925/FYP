import UIKit

class PokedexViewController: UIViewController {
    
    private var pokemons: [Pokemon] = []
    private let tableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = "Pokedex"
        
        setupTableView()
        fetchPokemonData()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func fetchPokemonData() {
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=20") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Network error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No data received")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    print("Found \(results.count) pokemons")
                    
                    let group = DispatchGroup()
                    var tempPokemons: [Pokemon] = []
                    
                    for result in results {
                        guard let urlString = result["url"] as? String,
                              let url = URL(string: urlString) else {
                            print("Invalid URL for pokemon")
                            continue
                        }
                        
                        group.enter()
                        self?.fetchPokemonDetail(url: url) { pokemon in
                            if let pokemon = pokemon {
                                tempPokemons.append(pokemon)
                                print("Successfully loaded pokemon: \(pokemon.name)")
                            } else {
                                print("Failed to load pokemon from \(urlString)")
                            }
                            group.leave()
                        }
                    }
                    
                    group.notify(queue: .main) {
                        self?.pokemons = tempPokemons.sorted { $0.name < $1.name }
                        print("Total pokemons loaded: \(self?.pokemons.count ?? 0)")
                        self?.tableView.reloadData()
                    }
                } else {
                    print("Failed to parse initial JSON")
                }
            } catch {
                print("JSON parsing error: \(error)")
            }
        }
        
        task.resume()
    }
    
    private func fetchPokemonDetail(url: URL, completion: @escaping (Pokemon?) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Detail network error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No detail data received")
                completion(nil)
                return
            }
            
            do {
                let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                print("Successfully decoded pokemon: \(pokemon.name)")
                print("Image URL: \(pokemon.sprites.frontDefault)")
                completion(pokemon)
            } catch {
                print("Detail decoding error: \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Received JSON: \(jsonString)")
                }
                completion(nil)
            }
        }
        
        task.resume()
    }
}

extension PokedexViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pokemons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = pokemons[indexPath.row].name.capitalized
        return cell
    }
}

extension PokedexViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pokemon = pokemons[indexPath.row]
        let detailVC = PokemonDetailViewController(pokemon: pokemon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
} 