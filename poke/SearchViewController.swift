import UIKit
import MapKit
import CoreLocation

class SearchViewController: UIViewController {
    
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    private var pokemons: [Pokemon] = []
    private var pokemonAnnotations: [PokemonAnnotation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Search Pokemon"
        
        setupMapView()
        setupLocationManager()
        fetchPokemonData()
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
    
    private func fetchPokemonData() {
        // 获取20种宝可梦的数据
        let pokemonNames = [
            "pikachu", "bulbasaur", "charmander", "squirtle", "jigglypuff",
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
        
        // 添加皮卡丘在用户位置
        if let userLocation = userLocation {
            let pikachuAnnotation = PokemonAnnotation(
                coordinate: userLocation.coordinate,
                pokemon: pokemons[0],
                title: "Pikachu"
            )
            pokemonAnnotations.append(pikachuAnnotation)
            mapView.addAnnotation(pikachuAnnotation)
        }
        
        // 添加其他随机宝可梦
        for i in 1..<pokemons.count {
            if let randomLocation = generateRandomLocation() {
                let annotation = PokemonAnnotation(
                    coordinate: randomLocation,
                    pokemon: pokemons[i],
                    title: pokemons[i].name.capitalized
                )
                pokemonAnnotations.append(annotation)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    private func generateRandomLocation() -> CLLocationCoordinate2D? {
        guard let userLocation = userLocation else { return nil }
        
        // 在用户位置周围5公里范围内生成随机位置
        let radius = 5000.0 // 5公里
        let randomAngle = Double.random(in: 0...2 * .pi)
        let randomRadius = Double.random(in: 0...radius)
        
        let lat = userLocation.coordinate.latitude + (randomRadius * sin(randomAngle) / 111111.0)
        let lon = userLocation.coordinate.longitude + (randomRadius * cos(randomAngle) / (111111.0 * cos(userLocation.coordinate.latitude * .pi / 180.0)))
        
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}

extension SearchViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location
        
        // 设置地图区域，扩大到5公里范围
        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
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