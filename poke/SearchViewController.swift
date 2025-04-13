import UIKit
import MapKit
import CoreLocation
import SceneKit

class SearchViewController: UIViewController {
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private let locationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        button.setImage(UIImage(systemName: "location.fill")?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(nil, action: #selector(centerMapOnUserLocation), for: .touchUpInside)
        return button
    }()
    
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    private var pokemons: [Pokemon] = []
    private var pokemonAnnotations: [PokemonAnnotation] = []
    private var savedPokemonLocations: [String: CLLocationCoordinate2D] = [:]
    
    private let arView: SCNView = {
        let view = SCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var eeveeNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search Pokemon"
        
        setupMapView()
        setupLocationManager()
        setupLocationButton()
        loadPokemonLocations()  // 加载保存的位置信息
        fetchPokemonData()
        setupAR()
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        mapView.delegate = self
        mapView.showsUserLocation = true  // 显示用户位置
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func setupLocationButton() {
        view.addSubview(locationButton)
        
        NSLayoutConstraint.activate([
            locationButton.widthAnchor.constraint(equalToConstant: 50),
            locationButton.heightAnchor.constraint(equalToConstant: 50),
            locationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            locationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func fetchPokemonData() {
        // 获取20种宝可梦的数据
        let pokemonNames = [
            "eevee", "bulbasaur", "charmander", "squirtle", "jigglypuff",
            "meowth", "psyduck", "growlithe", "poliwag", "abra",
            "machop", "tentacool", "geodude", "ponyta", "slowpoke",
            "magnemite", "doduo", "seel", "grimer", "shellder"
        ]
        
        for name in pokemonNames {
            guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(name)") else { continue }
            
            URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let data = data, error == nil else { return }
                
                do {
                    let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                    DispatchQueue.main.async {
                        self?.pokemons.append(pokemon)
                        if self?.pokemons.count == pokemonNames.count {
                            self?.addRandomPokemons()
                        }
                    }
                } catch {
                    print("Error decoding Pokemon: \(error)")
                }
            }.resume()
        }
    }
    
    private func addRandomPokemons() {
        // 清除现有的标注
        mapView.removeAnnotations(pokemonAnnotations)
        pokemonAnnotations.removeAll()
        
        // 添加伊布在用户位置
        if let userLocation = userLocation {
            let eeveeAnnotation = PokemonAnnotation(
                coordinate: userLocation.coordinate,
                pokemon: pokemons[0],
                title: "Eevee"
            )
            pokemonAnnotations.append(eeveeAnnotation)
            mapView.addAnnotation(eeveeAnnotation)
            savedPokemonLocations["eevee"] = userLocation.coordinate
        }
        
        // 从剩余的19只宝可梦中随机选择9只
        var availablePokemons = Array(pokemons[1..<pokemons.count])
        availablePokemons.shuffle()
        let selectedPokemons = Array(availablePokemons.prefix(9))
        
        // 添加选中的9只宝可梦
        for pokemon in selectedPokemons {
            let coordinate: CLLocationCoordinate2D
            
            // 如果已经保存了位置，使用保存的位置
            if let savedLocation = savedPokemonLocations[pokemon.name] {
                coordinate = savedLocation
            } else {
                // 否则生成新的随机位置并保存
                guard let randomLocation = generateRandomLocation() else { continue }
                coordinate = randomLocation
                savedPokemonLocations[pokemon.name] = coordinate
            }
            
            let annotation = PokemonAnnotation(
                coordinate: coordinate,
                pokemon: pokemon,
                title: pokemon.name.capitalized
            )
            pokemonAnnotations.append(annotation)
            mapView.addAnnotation(annotation)
        }
        
        // 保存位置信息到UserDefaults
        savePokemonLocations()
    }
    
    private func generateRandomLocation() -> CLLocationCoordinate2D? {
        guard let userLocation = userLocation else { return nil }
        
        // 在用户位置周围10公里范围内生成随机位置
        let radius = 10000.0 // 10公里
        let randomAngle = Double.random(in: 0...2 * .pi)
        let randomRadius = Double.random(in: 0...radius)
        
        let lat = userLocation.coordinate.latitude + (randomRadius * sin(randomAngle) / 111111.0)
        let lon = userLocation.coordinate.longitude + (randomRadius * cos(randomAngle) / (111111.0 * cos(userLocation.coordinate.latitude * .pi / 180.0)))
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    private func savePokemonLocations() {
        let locationsData = savedPokemonLocations.map { (name, coordinate) in
            ["name": name, "latitude": coordinate.latitude, "longitude": coordinate.longitude]
        }
        UserDefaults.standard.set(locationsData, forKey: "savedPokemonLocations")
    }
    
    private func loadPokemonLocations() {
        if let locationsData = UserDefaults.standard.array(forKey: "savedPokemonLocations") as? [[String: Any]] {
            for locationData in locationsData {
                if let name = locationData["name"] as? String,
                   let latitude = locationData["latitude"] as? Double,
                   let longitude = locationData["longitude"] as? Double {
                    savedPokemonLocations[name] = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                }
            }
        }
    }
    
    @objc private func centerMapOnUserLocation() {
        guard let userLocation = userLocation else { return }
        
        // 点击定位按钮时显示3公里范围
        let region = MKCoordinateRegion(
            center: userLocation.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        mapView.setRegion(region, animated: true)
    }
    
    private func setupAR() {
        // 创建伊布模型
        guard let eeveeScene = SCNScene(named: "art.scnassets/eevee.scn") else {
            print("Failed to load eevee scene")
            return
        }
        
        eeveeNode = eeveeScene.rootNode.childNodes.first
        eeveeNode?.position = SCNVector3(0, 0, -1)
        eeveeNode?.scale = SCNVector3(0.001, 0.001, 0.001) // 缩小100倍
        
        // 确保arView的scene已初始化
        if arView.scene == nil {
            arView.scene = SCNScene()
        }
        
        // 安全地添加节点
        if let eeveeNode = eeveeNode {
            arView.scene?.rootNode.addChildNode(eeveeNode)
        }
        
        // 设置AR场景
        arView.autoenablesDefaultLighting = true
        arView.backgroundColor = .clear // 设置背景为透明
    }
}

extension SearchViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        // 设置地图初始区域，显示3公里范围
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        )
        mapView.setRegion(region, animated: true)
        
        // 只在第一次获取位置时添加宝可梦
        if pokemons.count > 0 && pokemonAnnotations.isEmpty {
            addRandomPokemons()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
}

extension SearchViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // 如果是用户位置，返回 nil 以使用默认的蓝色标记
        if annotation is MKUserLocation {
            return nil
        }
        
        guard let pokemonAnnotation = annotation as? PokemonAnnotation else { return nil }
        
        let identifier = "PokemonAnnotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // 设置宝可梦图片，增大图标尺寸到100x100
            if let url = URL(string: pokemonAnnotation.pokemon.sprites.frontDefault) {
                URLSession.shared.dataTask(with: url) { data, response, error in
                    guard let data = data, error == nil else { return }
                    DispatchQueue.main.async {
                        annotationView?.image = UIImage(data: data)?.resized(to: CGSize(width: 100, height: 100))
                    }
                }.resume()
            }
        } else {
            annotationView?.annotation = annotation
        }
        
        return annotationView
    }
}

class PokemonAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let pokemon: Pokemon
    let title: String?
    
    init(coordinate: CLLocationCoordinate2D, pokemon: Pokemon, title: String?) {
        self.coordinate = coordinate
        self.pokemon = pokemon
        self.title = title
        super.init()
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
} 