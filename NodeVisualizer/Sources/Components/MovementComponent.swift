//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides different types of physics movement based on the current entities state.
class MovementComponent: GKComponent {

    private struct Constants {
        static let strength: CGFloat = 100
        static let dt: CGFloat = 1 / 60
        static let distancePadding: CGFloat = -10
        static let speed: CGFloat = 200
    }

    private var movementStrength: CGFloat = 9.8


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard let entity = entity as? RecordEntity else {
            return
        }

        checkAndUpdateBitMaskIfCloned()

        switch entity.state {
        case .seekEntity(let entity):
            seek(entity, deltaTime: seconds)
        case .seekLevel(let level):
            move(to: level)
        case .static, .selected, .dragging, .reset, .remove:
            break
        }
    }


    // MARK: Helpers

    private func checkAndUpdateBitMaskIfCloned() {
        if let entity = entity as? RecordEntity {
            if let previousCluster = entity.previousCluster,
                let outmostBoundingEntity = previousCluster.layerForLevel[previousCluster.layerForLevel.count - 1]?.renderComponent {
                let deltaX = entity.position.x - previousCluster.center.x
                let deltaY = entity.position.y - previousCluster.center.y
                let distance = previousCluster.distanceOf(x: deltaX, y: deltaY)

                // Update bitmasks if the entity has gone outside the cluster's maxRadius or if the selected entity is panned inside the cluster's maxRadius before
                // the entity has gone outside the maxRadius
                if distance > outmostBoundingEntity.maxRadius || (entity.cluster?.selectedEntity.state == .dragging && distance < outmostBoundingEntity.maxRadius) {
                    entity.previousCluster = nil
                    entity.updateBitMasks()
                }
            } else if entity.physicsBody.categoryBitMask == ColliderType.clonedRecordNode {
                entity.previousCluster = nil
                entity.updateBitMasks()
            }
        }
    }


    // MARK: Physics Movement

    /// Applies appropriate physics that moves the entity to the appropriate higher level before entering next state and setting its bitMasks
    private func move(to level: Int) {
        guard let entity = entity as? RecordEntity,
            let cluster = entity.cluster,
            let referenceNode = cluster.layerForLevel[level]?.renderComponent.layerNode else {
            return
        }

        // Find the unit vector from the distance between this component's entity and the center root node
        let deltaX = entity.position.x - referenceNode.position.x
        let deltaY = entity.position.y - referenceNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let distanceBetweenNodeAndCenter = distanceOf(x: deltaX, y: deltaY)

        var unitVector: CGVector
        // Check whether the entity is currently in the center in order to apply a non-zero unit vector for movement
        if distanceBetweenNodeAndCenter > 0 {
            unitVector = CGVector(dx: displacement.dx / distanceBetweenNodeAndCenter, dy: displacement.dy / distanceBetweenNodeAndCenter)
        } else {
            unitVector = CGVector(dx: 0.5, dy: 0)
        }

        // Find the difference in distance. This gives the total distance that is left to travel for the node
        guard let currentLevel = entity.clusterLevel.currentLevel,
            let currentLevelBoundingEntityComponent = cluster.layerForLevel[currentLevel]?.renderComponent else {
                return
        }

        let r2 = currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < -entity.bodyRadius {
            entity.set(state: .seekEntity(cluster.selectedEntity))
        } else {
            entity.physicsBody.velocity = CGVector(dx: Constants.speed * unitVector.dx, dy: Constants.speed * unitVector.dy)
        }
    }

    /// Applies appropriate physics that emulates a gravitational pull between this component's entity and the entity that it should seek
    private func seek(_ targetEntity: RecordEntity, deltaTime delta: TimeInterval) {
        guard let entity = entity as? RecordEntity, let cluster = entity.cluster else {
            return
        }

        let contactedBodies = entity.physicsBody.allContactedBodies().filter { (contactedBody) -> Bool in
            if let contactedEntity = contactedBody.node?.entity as? RecordEntity,
                let contactedEntityCluster = contactedEntity.cluster,
                contactedEntityCluster !== cluster, contactedEntityCluster.selectedEntity.state != .panning,
                contactedEntity.hasCollidedWithBoundingNode {
                return true
            }
            return false
        }

        if contactedBodies.count > 0,
            entity.physicsBody.velocity.magnitude < 100,
            cluster.selectedEntity.state != .panning {
//            movementStrength += CGFloat(1.2 * CGFloat(contactedBodies.count))
            movementStrength = 100
        } else {
            movementStrength = 100
        }

        // Check the radius between its own entity and the nodeToSeek, and apply the appropriate physics
        let deltaX = targetEntity.position.x - entity.position.x
        let deltaY = targetEntity.position.y - entity.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let radius = distanceOf(x: deltaX, y: deltaY)
        let unitVector = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)

        let targetEntityMass = style.nodePhysicsBodyMass * Constants.strength * radius
        let entityMass = style.nodePhysicsBodyMass * Constants.strength * radius

        let force = (targetEntityMass * entityMass) / (radius * radius)
        let dt = CGFloat(delta)
        let impulse = CGVector(dx: force * dt * unitVector.dx, dy: force * dt * unitVector.dy)
        entity.physicsBody.velocity = CGVector(dx: entity.physicsBody.velocity.dx + impulse.dx, dy: entity.physicsBody.velocity.dy + impulse.dy)
    }

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
