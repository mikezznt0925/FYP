import UIKit

class PokemonDetailViewController: UIViewController {
    
    private let pokemon: Pokemon
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private let contentView = UIView()
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 32)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statsContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let statsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(pokemon: Pokemon) {
        self.pokemon = pokemon
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = pokemon.name.capitalized
        setupUI()
        loadPokemonImage()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(containerView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(imageView)
        containerView.addSubview(statsContainer)
        statsContainer.addSubview(statsStack)
        
        nameLabel.text = pokemon.name.capitalized
        
        // 设置contentView的约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ScrollView constraints
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // ContentView constraints
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // ContainerView constraints
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // NameLabel constraints
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            nameLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            // ImageView constraints
            imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 30),
            imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            // StatsContainer constraints
            statsContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
            statsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            statsContainer.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // StatsStack constraints
            statsStack.topAnchor.constraint(equalTo: statsContainer.topAnchor, constant: 30),
            statsStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 30),
            statsStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -30),
            statsStack.bottomAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: -30)
        ])
        
        // Add basic information
        addStatLabel(title: "Height", value: "\(pokemon.height) dm")
        addStatLabel(title: "Weight", value: "\(pokemon.weight) hg")
        addStatLabel(title: "Base Experience", value: "\(pokemon.baseExperience)")
        
        // Add stats
        for stat in pokemon.stats {
            addStatLabel(title: stat.name, value: "\(stat.baseStat)")
        }
    }
    
    private func addStatLabel(title: String, value: String) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        statsStack.addArrangedSubview(container)
    }
    
    private func loadPokemonImage() {
        guard let url = URL(string: pokemon.sprites.frontDefault) else {
            print("Invalid image URL: \(pokemon.sprites.frontDefault)")
            return
        }
        
        print("Loading image from URL: \(url)")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Image loading error: \(error)")
                return
            }
            
            guard let data = data else {
                print("No image data received")
                return
            }
            
            DispatchQueue.main.async {
                self?.imageView.image = UIImage(data: data)
                print("Image loaded successfully")
            }
        }.resume()
    }
} 