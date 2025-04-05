//
//  ViewController.swift
//  poke
//
//  Created by zhongzhangniantong on 2025/1/9.
//

import UIKit

class ViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Pokemon Master"
        label.textColor = .systemRed
        label.font = .boldSystemFont(ofSize: 24)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let mainImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "main")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private func createButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        return button
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加标题和主图片
        view.addSubview(titleLabel)
        view.addSubview(mainImageView)
        view.addSubview(buttonStack)
        
        // 创建并添加按钮
        let buttons = ["Pokedex", "Package", "Search", "Capture"]
        buttons.forEach { title in
            buttonStack.addArrangedSubview(createButton(title: title))
        }
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            mainImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
            mainImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            mainImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            mainImageView.heightAnchor.constraint(equalTo: mainImageView.widthAnchor),
            
            buttonStack.topAnchor.constraint(equalTo: mainImageView.bottomAnchor, constant: 40),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            buttonStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        if sender.currentTitle == "Pokedex" {
            let pokedexVC = PokedexViewController()
            navigationController?.pushViewController(pokedexVC, animated: true)
        }
    }
}

