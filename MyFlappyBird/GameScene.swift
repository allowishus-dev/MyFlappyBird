//
//  GameScene.swift
//  MyFlappyBird
//
//  Created by Bjørn Puggaard on 06/02/15.
//  Copyright (c) 2015 Bjørn Puggaard. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene, SKPhysicsContactDelegate {
    var musicPlayer: AVAudioPlayer!
    
    // global holder for bird sprite, global to detect collisions
    var bird = SKSpriteNode()

    var pointBoard = SKLabelNode()
    var highBoard = SKLabelNode()

    var gameOverLabel = SKLabelNode()
    var highscoreList = SKNode()
    
    var topPipe = SKSpriteNode()
    var bottomPipe = SKSpriteNode()
    
    var movingObjects = SKNode()
    
    var highscoreLabels = SKNode()
    
    // global holder for bird animations, global to be able to change the animation
    var alternateTexture = SKAction()
 
    var point = 0
    var high = 0
    
    var userName = "Bjørn"
    
    var collision = false
    
    var showHigh = true

    var stopped = false
    // ???
    let birdGroup:UInt32 = 1
    let objectGroup:UInt32 = 2
    let gapGroup:UInt32 = 0

    func createHighScoreList() {
        // TODO load high score
        
        
    }
    
    // main method
    override func didMoveToView(view: SKView) {
        // set gravity in scene
        self.physicsWorld.gravity = CGVectorMake(0, -5.0)
        
        // ????
        self.physicsWorld.contactDelegate = self
        
        playBackgroundMusic("Klungos_Arcade.mp3")
        
        createGround()
        createBackground()
        createForeground()
        createPointBoard()
        createStatus()
        
        addChild(movingObjects)
        
        restartGameScene()
    }
    
    func restartGameScene(){
        createBird()
        
        var spawnPipes = SKAction.runBlock { () -> Void in
            self.createPipes()
        }
        
        var sleepAction = SKAction.waitForDuration(3)
        var runAll = SKAction.sequence([spawnPipes, sleepAction])
        var repeatForever = SKAction.repeatActionForever(runAll)
        self.runAction(repeatForever)

    }
    
    func playBackgroundMusic(filename: String) {
        let url = NSBundle.mainBundle().URLForResource(
            filename, withExtension: nil)
        var error: NSError? = nil
        musicPlayer = AVAudioPlayer(contentsOfURL: url, error: &error)
        musicPlayer.numberOfLoops = -1
        musicPlayer.prepareToPlay()
        musicPlayer.play()
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == gapGroup || contact.bodyB.categoryBitMask == gapGroup{
            if collision == false {
                
                runAction(SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false))
                
                point++
                pointBoard.text = String(point)
                if (high < point){
                    high = point
                    highBoard.text = "hi " + String(high)
                }
            }
        }
        else {

            var explodeTexture1 = SKTexture(imageNamed: "explode1.png")
            var explodeTexture2 = SKTexture(imageNamed: "explode2.png")
            var explodeTexture3 = SKTexture(imageNamed: "explode3.png")
            var explodeTexture4 = SKTexture(imageNamed: "explode4.png")
            var explodeTexture5 = SKTexture(imageNamed: "explode5.png")
        
            if collision == false {
            
                // send highscore
                // call sendToServer
                sendPostRequest()
                
                runAction(SKAction.playSoundFileNamed("explosion.wav",
                waitForCompletion: false))
            }
        
            alternateTexture = SKAction.animateWithTextures([explodeTexture1, explodeTexture2, explodeTexture3, explodeTexture4, explodeTexture5], timePerFrame: 0.1)
            var repeatAndKill = SKAction.repeatAction(alternateTexture, count: 10)
            bird.runAction(repeatAndKill)
        
            collision = true
           
            
            
        }
    }
    
    func processResponse(data: String){
        var lineArray=data.componentsSeparatedByString("-")
        var lineNumber: CGFloat = 0
        for string:String in lineArray {
            createHighScoreLine(string, lineNumber: lineNumber)
            lineNumber++
        }
    }
    
    func sendPostRequest() {
        // post doesn't show url in adressbar in a browser
        var URL: NSURL = NSURL(string: "http://www.joneikholm.dk/test/hs_QrwieKBnM842xZPQq.php")!
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "POST"
        var bodyData = "name=\(userName)&score=\(point)"
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding)
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()){
            (response, data, error) in
            var responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
//            println("server says: \(responseString)")
            self.processResponse(responseString!)
            
        }
        
    }
    
    func createHighScoreLine(text:String, lineNumber: CGFloat){
        
        var label = SKLabelNode(fontNamed: "MizuFontAlphabet")
        label.text=text
        label.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame) + 340 - lineNumber * 36)
        label.zPosition = 17
        highscoreLabels.addChild(label)
    }
    
    func createGround(){
        // make ground
        var ground = SKNode()
        // position ground in scene
        ground.position = CGPoint(x: 0, y:0)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: size.width, height: 15))
        ground.physicsBody?.dynamic = false
        ground.physicsBody?.categoryBitMask = objectGroup
        addChild(ground)
        
    }
    
    func createPointBoard(){
        pointBoard = SKLabelNode(fontNamed: "MizuFontAlphabet")
        pointBoard.text = "0"
        pointBoard.fontSize = 36
        pointBoard.position = CGPointMake(self.frame.size.width/2+208, self.frame.size.height/2+350)
        pointBoard.horizontalAlignmentMode = .Right
        addChild(pointBoard)

        highBoard = SKLabelNode(fontNamed: "MizuFontAlphabet")
        highBoard.text = "hi 0"
        highBoard.fontSize = 36
        highBoard.position = CGPointMake(self.frame.size.width/2-208, self.frame.size.height/2+350)
        highBoard.horizontalAlignmentMode = .Left
        addChild(highBoard)

    }

    func createStatus(){
        gameOverLabel = SKLabelNode(fontNamed: "MizuFontAlphabet")
        gameOverLabel.text = ""
        gameOverLabel.fontSize = 60
        gameOverLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2-40)

        addChild(gameOverLabel)
        
