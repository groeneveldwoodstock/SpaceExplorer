//
//  GameScene.swift


import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    var viewController: GameViewController!
    var explosion: SKEmitterNode!
    var starfall: SKEmitterNode!
    var spaceship: SKSpriteNode!
    var score: Int = 0
    var scoreLabel: SKLabelNode!
    var worlds: Int = 0
    var worldsLabel: SKLabelNode!
    var lives: Int = 3
    var livesLabel: SKLabelNode!
    var coinsCollected: Int = 0
    var rocketMagazine: Int = 10
    var rocketsLabel: SKLabelNode!
    var bottomBorder: SKSpriteNode!
    var ufosMissed: Int = 0

    var ufoTimer: Timer?
    var rocketTimer: Timer?
    var coinTimer: Timer?
    var rocketBoxTimer: Timer?

    let ufoCategory: UInt32 = 0x1 << 0
    let rocketCategory: UInt32 = 0x1 << 1
    let spaceshipCategory: UInt32 = 0x1 << 2
    let coinCategory: UInt32 = 0x1 << 3
    let rocketBoxCategory: UInt32 = 0x1 << 4
    let bottomBorderCategory: UInt32 = 0x1 << 5

    var backgroundMusic: SKAudioNode!
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    
    //Spaceship Controls
    @objc func swipeRight(sender: UISwipeGestureRecognizer) {
        if spaceship.position.x < 270{
            spaceship.position = CGPoint(x: (spaceship.position.x ) + 120, y: -self.frame.size.height/2 + 300)
        }
    }
    @objc func swipeLeft(sender: UISwipeGestureRecognizer) {
        if spaceship.position.x > -270{
            spaceship.position = CGPoint(x: (spaceship.position.x ) - 120, y: -self.frame.size.height/2 + 300)
        }
    }
    
    @objc func swipeUp(sender: UISwipeGestureRecognizer) {
        if(lives > 0){
            shootRocket()
        }
    }
    
    override func didMove(to view: SKView) {
        
        let swipeRight = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.swipeRight(sender:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)

        let swipeLeft = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.swipeLeft(sender:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        
        let swipeUp = UISwipeGestureRecognizer(target: self,
            action: #selector(GameScene.swipeUp(sender:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        self.physicsWorld.contactDelegate = self
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressure))
        self.view!.addGestureRecognizer(longPressRecognizer)

        starfall = SKEmitterNode(fileNamed: "Starfall")
        starfall.position = CGPoint(x: 0, y: 700)
        starfall.advanceSimulationTime(10)
        starfall.zPosition = -1
        self.addChild(starfall)

        spaceship = SKSpriteNode(imageNamed: "spaceship")
        spaceship.position = CGPoint(x: 0, y: -self.frame.size.height/2 + 300)
        spaceship.zPosition = 1
        spaceship.size = CGSize(width: 120, height: 220)
        spaceship.physicsBody = SKPhysicsBody(rectangleOf: spaceship.size)
        spaceship.physicsBody?.affectedByGravity = false
        spaceship.physicsBody?.categoryBitMask = spaceshipCategory
        spaceship.physicsBody?.contactTestBitMask = ufoCategory | coinCategory | rocketBoxCategory
        spaceship.physicsBody?.collisionBitMask = 0
        self.addChild(spaceship)

        bottomBorder = childNode(withName: "bottomBorder") as? SKSpriteNode
        bottomBorder.physicsBody?.categoryBitMask = bottomBorderCategory
        bottomBorder.physicsBody?.contactTestBitMask = ufoCategory
        bottomBorder.physicsBody?.collisionBitMask = bottomBorderCategory

        scoreLabel = SKLabelNode(text: "Score: \(score)")
        scoreLabel.position = CGPoint(x:  -self.frame.size.width/2 + 75, y:  self.frame.size.height/2 - 100)
        scoreLabel.fontSize = 48
        scoreLabel.fontName = "Helvetica Neue"
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.addChild(scoreLabel)
        
        worldsLabel = SKLabelNode(text: "Worlds: \(worlds)")
        worldsLabel.position = CGPoint(x:  -self.frame.size.width/2 + 75, y:  self.frame.size.height/2 - 250)
        worldsLabel.fontSize = 30
        worldsLabel.fontName = "Helvetica Neue"
        worldsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.addChild(worldsLabel)

        rocketsLabel = SKLabelNode(text: "🚀 \(rocketMagazine)")
        rocketsLabel.position = CGPoint(x:  -self.frame.size.width/2 + 75, y:  self.frame.size.height/2 - 200)
        rocketsLabel.fontSize = 48
        rocketsLabel.fontName = "Helvetica Neue"
        rocketsLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.addChild(rocketsLabel)

        livesLabel = childNode(withName: "livesLabel") as? SKLabelNode
        livesLabel.position = CGPoint(x:  self.frame.size.width/2 - 190, y:  self.frame.size.height/2 - 110)
        livesLabel.text = "👨‍🚀👨‍🚀👨‍🚀"

        ufoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            self.createUFO()
        })

        coinTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { (timer) in
            self.createCoin()
        })

        rocketBoxTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true, block: { (timer) in
            self.createRocketBox()
        })

        if let musicURL = Bundle.main.url(forResource: "background", withExtension: "wav") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }

    func createUFO(){
        let ufo = SKSpriteNode(imageNamed: "ufo")
        ufo.size = CGSize(width: 100, height: 50)
        ufo.physicsBody = SKPhysicsBody(rectangleOf: ufo.size)

        ufo.physicsBody?.affectedByGravity = false
        ufo.physicsBody?.isDynamic = true

        ufo.physicsBody?.categoryBitMask = ufoCategory
        ufo.physicsBody?.contactTestBitMask = rocketCategory | spaceshipCategory | bottomBorderCategory
        ufo.physicsBody?.collisionBitMask = 0

        ufo.name = "ufoNode"

        self.addChild(ufo)

        let minX = -size.width/2 + ufo.size.width
        let maxX = size.width/2 - ufo.size.width
        let range = maxX - minX
        let randomUfoX = maxX - CGFloat.random(in: 0 ..< range)

        ufo.position = CGPoint(x: randomUfoX, y: size.height / 2 + ufo.size.height / 2)

        let flyDown = SKAction.moveBy(x: 0, y: -size.height - ufo.size.height, duration: 4)
        let moveUFO = SKAction.sequence([flyDown, SKAction.removeFromParent()])

        ufo.run(moveUFO)
    }

    func createCoin() {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.size = CGSize(width: 70, height: 70)
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)

        coin.physicsBody?.affectedByGravity = false
        coin.physicsBody?.isDynamic = true

        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = rocketCategory | spaceshipCategory
        coin.physicsBody?.collisionBitMask = 0

        coin.name = "coinNode"

        self.addChild(coin)

        let minX = -size.width/2 + coin.size.width
        let maxX = size.width/2 - coin.size.width
        let range = maxX - minX
        let randomCoinX = maxX - CGFloat.random(in: 0 ..< range)

        coin.position = CGPoint(x: randomCoinX, y: size.height / 2 + coin.size.height / 2)

        let flyDown = SKAction.moveBy(x: 0, y: -size.height - coin.size.height, duration: 4)
        let moveCoin = SKAction.sequence([flyDown, SKAction.removeFromParent()])

        coin.run(moveCoin)
    }

    func createRocketBox() {
        let rocketBox: SKSpriteNode!
        switch ufosMissed {
        case -10..<3:
            rocketBox = SKSpriteNode(imageNamed: "bronze-box")
            rocketBox.name = "bronzeBox"
            break
        case 3..<6:
            rocketBox = SKSpriteNode(imageNamed: "silver-box")
            rocketBox.name = "silverBox"
            break
        case 6..<10:
            rocketBox = SKSpriteNode(imageNamed: "gold-box")
            rocketBox.name = "goldBox"
            break
        default:
            rocketBox = SKSpriteNode(imageNamed: "silver-box")
            rocketBox.name = "silverBox"
            break
        }

        rocketBox.size = CGSize(width: 70, height: 70)
        rocketBox.physicsBody = SKPhysicsBody(rectangleOf: rocketBox.size)

        rocketBox.physicsBody?.affectedByGravity = false
        rocketBox.physicsBody?.isDynamic = true

        rocketBox.physicsBody?.categoryBitMask = rocketBoxCategory
        rocketBox.physicsBody?.contactTestBitMask = rocketCategory | spaceshipCategory
        rocketBox.physicsBody?.collisionBitMask = 0

        self.addChild(rocketBox)

        let minX = -size.width/2 + rocketBox.size.width
        let maxX = size.width/2 - rocketBox.size.width
        let range = maxX - minX
        let randomRocketBoxX = maxX - CGFloat.random(in: 0 ..< range)

        rocketBox.position = CGPoint(x: randomRocketBoxX, y: size.height / 2 + rocketBox.size.height / 2)

        let flyDown = SKAction.moveBy(x: 0, y: -size.height - rocketBox.size.height, duration: 4)
        let moveRocketBox = SKAction.sequence([flyDown, SKAction.removeFromParent()])

        rocketBox.run(moveRocketBox)
    }

    func shootRocket() {
        if rocketMagazine > 0 {
            self.run(SKAction.playSoundFileNamed("shot.wav", waitForCompletion: false))
            let rocket = SKSpriteNode(imageNamed: "rocket")
            rocket.size = CGSize(width: 7, height: 40)
            rocket.position = spaceship.position
            rocket.zPosition = 0

            rocket.physicsBody = SKPhysicsBody(rectangleOf: rocket.size)
            rocket.physicsBody?.affectedByGravity = false
            rocket.physicsBody?.isDynamic = false

            rocket.physicsBody?.categoryBitMask = rocketCategory
            rocket.physicsBody?.contactTestBitMask = ufoCategory

            self.addChild(rocket)

            let flyUP = SKAction.move(to: CGPoint(x: spaceship.position.x, y: self.frame.size.height+50), duration: 1)
            let moveRocket = SKAction.sequence([flyUP, SKAction.removeFromParent()])

            rocket.run(moveRocket)
            
            rocketMagazine -= 1
            rocketsLabel.text = "🚀 \(rocketMagazine)"
        }
    }

    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == ufoCategory && contact.bodyB.categoryBitMask == rocketCategory {
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            updateScore()
            saveHighScore()
            updateDifficulty()
        } else if contact.bodyA.categoryBitMask == rocketCategory && contact.bodyB.categoryBitMask == ufoCategory {
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            updateScore()
            saveHighScore()
            updateDifficulty()
        } else if contact.bodyA.categoryBitMask == ufoCategory && contact.bodyB.categoryBitMask == spaceshipCategory {
            contact.bodyA.node?.removeFromParent()
            handleSpaceshipCollision()
        } else if contact.bodyA.categoryBitMask == spaceshipCategory && contact.bodyB.categoryBitMask == ufoCategory {
            contact.bodyB.node?.removeFromParent()
            handleSpaceshipCollision()
        } else if contact.bodyA.categoryBitMask == spaceshipCategory && contact.bodyB.categoryBitMask == coinCategory {
            coinsCollected += 1
            updateScore()
            saveHighScore()
            updateWorlds()
            contact.bodyB.node?.removeFromParent()
        } else if contact.bodyA.categoryBitMask == coinCategory && contact.bodyB.categoryBitMask == spaceshipCategory {
            coinsCollected += 1
            updateScore()
            saveHighScore()
            updateWorlds()
            contact.bodyA.node?.removeFromParent()
        } else if contact.bodyA.categoryBitMask == rocketBoxCategory && contact.bodyB.categoryBitMask == spaceshipCategory {
            updateRocketMagazine(nodeName: (contact.bodyA.node?.name)!)
            contact.bodyA.node?.removeFromParent()
            ufosMissed -= 1
        } else if contact.bodyA.categoryBitMask == spaceshipCategory && contact.bodyB.categoryBitMask == rocketBoxCategory {
            updateRocketMagazine(nodeName: (contact.bodyB.node?.name)!)
            contact.bodyB.node?.removeFromParent()
            ufosMissed -= 1
        } else if contact.bodyA.categoryBitMask == bottomBorderCategory && contact.bodyB.categoryBitMask == ufoCategory {
            ufosMissed += 1
        } else if contact.bodyA.categoryBitMask == ufoCategory && contact.bodyB.categoryBitMask == bottomBorderCategory {
            ufosMissed += 1
        }
    }

    private func updateRocketMagazine(nodeName box: String) {
        switch box {
        case "bronzeBox":
            rocketMagazine += 15
        case "silverBox":
            rocketMagazine += 10
        case "goldBox":
            lives += 1
            var livesLeft = ""
            if(lives > 0){
                for _ in 1...lives {
                    livesLeft += "👨‍🚀"
                }
            }
            livesLabel.text = livesLeft
        default:
            rocketMagazine += 5
        }
        rocketsLabel.text = "🚀 \(rocketMagazine)"
        ufosMissed = 0
    }

    private func updateScore() {
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
    
    private func updateWorlds() {
        worlds += 1
        worldsLabel.text = "Worlds: \(worlds)"
    }

    private func updateDifficulty() {
        if score > 30{
            updateUfoTimer(newTimeInterval: 0.5)
        } else if score > 50 {
            updateUfoTimer(newTimeInterval: 0.25)
        } else if score > 70 {
            updateUfoTimer(newTimeInterval: 0.15)
        } else if score > 90 {
            updateUfoTimer(newTimeInterval: 0.1)
        } else if score > 110 {
            updateUfoTimer(newTimeInterval: 0.05)
        }
    }

    private func updateUfoTimer(newTimeInterval: Double) {
        ufoTimer?.invalidate()
        ufoTimer = Timer.scheduledTimer(withTimeInterval: newTimeInterval, repeats: true, block: { (timer) in
            self.createUFO()
        })
    }

    private func handleSpaceshipCollision() {
        lives -= 1
        var livesLeft = ""
        if(lives > 0){
            self.run(SKAction.playSoundFileNamed("crush.wav", waitForCompletion: false))
            for _ in 1...lives {
                livesLeft += "👨‍🚀"
            }
        } else {
            self.run(SKAction.playSoundFileNamed("collision.wav", waitForCompletion: false))
            backgroundMusic.run(SKAction.stop())
            self.backgroundMusic.removeFromParent()
            saveCoins()
            explodeSpaceship()
            rocketBoxTimer?.invalidate()
            coinTimer?.invalidate()
            ufoTimer?.invalidate()
            _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
                self.isPaused = true
                self.viewController.gameOver()
            }
        }
        livesLabel.text = livesLeft
    }

    private func saveCoins() {
        var coins = UserDefaults.standard.integer(forKey: "coins")
        coins += coinsCollected
        UserDefaults.standard.set(coins, forKey: "coins")
    }
    private func saveHighScore() {
        var highscore = UserDefaults.standard.integer(forKey: "high")
        if score > highscore{
            highscore = score
        }
        UserDefaults.standard.set(highscore, forKey: "high")
    }

    private func explodeSpaceship() {
        self.run(SKAction.playSoundFileNamed("crush.wav", waitForCompletion: false))
        explosion = SKEmitterNode(fileNamed: "Explosion")
        explosion.position = spaceship.position
        explosion.advanceSimulationTime(25)
        explosion.zPosition = 5
        explosion.particleBirthRate = 0
        self.addChild(explosion)
        _ = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { (timer) in
            self.spaceship.removeFromParent()
        }
    }

    @objc func handleLongPressure(sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.began {
            rocketTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true, block: { (timer) in
                self.shootRocket()
            })
        } else if (sender.state == UIGestureRecognizer.State.ended){
            rocketTimer?.invalidate()
        }
    }

    override func didSimulatePhysics() {
        if(lives > 0){
            spaceship.position.x += xAcceleration * 50

            if spaceship.position.x < -self.frame.size.width/2 - 180 {
                spaceship.position = CGPoint(x: self.frame.size.width/2, y: spaceship.position.y)
            }else if spaceship.position.x > self.frame.size.width/2 + 180 {
                spaceship.position = CGPoint(x: -self.frame.size.width/2, y: spaceship.position.y)
            }
        }

    }
}
