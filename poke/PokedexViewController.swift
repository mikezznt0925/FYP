import UIKit

class PokedexViewController: UIViewController {
    
    private var pokemons: [Pokemon] = []
    private let tableView = UITableView()
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredPokemons: [Pokemon] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Pokemon"
        
        setupSearchController()
        setupTableView()
        fetchPokemonData()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Pokemon"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(PokemonCell.self, forCellReuseIdentifier: "PokemonCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
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
                        self?.filteredPokemons = self?.pokemons ?? []
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
        return filteredPokemons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PokemonCell", for: indexPath) as! PokemonCell
        let pokemon = filteredPokemons[indexPath.row]
        cell.configure(with: pokemon)
        return cell
    }
}

extension PokedexViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pokemon = filteredPokemons[indexPath.row]
        let detailVC = PokemonDetailViewController(pokemon: pokemon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension PokedexViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text?.lowercased(), !searchText.isEmpty {
            filteredPokemons = pokemons.filter { $0.name.lowercased().contains(searchText) }
        } else {
            filteredPokemons = pokemons
        }
        tableView.reloadData()
    }
}

class PokemonCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let pokemonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(pokemonImageView)
        containerView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            pokemonImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            pokemonImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            pokemonImageView.widthAnchor.constraint(equalToConstant: 50),
            pokemonImageView.heightAnchor.constraint(equalToConstant: 50),
            
            nameLabel.leadingAnchor.constraint(equalTo: pokemonImageView.trailingAnchor, constant: 16),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with pokemon: Pokemon) {
        nameLabel.text = pokemon.name.capitalized
        
        if let url = URL(string: pokemon.sprites.frontDefault) {
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, error == nil else { return }
                DispatchQueue.main.async {
                    self?.pokemonImageView.image = UIImage(data: data)
                }
            }.resume()
        }
    }
} 