//        restart = SKLabelNode(fontNamed: "MizuFontAlphabet")
//        restart.text = ""
//        restart.fontSize = 36
//        restart.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2-10)
//        
//        addChild(restart)
        
    }
    
    func createBackground(){
        var backgroundTexture = SKTexture(imageNamed: "bg.png")
        var background = SKSpriteNode(texture: backgroundTexture)
        background.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2)
        background.size.height = self.frame.height
        background.size.width = self.frame.width
        
        var moveLeft = SKAction.moveByX(-backgroundTexture.size().width, y: 0, duration: 25)
        var moveRight = SKAction.moveByX(backgroundTexture.size().width, y: 0, duration: 0)
        var moveAction = SKAction.sequence([moveLeft, moveRight])
        var repeatForever = SKAction.repeatActionForever(moveAction)
        
        for var i:CGFloat = 0;i<3;i++ {
            background = SKSpriteNode(texture: backgroundTexture)
            background.position = CGPoint(x: size.width/2 + backgroundTexture.size().width * i, y: CGRectGetMidY(self.frame))
            background.size.height = self.frame.size.height
            background.runAction(repeatForever)
            background.zPosition = -1
            addChild(background)
        }
    }
    
    func createPipes(){
        var gapHeight = bird.size.height * 4
        var movementAmount = arc4random() % UInt32(size.height/2)
        
        if (collision == true){
            
            gameOverLabel.text = "game over!"
            
            if (showHigh==true) {
                addChild(highscoreLabels)
                showHigh = false
            }
            
            stopped = true
            
            bird.removeFromParent()
            
            movingObjects.removeAllChildren()
            
        }
        else {
            
            var pipeOffset = CGFloat(movementAmount) - size.height/4
        
            var topPipeTexture = SKTexture(imageNamed: "pipe1.png")
            topPipe = SKSpriteNode(texture: topPipeTexture)
            topPipe.position = CGPoint(x: size.width, y: size.height/2 + topPipe.size.height/2 + gapHeight/2 + pipeOffset)
            topPipe.zPosition = 0
        
            var bottomPipeTexture = SKTexture(imageNamed: "pipe2.png")
            bottomPipe = SKSpriteNode(texture: bottomPipeTexture)
        
            bottomPipe.position = CGPoint(x: size.width, y: size.height/2 - bottomPipe.size.height/2 - gapHeight/2 + pipeOffset)
            bottomPipe.zPosition = 0
        
            // collisions
            topPipe.physicsBody = SKPhysicsBody(rectangleOfSize: topPipe.size)
            topPipe.physicsBody?.categoryBitMask = objectGroup
            topPipe.physicsBody?.dynamic = false
        
            bottomPipe.physicsBody = SKPhysicsBody(rectangleOfSize: bottomPipe.size)
            bottomPipe.physicsBody?.categoryBitMask = objectGroup
            bottomPipe.physicsBody?.dynamic = false
        
            // move pipes
            var movePipes = SKAction.moveByX(-size.width * 2, y: 0, duration: NSTimeInterval(size.width/100))
            var removePipes = SKAction.removeFromParent()
            var moveAndRemove = SKAction.sequence([movePipes, removePipes])
            topPipe.runAction(moveAndRemove)
            bottomPipe.runAction(moveAndRemove)
            
            // make gap
            var gap = SKNode()
            gap.position = CGPoint(x: size.width+topPipe.size.width/2+bird.size.width/2, y: CGRectGetMidY(self.frame) + pipeOffset)
            gap.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 2, height: gapHeight))
            gap.physicsBody?.dynamic=false
            gap.physicsBody?.categoryBitMask=gapGroup
            gap.physicsBody?.contactTestBitMask=birdGroup
            gap.runAction(moveAndRemove)
            
            movingObjects.addChild(gap)
            
            movingObjects.addChild(topPipe)
            movingObjects.addChild(bottomPipe)
        }
    }

    func createForeground(){
        var foregroundTexture = SKTexture(imageNamed: "foreground2.png")
        var foreground = SKSpriteNode(texture: foregroundTexture)
//        foreground.position = CGPointMake(self.frame.size.width/2, self.frame.size.height + 100)
//        foreground.size.height = self.frame.height
//        foreground.size.width = self.frame.width
        var moveLeft = SKAction.moveByX(-foregroundTexture.size().width, y: 0, duration: 2)
        var moveRight = SKAction.moveByX(foregroundTexture.size().width, y: 0, duration: 0)
        var moveAction = SKAction.sequence([moveLeft, moveRight])
        var repeatForever = SKAction.repeatActionForever(moveAction)
        
        for var i:CGFloat = 0;i<3;i++ {
            foreground = SKSpriteNode(texture: foregroundTexture)
            foreground.position = CGPoint(x: size.width/2 + foregroundTexture.size().width * i, y: foregroundTexture.size().height/2)
//            foreground.size.height = self.frame.size.height
            foreground.runAction(repeatForever)
            foreground.zPosition = 2
            addChild(foreground)
        }
    }
    
    func createBird() {
        var birdTexture1 = SKTexture(imageNamed: "flappy1.png")
        var birdTexture2 = SKTexture(imageNamed: "flappy2.png")
        bird = SKSpriteNode(texture: birdTexture1)
        alternateTexture = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.1)
        var repeatForever = SKAction.repeatActionForever(alternateTexture)
        bird.position = CGPointMake(self.frame.size.width/2 - 100, self.frame.size.height/2)
        bird.runAction(repeatForever)
        bird.zPosition = 1 // put bird on second top layer
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        bird.physicsBody?.categoryBitMask = birdGroup
        bird.physicsBody?.contactTestBitMask = objectGroup
        bird.physicsBody?.allowsRotation = false
        
        addChild(bird)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if (collision == false){
            bird.physicsBody?.velocity = CGVectorMake(0, 0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0, 50))
            
        }
        else if (stopped==true){
            point = 0
            createBird()
            gameOverLabel.text = ""
//            restart.text = ""
            stopped = false
            collision = false
            pointBoard.text = "0"
            
            // remove highscore labels
            showHigh = true
            highscoreLabels.removeAllChildren()
            highscoreLabels.removeFromParent()
            
            
        }
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
