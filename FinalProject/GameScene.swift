//
//  GameScene.swift
//  FinalProject
//
//  Created by Kierin Noreen, Ian Gioffre on 11/29/20.
//  Copyright © 2020 Kierin Noreen. All rights reserved.
//
import SpriteKit
import GameplayKit

// author credit for background.png: Emmett Zinda
// author credit for skater image: <div>Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
// author credit for cone image: <div>Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
// author credit for garbage image: <div>Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
// author credit for dollar image: <div>Icons made by <a href="https://www.flaticon.com/free-icon/dollar_770062?related_item_id=770045&term=dollar%20bill" title="Good Ware">Good Ware</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
// author credit for city image: <div>Icons made by <a href="https://www.flaticon.com/authors/smalllikeart" title="smalllikeart">smalllikeart</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
// author credit for bird image: <div>Icons made by <a href="https://www.flaticon.com/authors/freepik" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a></div>
enum PhysicsCategory: UInt32 {
    case skater = 1
    case obstacle = 2
    case road = 4
    case money = 8
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var viewControllerOptional: UIViewController?
    
    var skater = SKSpriteNode()
    var background = SKSpriteNode()
    var ground = SKSpriteNode()
    var road = SKSpriteNode()
    var obstacle = SKSpriteNode()
    var backgroundSprite = SKSpriteNode()
    var play = SKLabelNode()
    var money = SKSpriteNode()
    var highScoreLabel = SKLabelNode()
    var highScore = 0 {
        didSet {
            highScoreLabel.text = "High Score: \(highScore)"
        }
    }
    
