import UIKit

class PokemonDetailViewController: UIViewController {
    
    private let pokemon: Pokemon
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private let contentView = UIView()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let statsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
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
        view.backgroundColor = .white
        title = pokemon.name.capitalized
        setupUI()
        loadPokemonImage()
    }
    
    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(imageView)
        contentView.addSubview(statsStack)
        
        nameLabel.text = pokemon.name.capitalized
        
        // 设置contentView的约束
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ScrollView约束
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // ContentView约束
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            
            // NameLabel约束
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            // ImageView约束
            imageView.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 200),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            // StatsStack约束
            statsStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            statsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // 添加属性信息
        addStatLabel(title: "Height", value: "\(pokemon.height) dm")
        addStatLabel(title: "Weight", value: "\(pokemon.weight) hg")
        addStatLabel(title: "Base Experience", value: "\(pokemon.baseExperience)")
        
        // 添加能力值
        for stat in pokemon.stats {
            addStatLabel(title: stat.name, value: "\(stat.baseStat)")
        }
    }
    
    private func addStatLabel(title: String, value: String) {
        let label = UILabel()
        label.text = "\(title): \(value)"
        label.translatesAutoresizingMaskIntoConstraints = false
        statsStack.addArrangedSubview(label)
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