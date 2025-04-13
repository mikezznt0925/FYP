import UIKit
import ARKit
import SceneKit

class CaptureViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - Properties
    private var arView: ARSCNView!
    private var playerEeveeNode: SCNNode?
    private var wildEeveeNode: SCNNode?
    private var eeveeHealth = 100
    private var playerPokemonHealth = 100
    private var isBattleStarted = false
    private var isEeveeDefeated = false
    private var packageVC: PackageViewController?
    
    // UI Elements
    private let healthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.backgroundColor = .black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }()
    
    private let actionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .systemFont(ofSize: 16)
        label.backgroundColor = .black.withAlphaComponent(0.5)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.numberOfLines = 0
        return label
    }()
    
    private let skillStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        return stack
    }()
    
    private let captureButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Capture", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.isHidden = true
        return button
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        setupAR()
        
        // 检查是否已选择宝可梦
        if PackageViewController.capturedPokemons.isEmpty {
            showAlert(title: "Error", message: "Please select a Pokemon to battle")
            return
        }
        
        if let selectedPokemon = PackageViewController.selectedPokemon {
            updateHealthLabel()
        } else {
            showAlert(title: "Error", message: "You don't choose a Pokemon to battle")
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        arView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // AR View
        arView = ARSCNView(frame: view.bounds)
        arView.delegate = self
        view.addSubview(arView)
        
        // Health Label
        view.addSubview(healthLabel)
        NSLayoutConstraint.activate([
            healthLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            healthLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            healthLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            healthLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Action Label
        view.addSubview(actionLabel)
        NSLayoutConstraint.activate([
            actionLabel.topAnchor.constraint(equalTo: healthLabel.bottomAnchor, constant: 10),
            actionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            actionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionLabel.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        // Skill Buttons
        let impactButton = createSkillButton(title: "Impact")
        let fightButton = createSkillButton(title: "Fight")
        let strikeButton = createSkillButton(title: "Strike")
        
        skillStackView.addArrangedSubview(impactButton)
        skillStackView.addArrangedSubview(fightButton)
        skillStackView.addArrangedSubview(strikeButton)
        
        view.addSubview(skillStackView)
        NSLayoutConstraint.activate([
            skillStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            skillStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            skillStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            skillStackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Capture Button
        view.addSubview(captureButton)
        NSLayoutConstraint.activate([
            captureButton.bottomAnchor.constraint(equalTo: skillStackView.topAnchor, constant: -20),
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.widthAnchor.constraint(equalToConstant: 120),
            captureButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
    }
    
    private func setupAR() {
        // 创建玩家的伊布模型
        guard let playerEeveeScene = SCNScene(named: "art.scnassets/eevee.scn") else {
            print("Failed to load eevee scene")
            return
        }
        
        playerEeveeNode = playerEeveeScene.rootNode.childNodes.first
        playerEeveeNode?.position = SCNVector3(-0.3, 0, -1) // 放在左边，更靠近中心
        playerEeveeNode?.scale = SCNVector3(0.004, 0.004, 0.004)
        playerEeveeNode?.eulerAngles.y = .pi / 2 // 向右旋转90度
        
        // 创建野生的伊布模型
        guard let wildEeveeScene = SCNScene(named: "art.scnassets/eevee.scn") else {
            print("Failed to load eevee scene")
            return
        }
        
        wildEeveeNode = wildEeveeScene.rootNode.childNodes.first
        wildEeveeNode?.position = SCNVector3(0.3, 0, -1) // 放在右边，更靠近中心
        wildEeveeNode?.scale = SCNVector3(0.004, 0.004, 0.004)
        wildEeveeNode?.eulerAngles.y = -.pi / 2 // 向左旋转90度
        
        // 确保arView的scene已初始化
        if arView.scene == nil {
            arView.scene = SCNScene()
        }
        
        // 安全地添加节点
        if let playerEeveeNode = playerEeveeNode {
            arView.scene.rootNode.addChildNode(playerEeveeNode)
        }
        if let wildEeveeNode = wildEeveeNode {
            arView.scene.rootNode.addChildNode(wildEeveeNode)
        }
        
        // 设置AR场景
        arView.autoenablesDefaultLighting = true
        arView.backgroundColor = .clear // 设置背景为透明
    }
    
    private func createSkillButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(skillButtonTapped(_:)), for: .touchUpInside)
        return button
    }
    
    // MARK: - Actions
    @objc private func skillButtonTapped(_ sender: UIButton) {
        guard let skill = sender.titleLabel?.text else { return }
        guard let selectedPokemon = PackageViewController.selectedPokemon else {
            showAlert(title: "Error", message: "Please select a Pokemon first")
            return
        }
        
        // 野生宝可梦随机使用技能
        let eeveeSkills = ["Impact", "Fight", "Strike"]
        let eeveeSkill = eeveeSkills.randomElement()!
        
        var playerDamage = 0
        var eeveeDamage = 0
        var playerEffect = ""
        var eeveeEffect = ""
        
        // 检查技能克制关系
        if skill == "Impact" && eeveeSkill == "Strike" {
            playerDamage = 30
            playerEffect = "Effective hit! Impact nullifies Strike!"
            // 玩家宝可梦攻击动画
            animateAttack(attacker: playerEeveeNode, defender: wildEeveeNode)
        } else if skill == "Fight" && eeveeSkill == "Impact" {
            playerDamage = 30
            playerEffect = "Effective hit! Fight nullifies Impact!"
            // 玩家宝可梦攻击动画
            animateAttack(attacker: playerEeveeNode, defender: wildEeveeNode)
        } else if skill == "Strike" && eeveeSkill == "Fight" {
            playerDamage = 30
            playerEffect = "Effective hit! Strike nullifies Fight!"
            // 玩家宝可梦攻击动画
            animateAttack(attacker: playerEeveeNode, defender: wildEeveeNode)
        }
        
        if eeveeSkill == "Impact" && skill == "Strike" {
            eeveeDamage = 30
            eeveeEffect = "Effective hit! Impact nullifies Strike!"
            // 野生宝可梦攻击动画
            animateAttack(attacker: wildEeveeNode, defender: playerEeveeNode)
        } else if eeveeSkill == "Fight" && skill == "Impact" {
            eeveeDamage = 30
            eeveeEffect = "Effective hit! Fight nullifies Impact!"
            // 野生宝可梦攻击动画
            animateAttack(attacker: wildEeveeNode, defender: playerEeveeNode)
        } else if eeveeSkill == "Strike" && skill == "Fight" {
            eeveeDamage = 30
            eeveeEffect = "Effective hit! Strike nullifies Fight!"
            // 野生宝可梦攻击动画
            animateAttack(attacker: wildEeveeNode, defender: playerEeveeNode)
        }
        
        // 更新血量
        eeveeHealth = max(0, eeveeHealth - playerDamage)
        playerPokemonHealth = max(0, playerPokemonHealth - eeveeDamage)
        
        // 更新UI
        actionLabel.text = "Your \(selectedPokemon.name.capitalized) used \(skill)!\n\(playerEffect)\nWild Eevee used \(eeveeSkill)!\n\(eeveeEffect)"
        updateHealthLabel()
        
        // 检查战斗是否结束
        if eeveeHealth <= 0 {
            endBattle(isPlayerWin: true)
        } else if playerPokemonHealth <= 0 {
            endBattle(isPlayerWin: false)
        }
    }
    
    private func animateAttack(attacker: SCNNode?, defender: SCNNode?) {
        guard let attacker = attacker, let defender = defender else { return }
        
        // 保存原始位置
        let originalPosition = attacker.position
        
        // 创建攻击动画
        let moveForward = SCNAction.move(to: defender.position, duration: 0.2)
        let moveBack = SCNAction.move(to: originalPosition, duration: 0.2)
        
        // 添加震动效果
        let shake = SCNAction.sequence([
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05),
            SCNAction.moveBy(x: -0.2, y: 0, z: 0, duration: 0.1),
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05)
        ])
        
        // 创建受击动画
        let hitShake = SCNAction.sequence([
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05),
            SCNAction.moveBy(x: -0.2, y: 0, z: 0, duration: 0.1),
            SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.05)
        ])
        
        // 创建闪烁效果
        let originalColor = defender.geometry?.firstMaterial?.diffuse.contents
        let flash = SCNAction.sequence([
            SCNAction.run { _ in defender.geometry?.firstMaterial?.diffuse.contents = UIColor.red },
            SCNAction.wait(duration: 0.1),
            SCNAction.run { _ in defender.geometry?.firstMaterial?.diffuse.contents = originalColor }
        ])
        
        // 执行攻击者动画序列
        let attackerSequence = SCNAction.sequence([
            moveForward,
            shake,
            moveBack
        ])
        
        // 执行防御者动画序列
        let defenderSequence = SCNAction.sequence([
            hitShake,
            flash
        ])
        
        // 同时执行两个动画
        attacker.runAction(attackerSequence)
        defender.runAction(defenderSequence)
    }
    
    @objc private func captureButtonTapped() {
        guard eeveeHealth <= 0 else {
            showAlert(title: "Cannot Capture", message: "Eevee's health is too high")
            return
        }
        
        let success = Bool.random()
        if success {
            // 捕捉成功
            let newEevee = Pokemon(
                name: "eevee",
                height: 3,
                weight: 65,
                baseExperience: 65,
                stats: [
                    Pokemon.Stat(baseStat: 55, name: "hp"),
                    Pokemon.Stat(baseStat: 55, name: "attack"),
                    Pokemon.Stat(baseStat: 50, name: "defense"),
                    Pokemon.Stat(baseStat: 45, name: "special-attack"),
                    Pokemon.Stat(baseStat: 65, name: "special-defense"),
                    Pokemon.Stat(baseStat: 55, name: "speed")
                ],
                types: [
                    PokemonType(type: PokemonType.TypeInfo(name: "normal"))
                ],
                sprites: Pokemon.Sprites(frontDefault: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/133.png")
            )
            PackageViewController.capturedPokemons.append(newEevee)
            showAlert(title: "Success", message: "Successful capture! Eevee has been added to your package.") {
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            // 捕捉失败
            showAlert(title: "Failed", message: "Capture fail! Try again.") {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // MARK: - Battle Logic
    private func calculateDamage(for skill: String, from pokemon: Pokemon) -> Int {
        // 根据宝可梦的攻击力和技能类型计算伤害
        let attackStat = pokemon.stats.first { $0.name == "attack" }?.baseStat ?? 50
        let baseDamage = 20 // 基础伤害值
        
        // 根据技能类型增加伤害
        var damageMultiplier = 1.0
        switch skill {
        case "Impact":
            damageMultiplier = 0.4 // 原1.2的1/3
        case "Fight":
            damageMultiplier = 0.5 // 原1.5的1/3
        case "Strike":
            damageMultiplier = 0.43 // 原1.3的1/3
        default:
            damageMultiplier = 1.0
        }
        
        // 计算最终伤害
        let finalDamage = Int(Double(baseDamage + attackStat) * damageMultiplier)
        return finalDamage
    }
    
    private func endBattle(isPlayerWin: Bool) {
        if isPlayerWin {
            isEeveeDefeated = true
            captureButton.isHidden = false
            showAlert(title: "Victory", message: "You defeated Eevee! Try to capture it!", shouldReturn: false)
        } else {
            showAlert(title: "Defeat", message: "Your Pokemon fainted!", shouldReturn: true)
            resetBattle()
        }
    }
    
    private func battle(playerSkill: String, eeveeSkill: String) -> String {
        var playerDamage = 0
        var eeveeDamage = 0
        
        // 检查技能克制关系
        if playerSkill == "Impact" && eeveeSkill == "Strike" {
            playerDamage = 30
        } else if playerSkill == "Fight" && eeveeSkill == "Impact" {
            playerDamage = 30
        } else if playerSkill == "Strike" && eeveeSkill == "Fight" {
            playerDamage = 30
        }
        
        if eeveeSkill == "Impact" && playerSkill == "Strike" {
            eeveeDamage = 30
        } else if eeveeSkill == "Fight" && playerSkill == "Impact" {
            eeveeDamage = 30
        } else if eeveeSkill == "Strike" && playerSkill == "Fight" {
            eeveeDamage = 30
        }
        
        // 更新血量
        playerPokemonHealth -= eeveeDamage
        eeveeHealth -= playerDamage
        
        return "\(playerDamage > 0 ? "Effective hit!" : "No effect...")"
    }
    
    private func checkBattleResult() {
        if playerPokemonHealth <= 0 {
            showAlert(title: "Game Over", message: "Your Pokemon died!")
            resetBattle()
        } else if eeveeHealth <= 0 {
            showAlert(title: "Victory", message: "Eevee died!")
            isEeveeDefeated = true
            captureButton.isHidden = false
        } else if eeveeHealth <= 10 {
            captureButton.isHidden = false
        }
    }
    
    private func resetBattle() {
        isBattleStarted = false
        playerPokemonHealth = 100
        eeveeHealth = 100
        updateHealthLabel()
        actionLabel.text = ""
        captureButton.isHidden = true
    }
    
    private func updateHealthLabel() {
        healthLabel.text = "\(PackageViewController.selectedPokemon?.name.capitalized ?? "Your Pokemon"): \(playerPokemonHealth) HP | Wild Eevee: \(eeveeHealth) HP"
    }
    
    private func showAlert(title: String, message: String, shouldReturn: Bool = true, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            completion?()
            if shouldReturn {
                self?.navigationController?.popViewController(animated: true)
            }
        })
        present(alert, animated: true)
    }
} 