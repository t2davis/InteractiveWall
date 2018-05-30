//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit


class RecordNode: SKNode {

    private let record: RecordDisplayable


    private struct Constants {
        static let borderCornerRadius: CGFloat = 0.3
        static let centerOffset: CGFloat = 0.2
        static let labelFontSize: CGFloat = 13
    }


    // MARK: Initializers

    init(record: RecordDisplayable) {
        self.record = record
        super.init()
        makeRecordNode()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    // MARK: API

    func runAnimations() {

    }

    func createInitialAnimation(delay: Int) -> SKAction {
        let delayAction = SKAction.wait(forDuration: TimeInterval(delay) * 2)
        let fadeInAction = SKAction.fadeIn(withDuration: 0.5)
        let moveToCenterAction = SKAction.move(to: CGPoint(x: 10, y: 10), duration: 1)

        let impulse = SKAction.applyImpulse(CGVector(dx: 10, dy: 10), duration: 1)

        let actionSequence = SKAction.sequence([delayAction, fadeInAction, moveToCenterAction, impulse])
        return actionSequence
    }



    // MARK: Helpers

    private func makeRecordNode() {
        let rootNode = makeRootNode()

        addTitleLabelNode(to: rootNode)
        addIdLabelNode(to: rootNode)

        physicsBody = SKPhysicsBody(rectangleOf: calculateAccumulatedFrame().size)
//        physicsBody?.affectedByGravity = false
        physicsBody?.restitution = 1
        physicsBody?.linearDamping = 0
        physicsBody?.friction = 0
    }

    private func makeRootNode() -> SKNode {
        let rootNode = SKSpriteNode()
        rootNode.size = CGSize(width: 50, height: 50)
        rootNode.color = record.type.color
        addChild(rootNode)
        return rootNode
    }

    private func addTitleLabelNode(to root: SKNode) {
        let title = SKLabelNode(text: record.title)
        title.verticalAlignmentMode = .center
        title.horizontalAlignmentMode = .center
        title.position.y = root.frame.height / 2 * Constants.centerOffset
        title.fontSize = Constants.labelFontSize
        title.xScale = root.frame.width / title.frame.width
        title.yScale = title.xScale
        root.addChild(title)
    }

    private func addIdLabelNode(to root: SKNode) {
        let id = SKLabelNode()
        id.text = String(record.id)
        id.verticalAlignmentMode = .center
        id.horizontalAlignmentMode = .center
        id.position.y = -(root.frame.height / 2 * Constants.centerOffset)
        id.fontSize = Constants.labelFontSize
        root.addChild(id)
    }




}









