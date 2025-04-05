import Foundation

struct Pokemon: Codable {
    let name: String
    let height: Int
    let weight: Int
    let baseExperience: Int
    let stats: [Stat]
    let sprites: Sprites
    
    enum CodingKeys: String, CodingKey {
        case name
        case height
        case weight
        case baseExperience = "base_experience"
        case stats
        case sprites
    }
    
    struct Stat: Codable {
        let baseStat: Int
        let name: String
        
        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case stat
        }
        
        enum StatCodingKeys: String, CodingKey {
            case name
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            baseStat = try container.decode(Int.self, forKey: .baseStat)
            let statContainer = try container.nestedContainer(keyedBy: StatCodingKeys.self, forKey: .stat)
            name = try statContainer.decode(String.self, forKey: .name)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(baseStat, forKey: .baseStat)
            var statContainer = container.nestedContainer(keyedBy: StatCodingKeys.self, forKey: .stat)
            try statContainer.encode(name, forKey: .name)
        }
    }
    
    struct Sprites: Codable {
        let frontDefault: String
        
        enum CodingKeys: String, CodingKey {
            case frontDefault = "front_default"
        }
    }
} 