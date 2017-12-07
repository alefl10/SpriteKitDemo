//
//  GameScene.swift
//  PresentationDemo
//
//  Created by Alejandro Ferrero on 12/6/17.
//  Copyright © 2017 Alejandro Ferrero. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    private final let fadeIn = SKAction.fadeIn(withDuration: 0.75)
    private final let fadeOut = SKAction.fadeOut(withDuration: 1.5)
    private var startGame = false

    override func didMove(to view: SKView) {
        
        run(SKAction.wait(forDuration: 1.0), completion: {
            let tapLabel = self.childNode(withName: "tapNode")
            tapLabel?.zPosition = 1
            tapLabel?.isHidden = false
            self.startGame = true
            tapLabel?.run(SKAction.repeatForever(SKAction.sequence([self.fadeOut, self.fadeIn])))
        })
    }
    
    override func sceneDidLoad() {
        if let backgroundImg = childNode(withName: "logoNode") {
           backgroundImg.zPosition = 0
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if startGame {
            startGame = false
            run(fadeOut, completion: {
                let transitionEffect = SKTransition.flipHorizontal(withDuration: 1.0)
                let beachScene = BeachScene(fileNamed: "BeachScene")
                self.view?.presentScene(beachScene!, transition: transitionEffect)
            })
        }
    }
    
}
