//
//  BeachScene.swift
//  PresentationDemo
//
//  Created by Alejandro Ferrero on 12/6/17.
//  Copyright © 2017 Alejandro Ferrero. All rights reserved.
//

import Foundation
import SpriteKit

class BeachScene: SKScene, SKPhysicsContactDelegate {
    
    private var beach: SKSpriteNode!
    private var knight: SKSpriteNode!
    private var countdown: SKLabelNode!
    private var scoreLabel: SKLabelNode!
    private var score = 0
    private var count = 3
    private var gameStarted = false
    private var fingerOnKnight = false
    private var touchLocation: CGPoint!
    private var lastTouch: CGPoint? = nil
    private var translation: CGPoint!
    
    
    private final let knightCategory: UInt32 = 0x1 << 0
    private final let ballCategory: UInt32 = 0x1 << 1
    
    override func didMove(to view: SKView) {
        self.size = view.bounds.size
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -2)
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        borderBody.friction = 0
        self.physicsBody = borderBody
        self.physicsWorld.contactDelegate = self
        setupSceneNodes()
        startCountdown()
    }
    
    private func setupSceneNodes() {
        beach = childNode(withName: "beachNode") as! SKSpriteNode
        beach.size.width = (self.scene?.size.width)!
        beach.size.height = (self.scene?.size.height)!
        createKnightNode()
    }
    
    //    MARK: Include Countdown
    private func startCountdown() {
        countdown = SKLabelNode(fontNamed: "Futura")
        countdown.zPosition = 3
        countdown.fontSize = 70
        countdown.fontColor = SKColor.red
        countdown.position = CGPoint(x: self.scene!.frame.midX, y: self.scene!.frame.midY)
        countdown.text = "\(count)"
        addChild(countdown)
        let counterDecrement = SKAction.sequence([SKAction.wait(forDuration: 1.0), SKAction.run(countdownAction)])
        run(SKAction.sequence([SKAction.repeat(counterDecrement, count: 4), SKAction.run(endCountdown)]))
    }
    
    private func countdownAction() {
        if count != 1 {
            count -= 1
            countdown.text = "\(count)"
        } else {
            countdown.text = "TAP!"
        }
    }
    
    private func endCountdown() {
        countdown.removeFromParent()
        let backgroundMusic = SKAction.playSoundFileNamed("beachMusic.mp3", waitForCompletion: true)
        run(SKAction.repeatForever(backgroundMusic))
        scoreLabel = childNode(withName: "score") as! SKLabelNode
        scoreLabel.isHidden = false
        scoreLabel.position = CGPoint(x: 0, y: 0)
        scoreLabel.text = "\(score)"
        gameStarted = true
    }
    
    //    MARK: Create Game Nodes
    
    private func createKnightNode() {
        knight = childNode(withName: "knightNode") as! SKSpriteNode
        knight.position = CGPoint(x: self.scene!.frame.midX, y: self.scene!.frame.midY)
        knight.size = CGSize(width: 150, height: 150)
        knight.physicsBody = SKPhysicsBody(rectangleOf: knight.frame.size)
        knight.physicsBody!.applyImpulse(CGVector(dx: 2.0, dy: -2.0))
        knight.physicsBody?.usesPreciseCollisionDetection = true
        knight.physicsBody?.categoryBitMask = knightCategory
        knight.physicsBody?.collisionBitMask = knightCategory | ballCategory
        knight.physicsBody?.contactTestBitMask = knightCategory | ballCategory

    }
    
    private func releaseBall() {
        run(SKAction.run(createBallNode))
    }
    
    private func createBallNode() {
        let screenWidth = self.frame.size.width
        let ball = SKSpriteNode(imageNamed: "Ball.png")
        ball.zPosition = 2
        ball.position = CGPoint(x: randomBetween(min: -screenWidth/2, max: screenWidth/2), y: self.frame.height/2)
        ball.name = "ballNode"
        ball.physicsBody = SKPhysicsBody(circleOfRadius: (ball.size.width/2))
        ball.physicsBody?.categoryBitMask = ballCategory
        ball.physicsBody?.usesPreciseCollisionDetection = true
        self.addChild(ball)
    }
    
    private func randomBetween(min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat(Float(arc4random()) / Float(UINT32_MAX)) * (max - min) + min
    }
    
    //    MARK: Collision Handling
    
    func didBegin(_ contact: SKPhysicsContact) {
        let secondNode = contact.bodyB.node as! SKSpriteNode
        
        if (contact.bodyA.categoryBitMask == knightCategory) && (contact.bodyB.categoryBitMask == ballCategory) {
            let target_x = secondNode.position.x
            let target_y = secondNode.position.y
            let burstPath = Bundle.main.path(forResource: "BurstParticle", ofType: "sks")
            if burstPath != nil {
                let burstNode = NSKeyedUnarchiver.unarchiveObject(withFile: burstPath!) as! SKEmitterNode
                burstNode.position = CGPoint(x: target_x, y: target_y)
                secondNode.removeFromParent()
                self.addChild(burstNode)
                let sound = SKAction.playSoundFileNamed("burstsound.mp3", waitForCompletion: true)
                run(sound)
                score += 1
                scoreLabel.text = "\(score)"
            }
        }
    }
    
    //    MARK: Screen Taps
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        touchLocation = touch!.location(in: self)
        
        if let body = physicsWorld.body(at: touchLocation) {
            if body.node!.name == knight.name {
                fingerOnKnight = true
            }
        } else if gameStarted {
            releaseBall()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if fingerOnKnight {
            let touch = touches.first
            touchLocation = touch!.location(in: self)
            lastTouch = touch?.previousLocation(in: self)
            translation = CGPoint(x: touchLocation.x - (lastTouch?.x)!, y: touchLocation.y - (lastTouch?.y)!)
            panForTranslation(translation: translation)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fingerOnKnight = false
    }
    
    //    MARK: KnightNode Position Update
    
    private func panForTranslation(translation: CGPoint) {
        let position = knight.position
        knight.position = CGPoint(x: position.x + translation.x, y: position.y + translation.y)
    }
    
    override func update(_ currentTime: TimeInterval) {
        if fingerOnKnight {
            let dt:CGFloat = 1.0/60.0
            let distance = CGVector(dx: touchLocation.x - knight.position.x, dy: touchLocation.y - knight.position.y)
            let velocity = CGVector(dx: distance.dx/dt, dy: distance.dy/dt)
            knight.physicsBody!.velocity=velocity
        }
        
    }
    
}
