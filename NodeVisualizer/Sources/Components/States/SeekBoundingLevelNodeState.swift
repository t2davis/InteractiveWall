//  Copyright © 2018 JABT. All rights reserved.

/*
    Abstract:
    A RecordEntity enters this state when it needs to move to its level's bounding node entity's minimum distance before seeking the TappedState's RecordEntity. Entering this intermediary state allows for more fluid movement and interaction between the entities and their level node bounding entities.
 */

import Foundation
import SpriteKit
import GameplayKit


class SeekBoundingLevelNodeState: GKState {

    /// The entity associated with this state
    private unowned var entity: RecordEntity

    private var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity.component(ofType: PhysicsComponent.self) else {
            fatalError("A SeekBoundingLevelNodeState's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }


    // MARK: Initializer

    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        // declare local version so that we don't compute multiple times
        let physicsComponent = self.physicsComponent

        // sticky collisions
        physicsComponent.physicsBody.restitution = 0
        physicsComponent.physicsBody.friction = 1
        physicsComponent.physicsBody.linearDamping = 1

        // interactable with rest of physics world
        physicsComponent.physicsBody.isDynamic = true

        // not interactable with the repulsive 'reset' radial force field
        physicsComponent.physicsBody.fieldBitMask = 0x1 << 1
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
    }

    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }

    override func willExit(to nextState: GKState) {
        super.willExit(to: nextState)
    }
}
