import UIKit

class PackageViewController: UIViewController {
    
    static var capturedPokemons: [Pokemon] = []
    private static var hasLoadedInitialPokemon = false
    private var filteredPokemons: [Pokemon] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(PokemonTableViewCell.self, forCellReuseIdentifier: "PokemonCell")
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.showsVerticalScrollIndicator = false
        return table
    }()
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.image = UIImage(named: "pokemon_background")
        imageView.alpha = 0.1
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "My Pokemon"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private var isSearching: Bool {
        return searchController.isActive && !(searchController.searchBar.text?.isEmpty ?? true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loadInitialPokemon()
    }
    
    private func setupUI() {
        // 添加背景图片
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 添加标题
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // 设置搜索控制器
        setupSearchController()
        
        // 设置表格视图
        setupTableView()
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Pokemon"
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .systemBlue
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 100
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func loadInitialPokemon() {
        // 如果已经加载过初始宝可梦，直接返回
        if PackageViewController.hasLoadedInitialPokemon {
            return
        }
        
        // 获取初始三只宝可梦
        let initialPokemons = ["blastoise", "charizard", "ivysaur"]
        
        for pokemonName in initialPokemons {
            guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemonName)") else { continue }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, error == nil else { return }
                
                do {
                    let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                    DispatchQueue.main.async {
                        PackageViewController.capturedPokemons.append(pokemon)
                        self?.tableView.reloadData()
                    }
                } catch {
                    print("Error decoding Pokemon: \(error)")
                }
            }.resume()
        }
        
        // 标记已经加载过初始宝可梦
        PackageViewController.hasLoadedInitialPokemon = true
    }
    
    func addCapturedPokemon(_ pokemon: Pokemon) {
        PackageViewController.capturedPokemons.append(pokemon)
        tableView.reloadData()
    }
}

extension PackageViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredPokemons.count : PackageViewController.capturedPokemons.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PokemonCell", for: indexPath) as! PokemonTableViewCell
        let pokemon = isSearching ? filteredPokemons[indexPath.row] : PackageViewController.capturedPokemons[indexPath.row]
        
        cell.configure(with: pokemon) { [weak self] in
            // 检查是否只剩最后一只宝可梦
            if (self?.isSearching == true ? self?.filteredPokemons.count : PackageViewController.capturedPokemons.count) ?? 0 <= 1 {
                let alert = UIAlertController(
                    title: "Cannot Delete",
                    message: "You cannot delete the last Pokemon",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
                return
            }
            
            let alert = UIAlertController(
                title: "Delete Pokemon",
                message: "Are you sure to delete this pokemon?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel))
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                let pokemon = self.isSearching ? self.filteredPokemons[indexPath.row] : PackageViewController.capturedPokemons[indexPath.row]
                
                if let index = PackageViewController.capturedPokemons.firstIndex(where: { $0.name == pokemon.name }) {
                    PackageViewController.capturedPokemons.remove(at: index)
                    if self.isSearching {
                        self.filteredPokemons.remove(at: indexPath.row)
                    }
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
            
            self?.present(alert, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let pokemon = isSearching ? filteredPokemons[indexPath.row] : PackageViewController.capturedPokemons[indexPath.row]
        
        let detailVC = PokemonDetailViewController(pokemon: pokemon)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 检查是否只剩最后一只宝可梦
            if (isSearching ? filteredPokemons.count : PackageViewController.capturedPokemons.count) <= 1 {
                let alert = UIAlertController(
                    title: "Cannot Delete",
                    message: "You cannot delete the last Pokemon",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            
            let pokemon = isSearching ? filteredPokemons[indexPath.row] : PackageViewController.capturedPokemons[indexPath.row]
            
            let alert = UIAlertController(
                title: "Release Pokemon?",
                message: "Are you sure you want to release \(pokemon.name.capitalized)?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Release", style: .destructive) { [weak self] _ in
                if let index = PackageViewController.capturedPokemons.firstIndex(where: { $0.name == pokemon.name }) {
                    PackageViewController.capturedPokemons.remove(at: index)
                    if self?.isSearching == true {
                        self?.filteredPokemons.remove(at: indexPath.row)
                    }
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            })
            
            present(alert, animated: true)
        }
    }
}

extension PackageViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.lowercased() else { return }
        
        filteredPokemons = PackageViewController.capturedPokemons.filter { pokemon in
            return pokemon.name.lowercased().contains(searchText)
        }
        
        tableView.reloadData()
    }
}

class PokemonTableViewCell: UITableViewCell {
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.layer.shadowOpacity = 0.1
        return view
    }()
    
    private let pokemonImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.shadowColor = UIColor.black.cgColor
        imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        imageView.layer.shadowRadius = 4
        imageView.layer.shadowOpacity = 0.2
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "trash.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.contentVerticalAlignment = .fill
        button.contentHorizontalAlignment = .fill
        return button
    }()
    
    var deleteAction: (() -> Void)?
    
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
        containerView.addSubview(deleteButton)
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            pokemonImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            pokemonImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            pokemonImageView.widthAnchor.constraint(equalToConstant: 80),
            pokemonImageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.leadingAnchor.constraint(equalTo: pokemonImageView.trailingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 30),
            deleteButton.heightAnchor.constraint(equalToConstant: 30),
            
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: deleteButton.leadingAnchor, constant: -12)
        ])
    }
    
    @objc private func deleteButtonTapped() {
        deleteAction?()
    }
    
    func configure(with pokemon: Pokemon, deleteAction: @escaping () -> Void) {
        nameLabel.text = pokemon.name.capitalized
        self.deleteAction = deleteAction
        
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