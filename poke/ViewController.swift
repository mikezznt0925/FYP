//
//  ViewController.swift
//  poke
//
//  Created by zhongzhangniantong on 2025/1/9.
//

import UIKit

class ViewController: UIViewController {
    
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "main")
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Pokemon Master"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 36)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your journey begins here"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private func createButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
        
        // Add shadow
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.3
        
        return button
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Add background image and overlay
        view.addSubview(backgroundImageView)
        view.addSubview(overlayView)
        
        // Add title and subtitle
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        // Add buttons
        view.addSubview(buttonStack)
        
        // Create and add buttons
        let buttons = ["Pokedex", "Package", "Search", "Capture"]
        buttons.forEach { title in
            buttonStack.addArrangedSubview(createButton(title: title))
        }
        
        NSLayoutConstraint.activate([
            // Background image constraints
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Overlay constraints
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Title constraints
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Subtitle constraints
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Button stack constraints
            buttonStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            buttonStack.heightAnchor.constraint(equalToConstant: 240)
        ])
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        // Add button press animation
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }
        
        if sender.currentTitle == "Pokedex" {
            let pokedexVC = PokedexViewController()
            navigationController?.pushViewController(pokedexVC, animated: true)
        } else if sender.currentTitle == "Search" {
            let searchVC = SearchViewController()
            navigationController?.pushViewController(searchVC, animated: true)
        }
    }
}