    var moneyPickupAllowed = true
    var scoreLabel = SKLabelNode()
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }

    var obstacleTimer: Timer?
    var backgroundSpriteTimer: Timer?
    var moneyTimer: Timer?
    var moneyCooldownTimer: Timer?
    
    override func didMove(to view: SKView) {
        self.physicsWorld.contactDelegate = self
        
        setupGame()
    }
    
    func setupGame() {
        setupSprites()
        highScore = 0
        self.isPaused = true
    }
    
    func restartGame() {
        self.removeAllChildren()
        setupSprites()
        play.isHidden = true
        self.isPaused = false
        runMoney()
        runObstacles()
        runBackgroundSprites()
        
    }
    
    func gameOver() {
        self.isPaused = true
        obstacleTimer?.invalidate()
        obstacleTimer = nil
        backgroundSpriteTimer?.invalidate()
        backgroundSpriteTimer = nil
        moneyTimer?.invalidate()
        moneyTimer = nil
        play.isHidden = false
        updateHighScore()
    }
    
    func setupSprites() {
        // background
        background = SKSpriteNode(imageNamed: "background")
        background.size = CGSize(width: self.frame.width, height: self.frame.height)
        background.zPosition = -4
        addChild(background)
        ground = SKSpriteNode(color: .lightGray, size: CGSize(width: self.frame.width, height: self.frame.height / 2 - 100))
        ground.position = CGPoint(x: self.frame.midX, y: self.frame.minY + ground.size.height / 2)
        ground.zPosition = -3
        addChild(ground)
        
        // road (floor)
        //road = SKSpriteNode(imageNamed: "road")
        //road.size = CGSize(width: self.frame.width, height: ROAD_HEIGHT)
        road = SKSpriteNode(color: .darkGray, size: CGSize(width: self.frame.width, height: 150))
        road.position = CGPoint(x: self.frame.midX, y: self.frame.minY + road.size.height / 2)
        road.zPosition = -2
        road.physicsBody = SKPhysicsBody(rectangleOf: road.size)
        road.physicsBody?.isDynamic = false
        road.physicsBody?.categoryBitMask = PhysicsCategory.road.rawValue
        road.physicsBody?.restitution = 0
        addChild(road)
        
        // skater (player)
        skater = SKSpriteNode(imageNamed: "skater")
        skater.size = CGSize(width: 160, height: 180)
        skater.position = CGPoint(x: self.frame.minX + 200, y: road.position.y + (road.size.height / 2) + (skater.size.height / 2))
        skater.physicsBody = SKPhysicsBody(texture: skater.texture!, size: skater.size)
        skater.physicsBody?.categoryBitMask = PhysicsCategory.skater.rawValue
        skater.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle.rawValue | PhysicsCategory.money.rawValue
        skater.physicsBody?.collisionBitMask = PhysicsCategory.road.rawValue
        skater.physicsBody?.restitution = 0
        skater.physicsBody?.allowsRotation = false
        addChild(skater)
        
        // score label
        scoreLabel.fontSize = 50
        scoreLabel.position = CGPoint(x: self.frame.minX + 100, y: self.frame.maxY - 50)
        score = 0
        addChild(scoreLabel)
        
        //highScore Label
        highScoreLabel.fontSize = 50
        highScoreLabel.position = CGPoint(x: self.frame.maxX - 160, y: self.frame.maxY - 50)
        addChild(highScoreLabel)
        
        // play again text
        play.fontSize = 100
        play.fontName = "AvenirNext-Bold"
        play.fontColor = .black
        play.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        play.text = "Tap to Play"
        addChild(play)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if self.isPaused {
            restartGame()
        } else {
            let skaterGroundPosition = road.position.y + (road.size.height / 2) + (skater.size.height / 2) + 5
            if skater.position.y <= skaterGroundPosition {
                skater.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 300))
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("contact")
        if contact.bodyA.categoryBitMask == PhysicsCategory.money.rawValue || contact.bodyB.categoryBitMask == PhysicsCategory.money.rawValue {
            contact.bodyA.categoryBitMask == PhysicsCategory.money.rawValue ? contact.bodyA.node?.removeFromParent() : contact.bodyB.node?.removeFromParent()
            if moneyPickupAllowed {
                score += 1
                moneyPickupAllowed = false
                runMoneyCooldownTimer()
            }
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.obstacle.rawValue || contact.bodyB.categoryBitMask == PhysicsCategory.obstacle.rawValue {
            // obstacle has been contacted by skater
            gameOver()
        }
    }
    
    func addRandomObstacle() {
        // pick random obstacle
        let randNum = arc4random_uniform(3)
        if randNum == 0 {
            obstacle = SKSpriteNode(imageNamed: "bird")
            obstacle.size = CGSize(width: 100, height: 100)
            obstacle.position = CGPoint(x: self.frame.maxX + obstacle.size.width / 2, y: road.position.y + (road.size.height / 2) + (obstacle.size.height / 2) + 300)
        } else if randNum == 1 {
            obstacle = SKSpriteNode(imageNamed: "cone")
            obstacle.size = CGSize(width: 90, height: 90)
            obstacle.position = CGPoint(x: self.frame.maxX + obstacle.size.width / 2, y: road.position.y + (road.size.height / 2) + (obstacle.size.height / 2))
        } else if randNum == 2 {
            obstacle = SKSpriteNode(imageNamed: "garbage")
            obstacle.size = CGSize(width: 100, height: 120)
            obstacle.position = CGPoint(x: self.frame.maxX + obstacle.size.width / 2, y: road.position.y + (road.size.height / 2)  + (obstacle.size.height / 2))
        }
        let moveAction = SKAction.move(to: CGPoint(x: self.frame.minX - obstacle.size.width / 2, y: obstacle.position.y), duration: 3)
        obstacle.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
        obstacle.physicsBody = SKPhysicsBody(texture: obstacle.texture!, size: obstacle.size)
        obstacle.physicsBody?.affectedByGravity = false
        obstacle.physicsBody?.allowsRotation = false
        obstacle.physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        obstacle.physicsBody?.contactTestBitMask = PhysicsCategory.skater.rawValue
        addChild(obstacle)
    }
    
    func runObstacles() {
        obstacleTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
            self.addRandomObstacle()
        })
    }
    
    func addBackgroundSprite() {
        backgroundSprite = SKSpriteNode(imageNamed: "building")
        backgroundSprite.size = CGSize(width: 400, height: 400)
        backgroundSprite.position = CGPoint(x: self.frame.maxX + backgroundSprite.size.width / 2, y: road.position.y + (road.size.height / 2) + (backgroundSprite.size.height / 2) + 50)
        backgroundSprite.zPosition = -1
        let moveAction = SKAction.move(to: CGPoint(x: self.frame.minX - backgroundSprite.size.width / 2, y: backgroundSprite.position.y), duration: 6)
        backgroundSprite.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
        addChild(backgroundSprite)
    }
    
    func runBackgroundSprites() {
        backgroundSpriteTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { (timer) in
            self.addBackgroundSprite()
        })
    }
    
    func addMoney() {
        money = SKSpriteNode(imageNamed: "dollar")
        money.size = CGSize(width: 100, height: 100)
        let randYPosition = arc4random_uniform(400)
        money.position = CGPoint(x: self.frame.maxX + obstacle.size.width / 2, y: road.position.y + (road.size.height / 2) + CGFloat(randYPosition))
        let moveAction = SKAction.move(to: CGPoint(x: self.frame.minX - money.size.width / 2, y: money.position.y), duration: 3)
        money.run(SKAction.sequence([moveAction, SKAction.removeFromParent()]))
        money.physicsBody = SKPhysicsBody(texture: money.texture!, size: money.size)
        money.physicsBody?.affectedByGravity = false
        money.physicsBody?.allowsRotation = false
        money.physicsBody?.categoryBitMask = PhysicsCategory.money.rawValue
        money.physicsBody?.contactTestBitMask = PhysicsCategory.skater.rawValue
        addChild(money)
    }
    
    func runMoney() {
        moneyTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true, block: { (timer) in
            self.addMoney()
        })
    }
    
    func runMoneyCooldownTimer() {
        moneyCooldownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (timer) in
            self.moneyPickupAllowed = true
            self.moneyCooldownTimer?.invalidate()
            self.moneyCooldownTimer = nil
        })
    }
    
    func updateHighScore() {
        if score > highScore {
            self.highScore = score
        }
    }
}
