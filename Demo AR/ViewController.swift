//
//  ViewController.swift
//  Demo AR
//
//  Created by Jason Nguyen on 2/10/21.
//

import RealityKit
import ARKit
import UIKit

/// The main class that handles the AR session and adding and removing objects
class ViewController: UIViewController {
    
    //ARView handles the the AR experience
    //IBOutlet is inserted when storyboard is connected to code
    @IBOutlet var arView: ARView!

    
    /// Initializes the AR session and adds gestures for tap and long press
    override func viewDidLoad(){
        
        /*Calling super on viewDidLoad is good practice for overriding functions with
        return value
        */
        super.viewDidLoad()
        
        //Creates a new arView sessions and sets session.delegate to self
        let session = arView.session
        session.delegate = self
        
        //Calls setupARView to set up the ARView
        setupARView()
        
        //Adds a Gesture Recognizer for a tap
        arView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showTap(recognizer:))))
        
        //Adds a Gesture Recognizer for a Long Press
        arView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleHold(recognizer:))))
        
    }
    
    
    /// Sets up the AR View's configuration and runs the arView session with that configuration
    func setupARView(){
        
        //Disables default arView configuration
        arView.automaticallyConfigureSession = false
        
        //Sets configuration constnat to an ARWorldTrackingConfiguration
        let configuration = ARWorldTrackingConfiguration()
        
        //Sets plane detection to both horizontal and vertical
        configuration.planeDetection = [.horizontal, .vertical]
        
        /*Sets environment teturing to automatic, which automatically textures and
         renders the environment
        */
        configuration.environmentTexturing = .automatic
        
        //Runs the session with specficied configuration
        arView.session.run(configuration)
    }
    
    /// Removes the anchor of the entity at the location the user long presses if there is an anchor there
    @objc
    func handleHold(recognizer: UILongPressGestureRecognizer){
        
        //Location is set to where the user long presses
        let location = recognizer.location(in: arView)
        
        /*Checks to see if there is an entity at the location and removes the entity anchor
        from the parent if the entity has an anchor.
        */
        if let entity = arView.entity(at: location){
            if let anchorEntity = entity.anchor{
                anchorEntity.removeFromParent()
            }
        }
    }
    
    /// Adds an anchor if the raycast recognizes a plane at the location where the user taps
    @objc
    func showTap(recognizer: UITapGestureRecognizer){
        
        //Location is set to where the user taps
        let location = recognizer.location(in: arView)
        
        //Ray starts from where the user taps
        /*Estimated plane is the target that only ARKit can estimate to be a real-world surface
        */
        //The alignment for the raycast is only for the horizontal plane
        let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
        
        //Checks to see if there is a plane returned from the raycast
        //If there is, then an ARAnchor is created and added to the session
        if let firstResult = results.first {
            let anchor = ARAnchor(name: "chess", transform: firstResult.worldTransform)
            arView.session.add(anchor: anchor)
        }
    }
    
    /// Loads the model for the entity, generates collision for the model, and adds gestures for the entity
    /// - Parameters:
    ///   - entityName: name of the entity
    ///   - anchor: the anchor that the entity is going to be spawned on
    func makeEntity(named entityName: String, for anchor: ARAnchor){
        
        /*Loads the model that is associated with the entityName, which should be the chess board currently
        */
        let entity = try! ModelEntity.loadModel(named: entityName)
        
        //Adds collision to the entity in order for gestures to be installed on it
        entity.generateCollisionShapes(recursive: true)
        
        //Adds gestures to the entity that allow for scaling, rotation, and moving
        arView.installGestures(.all, for: entity)
        
        //Calls function that will place the entity on the anchor
        placeEntity(entity)
    }
    
    
    /// Places the model entity by adding it as a child to the anchor and adding the anchor to the scene
    /// - Parameter entity: entity that was created by loading the model
    func placeEntity(_ entity: ModelEntity){
        
        //Sets anchor to the AnchorEntity instance on the horizontal plane
        let anchor = AnchorEntity(plane: .horizontal)
        
        //Adds entity as a child to the anchor and conforms to hasAnchoring property
        anchor.addChild(entity)
        
        //Adds anchor to the arView scene
        arView.scene.addAnchor(anchor)
        
    }
}

/// Places object into the session if an anchor was added to the session
extension ViewController: ARSessionDelegate{
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]){
        for anchor in anchors{
            if let anchorName = anchor.name, anchorName == "chess" {
                makeEntity(named: anchorName, for: anchor)
            }
        }
    }
}
