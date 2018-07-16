//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class SeekState: GKState {

    private unowned var entity: RecordEntity


    required init(entity: RecordEntity) {
        self.entity = entity
    }


    // MARK: GKState Lifecycle

    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)

        entity.physicsComponent.physicsBody.friction = 1
        entity.physicsComponent.physicsBody.linearDamping = 1
        entity.physicsComponent.physicsBody.fieldBitMask = 0x1 << 1
        entity.physicsComponent.physicsBody.isDynamic = true
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
