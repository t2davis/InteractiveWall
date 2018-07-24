//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    Class that manages all non-bounding node entities for the scene.
 */

import Foundation
import SpriteKit
import GameplayKit


final class EntityManager {

    private lazy var componentSystems: [GKComponentSystem] = {
        let intelligenceSystem = GKComponentSystem(componentClass: IntelligenceComponent.self)
        let movementSystem = GKComponentSystem(componentClass: MovementComponent.self)
        let animationSystem = GKComponentSystem(componentClass: AnimationComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: PhysicsComponent.self)
        return [intelligenceSystem, animationSystem, movementSystem, physicsSystem]
    }()

    static let instance = EntityManager()

    /// Set of all entities in the scene
    private(set) var entities = Set<GKEntity>()

    /// 2D array of related entities that belong to a particular level
    private(set) var entitiesInLevel = [[RecordEntity]]()

    /// Set of all entities in all levels
    private(set) var allLevelEntities = Set<RecordEntity>()

    /// Set of all entities that are currently in a formed state
    private(set) var allEntitiesInFormedState = Set<RecordEntity>()

    /// Local copy of the entities that are associated with the current level
    private var entitiesInCurrentLevel = [RecordEntity]()

    private struct Constants {
        static let maxLevel = 5
    }


    // Use singleton instance
    private init() { }


    // MARK: API

    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }

    func add(_ entity: GKEntity) {
        entities.insert(entity)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    func remove(_ entity: GKEntity) {
        entities.remove(entity)
    }

    func add(component: GKComponent, to entity: GKEntity) {
        entity.addComponent(component)

        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    func associateRelatedEntities(for entities: [RecordEntity]?, toLevel level: Int = 0) {
        guard let entities = entities, !entities.isEmpty else {
            entitiesInLevel = entitiesInLevel.filter { !($0.isEmpty) }
            return
        }

        // reset the previous level entities
        entitiesInCurrentLevel.removeAll()

        // padding for 2D array
        padEntitiesForLevel(level)

        for entity in entities {
            allLevelEntities.insert(entity)
            allEntitiesInFormedState.insert(entity)

            // add relatedEntities to the appropriate level
            let relatedEntities = getRelatedEntities(for: entity)

            if !relatedEntities.isEmpty {
                entitiesInLevel[level] += relatedEntities
                entitiesInCurrentLevel += relatedEntities
            }
        }

        // all entities that belong past the maxLevel should just go inside maxLevel (i.e. clamp to maxLevel)
        let next = (level == Constants.maxLevel) ? Constants.maxLevel : level + 1

        associateRelatedEntities(for: entitiesInCurrentLevel, toLevel: next)
    }

    func resetAll() {
        for entity in allLevelEntities {
            entity.reset()
        }

        for entity in allEntitiesInFormedState {
            entity.reset()
        }

        allEntitiesInFormedState.removeAll()
        clearLevelEntities()
    }

    func clearLevelEntities() {
        entitiesInLevel.removeAll()
        allLevelEntities.removeAll()
    }


    // MARK: Helpers

    private func getRelatedEntities(for entity: RecordEntity) -> [RecordEntity] {
        let record = entity.renderComponent.recordNode.record

        guard let relatedRecords = TestingEnvironment.instance.relatedRecordsForRecord[record] else {
            return []
        }

        let relatedEntities = entities(for: Array(relatedRecords)).compactMap({ $0 as? RecordEntity })
        return relatedEntities
    }

    private func entities(for records: [TestingEnvironment.Record]) -> [GKEntity] {
        var recordEntities = [GKEntity]()

        for record in records {
            if let entity = entity(for: record) {
                recordEntities.append(entity)
            }
        }

        return recordEntities
    }

    private func entity(for record: TestingEnvironment.Record) -> GKEntity? {
        for entity in entities {
            if let recordEntity = entity as? RecordEntity,
                !allLevelEntities.contains(recordEntity),
                recordEntity.renderComponent.recordNode.record.id == record.id {
                return entity
            }
        }

        return nil
    }

    private func padEntitiesForLevel(_ level: Int) {
        guard entitiesInLevel.count <= level else {
            return
        }

        (entitiesInLevel.count...level).forEach { _ in
            entitiesInLevel.append([])
        }
    }
}
