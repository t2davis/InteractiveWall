//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


class AnimationComponent: GKComponent {

    var renderComponent: RenderComponent {
        guard let renderComponent = entity?.component(ofType: RenderComponent.self) else {
            fatalError("An AnimationComponent's entity must have a RenderComponent")
        }
        return renderComponent
    }

    var intelligenceComponent: IntelligenceComponent {
        guard let intelligenceComponent = entity?.component(ofType: IntelligenceComponent.self) else {
            fatalError("An AnimationComponent's entity must have an IntelligenceComponent")
        }
        return intelligenceComponent
    }

    var physicsComponent: PhysicsComponent {
        guard let physicsComponent = entity?.component(ofType: PhysicsComponent.self) else {
            fatalError("An AnimationComponent's entity must have a PhysicsComponent")
        }
        return physicsComponent
    }

    enum AnimationState {
        case goToPoint(CGPoint)
    }

    var requestedAnimationState: AnimationState?


    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        // if an animation has been requested and the entity is in the TappedState, then run the animation
        if let animationState = requestedAnimationState {
            requestedAnimationState = nil
            runAnimationFor(animationState)
        }
    }


    // MARK: Helpers

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }

    private func runAnimationFor(_ animationState: AnimationState) {
        let renderComponent = self.renderComponent

        switch animationState {
        case .goToPoint(let point):
            let moveToPointAction = SKAction.move(to: point, duration: 1.2)
            renderComponent.recordNode.run(moveToPointAction)
        }
    }
}
