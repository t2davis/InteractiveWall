//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// Class that manages all non-bounding node entities for the scene.
final class EntityManager {
    static let instance = EntityManager()

    /// Set of all entities
    private(set) var entitiesForProxy = [RecordProxy: [RecordEntity]]()

    /// The scene that record nodes are added to
    var scene: MainScene!

    /// List of all GKComponentSystems. The systems will be updated in order. The order is defined to match assumptions made within components.
    private lazy var componentSystems: [GKComponentSystem] = {
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: PhysicsComponent.self)
        let renderSystem = GKComponentSystem(componentClass: RenderComponent.self)
        return [movementSystem, physicsSystem, animationSystem]
    }()

    private struct Constants {
        static let maxRelatedLevel = 4
    }


    // MARK: Init

    /// Use singleton
    private init() { }


    // MARK: API

    /// Creates and stores record entities from all records from database
    func createEntity(record: RecordDisplayable, levels: RelatedLevels) {
        let entity = RecordEntity(record: record, levels: levels)
        store(entity)
        addComponents(to: entity)
    }

    func allEntities() -> [RecordEntity] {
        return entitiesForProxy.reduce([]) { $0 + $1.value }
    }

    /// If entity is a duplicate it will be removed from the scene, else resets entity.
    func release(_ entity: RecordEntity) {
        guard let entities = entitiesForProxy[entity.record.proxy] else {
            return
        }

        if entities.count > 1 {
            remove(entity)
        } else {
            entity.reset()
        }
    }

    /// Returns the entities associated with the given proxies, if an entity is already with another cluster, the entity will be duplicated
    func requestEntities(with proxies: Set<RecordProxy>, for cluster: NodeCluster) -> Set<RecordEntity> {
        var result = Set<RecordEntity>()
        for proxy in proxies {
            if let entityForProxy = getEntity(for: proxy) {
                // If entity for proxy already has a different cluster, duplicate the entity at the same position
                if let current = entityForProxy.cluster, current != cluster {
                    let copy = entityForProxy.clone()
                    store(copy)
                    addComponents(to: copy)
                    copy.node.scale(to: entityForProxy.node.size)
                    copy.set(position: entityForProxy.position)
                    copy.setClonedNodeBitMasks()
                    copy.previousCluster = current
                    result.insert(copy)
                    scene?.addChild(copy.node)
                } else {
                    result.insert(entityForProxy)
                }
            }
        }

        return result
    }

    /// Updates all component systems that the EntityManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    /// Adds each entity's components to the component system to allow updates to occur
    func addToComponentSystems(for entities: [RecordEntity]) {
        for entity in entities {
            for componentSystem in componentSystems {
                componentSystem.addComponent(foundIn: entity)
            }
        }
    }

    /// Removes each entity's components from the component system so that unnecessary updates do not happen
    func removeFromComponentSystems(for entities: [RecordEntity]) {
        for entity in entities {
            removeComponents(from: entity)
        }
    }

    /// Dynamically add a new component to an entity
    func add(component: GKComponent, to entity: RecordEntity) {
        entity.addComponent(component)
        addComponents(to: entity)
    }


    // MARK: Helpers

    private func store(_ entity: RecordEntity) {
        let proxy = entity.record.proxy
        if entitiesForProxy[proxy] == nil {
            entitiesForProxy[proxy] = [entity]
        } else {
            entitiesForProxy[proxy]!.append(entity)
        }
    }

    /// Removes an entity from the scene and local cache
    private func remove(_ entity: RecordEntity) {
        let proxy = entity.record.proxy
        let entities = entitiesForProxy[proxy]
        if let index = entities?.index(where: { $0 === entity }) {
            removeComponents(from: entity)
            entity.node.removeFromParent()
            entitiesForProxy[proxy]?.remove(at: index)
        }
    }

    /// Returns entity for given record, prioritizing records that are not already clustered
    private func getEntity(for proxy: RecordProxy) -> RecordEntity? {
        guard let entities = entitiesForProxy[proxy] else {
            return nil
        }

        if let unclustered = entities.first(where: { $0.cluster == nil }) {
            return unclustered
        }

        return entities.first
    }

    private func addComponents(to entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    private func removeComponents(from entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: entity)
        }
    }

    // TODO: fix the duplicating and tapping on related items issue
    private func randomize(entities: Set<RecordEntity>, upTo max: Int) -> Set<RecordEntity> {
        let entities = Array(entities)
        let randomizedEntities = GKRandomSource().arrayByShufflingObjects(in: entities).compactMap({ $0 as? RecordEntity })
        let filteredRandomizedEntities = randomizedEntities.prefix(upTo: max)
        return Set(filteredRandomizedEntities)
    }
}

extension MutableCollection {
    /// Shuffles the contents of this collection.
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            // Change `Int` in the next line to `IndexDistance` in < Swift 4.1
            let d: Int = numericCast(arc4random_uniform(numericCast(unshuffledCount)))
            let i = index(firstUnshuffled, offsetBy: d)
            swapAt(firstUnshuffled, i)
        }
    }
}

extension Sequence {
    /// Returns an array with the contents of this sequence, shuffled.
    func shuffled() -> [Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}
