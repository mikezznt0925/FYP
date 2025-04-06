import UIKit
import ARKit
import SceneKit

class CaptureViewController: UIViewController {
    
    private let sceneView: ARSCNView = {
        let view = ARSCNView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Capture", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 30
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        button.isEnabled = false  // 初始时禁用按钮
        return button
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    private var currentPokemon: Pokemon?
    private var pokemonNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAR()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "Capture Pokemon"
        
        view.addSubview(sceneView)
        view.addSubview(captureButton)
        view.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            captureButton.widthAnchor.constraint(equalToConstant: 120),
            captureButton.heightAnchor.constraint(equalToConstant: 60),
            
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.widthAnchor.constraint(equalToConstant: 200),
            statusLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }
    
    private func setupAR() {
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = [.showFeaturePoints]  // 添加特征点显示，帮助调试
    }
    
    private func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            statusLabel.text = "AR not supported on this device"
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        statusLabel.text = "Move your device to detect surfaces"
    }
    
    private func spawnRandomPokemon() {
        // 清除现有的宝可梦
        pokemonNode?.removeFromParentNode()
        
        // 随机选择一个宝可梦
        let pokemonNames = ["pikachu", "bulbasaur", "charmander", "squirtle", "jigglypuff"]
        let randomName = pokemonNames.randomElement() ?? "pikachu"
        
        // 获取宝可梦数据
        guard let url = URL(string: "https://pokeapi.co/api/v2/pokemon/\(randomName)") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                let pokemon = try JSONDecoder().decode(Pokemon.self, from: data)
                DispatchQueue.main.async {
                    self?.currentPokemon = pokemon
                    self?.statusLabel.text = "A wild \(pokemon.name.capitalized) appeared!"
                    self?.spawnPokemonModel(pokemon: pokemon)
                    self?.captureButton.isEnabled = true  // 宝可梦出现后启用按钮
                }
            } catch {
                print("Error decoding Pokemon: \(error)")
            }
        }.resume()
    }
    
    private func spawnPokemonModel(pokemon: Pokemon) {
        // 创建宝可梦模型节点
        let pokemonNode = SCNNode()
        
        // 设置宝可梦的位置（在相机前方2米处）
        guard let currentFrame = sceneView.session.currentFrame else { return }
        let transform = currentFrame.camera.transform
        var translation = matrix_identity_float4x4
        translation.columns.3.z = -2.0
        let finalTransform = simd_mul(transform, translation)
        pokemonNode.simdTransform = finalTransform
        
        // 根据宝可梦名称加载对应的3D模型
        let modelName = getModelName(for: pokemon.name)
        if let modelScene = SCNScene(named: "\(modelName).scn") {
            let modelNode = modelScene.rootNode.childNodes.first!
            modelNode.scale = SCNVector3(0.1, 0.1, 0.1)  // 调整模型大小
            pokemonNode.addChildNode(modelNode)
        } else {
            // 如果找不到模型文件，使用默认的球体
            let sphere = SCNSphere(radius: 0.2)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            pokemonNode.geometry = sphere
        }
        
        // 添加动画
        let rotateAction = SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 5)
        let repeatAction = SCNAction.repeatForever(rotateAction)
        pokemonNode.runAction(repeatAction)
        
        sceneView.scene.rootNode.addChildNode(pokemonNode)
        self.pokemonNode = pokemonNode
    }
    
    private func getModelName(for pokemonName: String) -> String {
        // 宝可梦名称到模型文件的映射
        let modelMapping: [String: String] = [
            "pikachu": "pikachu",
            "bulbasaur": "bulbasaur",
            "charmander": "charmander",
            "squirtle": "squirtle",
            "jigglypuff": "jigglypuff",
            "meowth": "meowth",
            "psyduck": "psyduck",
            "growlithe": "growlithe",
            "poliwag": "poliwag",
            "abra": "abra",
            "machop": "machop",
            "tentacool": "tentacool",
            "geodude": "geodude",
            "ponyta": "ponyta",
            "slowpoke": "slowpoke",
            "magnemite": "magnemite",
            "doduo": "doduo",
            "seel": "seel",
            "grimer": "grimer",
            "shellder": "shellder"
        ]
        
        return modelMapping[pokemonName.lowercased()] ?? "default"
    }
    
    @objc private func captureButtonTapped() {
        guard let pokemon = currentPokemon else {
            statusLabel.text = "No Pokemon to capture"
            return
        }
        
        // 禁用按钮，防止重复点击
        captureButton.isEnabled = false
        
        // 显示捕捉动画
        statusLabel.text = "Capturing \(pokemon.name.capitalized)..."
        
        // 模拟捕捉过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // 随机决定是否捕捉成功
            let isSuccess = Bool.random()
            
            if isSuccess {
                self?.statusLabel.text = "Gotcha! \(pokemon.name.capitalized) was caught!"
                // 将宝可梦添加到Package中
                PackageViewController.capturedPokemons.append(pokemon)
            } else {
                self?.statusLabel.text = "Oh no! \(pokemon.name.capitalized) escaped!"
            }
            
            // 3秒后生成新的宝可梦
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.spawnRandomPokemon()
            }
        }
    }
}

extension CaptureViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        statusLabel.text = "AR session failed"
        captureButton.isEnabled = false
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        statusLabel.text = "AR session interrupted"
        captureButton.isEnabled = false
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        startARSession()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            statusLabel.text = "Surface detected"
            spawnRandomPokemon()
        }
    }
} 