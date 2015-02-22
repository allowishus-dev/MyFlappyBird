//
//  GameScene.swift
//  MyFlappyBird
//
//  Created by Bjørn Puggaard on 06/02/15.
//  Copyright (c) 2015 Bjørn Puggaard. All rights reserved.
//

import SpriteKit
import AVFoundation
import Foundation
import SystemConfiguration

class GameScene: SKScene, SKPhysicsContactDelegate {

    var musicPlayer: AVAudioPlayer!
    var coinPlayer: AVAudioPlayer!
    var explodePlayer: AVAudioPlayer!
    
    // global holder for bird sprite, global to detect collisions
    var bird = SKSpriteNode()

    var pointBoard = SKLabelNode()
    var highBoard = SKLabelNode()
    
    var volume = SKSpriteNode()
    var volumeOnTexture = SKTexture(imageNamed: "volumeOn")
    var volumeOffTexture = SKTexture(imageNamed: "volumeOff")
    
    var soundOn = true

    var gameOverLabel = SKLabelNode()
    var gameOverLabel2 = SKLabelNode()

    var highscoreList = SKNode()
    
    var topPipe = SKSpriteNode()
    var bottomPipe = SKSpriteNode()
    
    var movingObjects = SKNode()
    
    var highscoreLabels = SKNode()
    
    // global holder for bird animations, global to be able to change the animation
    var alternateTexture = SKAction()
 
    var point = 0
    var high = 0
    
    var userName = "er"
    
    var collision = false
    
    var showHigh = true

    var stopped = false
    // ???
    let birdGroup:UInt32 = 1
    let objectGroup:UInt32 = 2
    let gapGroup:UInt32 = 0

    func createHighScoreList() {
        var highBackTexture = SKTexture(imageNamed: "highBack.png")
        var highBack = SKSpriteNode(texture: highBackTexture)
        highBack.zPosition = 1
        highBack.setScale(2)
        highBack.position = CGPoint(x: CGRectGetMidX(self.frame), y: CGRectGetMidY(self.frame))
        highscoreLabels.addChild(highBack)
        
        if isConnectedToNetwork() {
            sendPostRequest()
        }
        else {
            createHighScoreLine("[no network]", lineNumber: 4)
        }
    }
    
    // main method
    override func didMoveToView(view: SKView) {
        // set gravity in scene
        self.physicsWorld.gravity = CGVectorMake(0, -5.0)
        
        // ????
        self.physicsWorld.contactDelegate = self
        
        setupSound()
        
        createGround()
        createBackground()
        createForeground()
        createPointBoard()
        createStatus()
        
        addChild(movingObjects)
        
        restartGameScene()
    }
    
    func setupSound() {
        let urlCoin = NSBundle.mainBundle().URLForResource("coin.wav", withExtension: nil)
        var errorCoin: NSError? = nil
        coinPlayer = AVAudioPlayer(contentsOfURL: urlCoin, error: &errorCoin)
        coinPlayer.numberOfLoops = 0
        coinPlayer.prepareToPlay()
        
        let urlExplode = NSBundle.mainBundle().URLForResource("explosion.wav", withExtension: nil)
        var errorExplode: NSError? = nil
        explodePlayer = AVAudioPlayer(contentsOfURL: urlExplode, error: &errorExplode)
        explodePlayer.numberOfLoops = 0
        explodePlayer.prepareToPlay()
        
        playBackgroundMusic("Klungos_Arcade.mp3")
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
                
//                runAction(SKAction.playSoundFileNamed("coin.wav", waitForCompletion: false))
                if soundOn {
                    coinPlayer.play()
                }
         
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
            // if first collision in crash
                
                if soundOn {
                    explodePlayer.play()
                }
            }
        
            alternateTexture = SKAction.animateWithTextures([explodeTexture1, explodeTexture2, explodeTexture3, explodeTexture4, explodeTexture5], timePerFrame: 0.1)
            var repeatAndKill = SKAction.repeatAction(alternateTexture, count: 10)
            bird.runAction(repeatAndKill)
        
            collision = true
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
            if data != nil {
                var responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
                //            println("server says: \(responseString)")
                self.processResponse(responseString!)
            }
        }
    }
    
    func processResponse(data: String){
        var lineArray = data.componentsSeparatedByString("-")
        var lineNumber: CGFloat = 0
        for string:String in lineArray {
            createHighScoreLine(string, lineNumber: lineNumber)
            lineNumber++
        }
    }
    
    func createHighScoreLine(text:String, lineNumber: CGFloat){
        var entries = text.componentsSeparatedByString(",")
        
        var nameLabel = SKLabelNode(fontNamed: "MizuFontAlphabet")
        nameLabel.text=entries.first!
        nameLabel.position = CGPoint(x: CGRectGetMidX(self.frame)-160, y: CGRectGetMidY(self.frame) + 86 - lineNumber * 36)
        nameLabel.zPosition = 2
        nameLabel.horizontalAlignmentMode = .Left
        highscoreLabels.addChild(nameLabel)
        
        var scoreLabel = SKLabelNode(fontNamed: "MizuFontAlphabet")
        scoreLabel.text=entries.last!
        scoreLabel.position = CGPoint(x: CGRectGetMidX(self.frame)+160, y: CGRectGetMidY(self.frame) + 86 - lineNumber * 36)
        scoreLabel.zPosition = 2
        scoreLabel.horizontalAlignmentMode = .Right
        highscoreLabels.addChild(scoreLabel)
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
        
        volume = SKSpriteNode(texture: volumeOnTexture)
//        volume.setScale(1.16)
        volume.position = CGPointMake(self.frame.size.width/2+16, self.frame.size.height/2+358)
        addChild(volume)

    }

    func createStatus(){
        gameOverLabel = SKLabelNode(fontNamed: "MizuFontAlphabet")
        gameOverLabel.text = ""
        gameOverLabel.fontSize = 60
        gameOverLabel.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2+220)
        gameOverLabel.zPosition = 2

        addChild(gameOverLabel)
        
        gameOverLabel2 = SKLabelNode(fontNamed: "MizuFontAlphabet")
        gameOverLabel2.text = ""
        gameOverLabel2.fontSize = 60
        gameOverLabel2.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2+160)
        gameOverLabel2.zPosition = 2
        
        addChild(gameOverLabel2)
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
            
            gameOverLabel.text = "game"
            gameOverLabel2.text = "over"
            
            if (showHigh==true) {
                createHighScoreList()
                
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
//    480 x 752 til 530 x 709
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        var touchPoint = touches.anyObject()?.locationInNode(self)
        var x = touchPoint?.x
        var y = touchPoint?.y
               
        if (x < 555 && x > 505 && y < 760 && y > 716) {
            if soundOn {
                soundOn = false
                musicPlayer.stop()
                volume.texture = volumeOffTexture
            }
            else {
                soundOn = true
                musicPlayer.play()
                volume.texture = volumeOnTexture
            }
        }
        else if (collision == false){

            // ------------ if screen is pressed when on game screen when not crashed ------------
            
            bird.physicsBody?.velocity = CGVectorMake(0, 0)
            bird.physicsBody?.applyImpulse(CGVectorMake(0, 50))
            
        }
        else if (stopped==true){
            
            // ------------ if screen is pressed when on highscore screen ------------
            
            point = 0
            createBird()
            gameOverLabel.text = ""
            gameOverLabel2.text = ""
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
    
    func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0)).takeRetainedValue()
        }
        
        var flags: SCNetworkReachabilityFlags = 0
        if SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) == 0 {
            return false
        }
        
        let isReachable = (flags & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection) ? true : false
    }
}