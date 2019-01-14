import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    enum ObjectPlacementMode {
        case freeform, plane, image, text
    }
    
    let configuration = ARWorldTrackingConfiguration()
    var objectMode: ObjectPlacementMode = .freeform
    var selectedNode: SCNNode?
    var placedNodes = [SCNNode]()   // ноды
    var planeNodes = [SCNNode]()    // поверхности
    var planes = [Plane]()
    var lastObjectPlacedPoint: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        // sceneView.debugOptions = [.showWorldOrigin, .showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
  
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources",bundle: nil)
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    @IBAction func changeObjectMode(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            objectMode = .freeform
        case 1:
            objectMode = .plane
        case 2:
            objectMode = .image
        case 3:
            objectMode = .text
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showOptions" {
            let optionsViewController = segue.destination as! OptionsContainerViewController
            optionsViewController.delegate = self
        }
    }
}

extension ViewController: OptionsViewControllerDelegate {
    // выбранный объект
    func objectSelected(node: SCNNode) {
        selectedNode = node
        dismiss(animated: true, completion: nil)
    }
    // переключить плоскость визуализации
    func togglePlaneVisualization() {
        dismiss(animated: true, completion: nil)
    }
    // отменить последний объект
    func undoLastObject() {}
    // сбросить сцену
    func resetScene() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Touches
extension ViewController {
    // таб по экрану
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // полоска отладки
        super.touchesBegan(touches, with: event)
        // выброн объект на сцену, таб по экрану
        guard let node = selectedNode, let touch = touches.first  else { return }
        
        switch objectMode {
        case .freeform:
           addNodeInFront(node)
        case .plane:
            let point = touch.location(in: sceneView)
            addNonePlane(node, point: point)
        case .image:
            break
        case .text:
            textAlert(node)
         }
    }
}
// MARK: - Placing methods
extension ViewController {

    func addNodeInFront(_ node: SCNNode) {
        // фигура и объект
        guard let frame = sceneView.session.currentFrame else { return }
        var translation = matrix_identity_float4x4
        
        // универсальный метод  от себя 0.2 м
        translation.columns.3.z = -0.2
        node.simdTransform = matrix_multiply(frame.camera.transform, translation)
        addNodeToSceneRoot(node)
    }
    
    func addNonePlane(_ node: SCNNode, point: CGPoint) {
        // распознать поверхность
        let results = sceneView.hitTest(point, types: [.existingPlaneUsingExtent])
        
        if let match = results.first {
            let position = match.worldTransform.columns.3
            node.position = SCNVector3(position.x,
                                       position.y,
                                       position.z)
            addNodeToSceneRoot(node)
            lastObjectPlacedPoint = point
        }
    }
    
    func addNoneImage(_ node: SCNNode, _ imageAncor: ARImageAnchor) {
        // распознать изображение
        let referenceImage = imageAncor.referenceImage
        let plane = SCNPlane(
            width: referenceImage.physicalSize.width,
            height: referenceImage.physicalSize.height
        )
        plane.firstMaterial?.diffuse.contents =  #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 0.1)

        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity =  0.7 // прозрачность
        planeNode.eulerAngles.x = -.pi / 2
        if objectMode == .image {
            let scene = SCNScene(named: "models.scnassets/pig/pig.scn")
            guard let pigNode = scene?.rootNode.childNode(withName: "Pig", recursively: false ) else { return }
            pigNode.scale = SCNVector3(0.002, 0.002, 0.002)
            node.addChildNode(pigNode)
            node.addChildNode(planeNode)
       } else {
            planeNode.removeFromParentNode()
        }
    }
    // текст
    func addNoneText(_ node: SCNNode, text: String) {
        let textGeometry = SCNText(string: text, extrusionDepth: 1.0)
        textGeometry.firstMaterial?.diffuse.contents = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        let nodeText = SCNNode()
        for node in  sceneView.scene.rootNode.childNodes{
            if node.name != "text" {
                nodeText.geometry = textGeometry
                nodeText.name = "text"
                nodeText.scale = SCNVector3(0.1, 0.1, 0.1)
                nodeText.position = SCNVector3(0, 0, -5)
            } else {
                node.removeFromParentNode()
            }
        }
        addNodeToSceneRoot(nodeText)
    }
    // клонируем и добавляем ноду на сцену
    func addNodeToSceneRoot(_ node: SCNNode) {
        let cloneNode = node.clone()
        sceneView.scene.rootNode.addChildNode(cloneNode)
        placedNodes.append(cloneNode)
    }
    
    // MARK: - Alert methods
    func textAlert(_ node: SCNNode) {
        let alert = UIAlertController(title: "Визуализировать текст",
                                      message: "введите текст",
                                      preferredStyle: .alert) // по центру
        // добавим кнопку и текст
        let alertOkAction = UIAlertAction(title: "OK", style: .default, handler: { action in
            if let textTF = alert.textFields?.first?.text {
                self.addNoneText(node, text: textTF)
            }
        })
        alert.addAction(alertOkAction)
        // текстовое поле
        alert.addTextField { (textTF) in
            //textTF.placeholder = "Пример текста"
            textTF.text = "Пример текста!"
        }
        self.present(alert, animated: true, completion: nil)
    }
}
// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if let anchor = anchor as? ARImageAnchor {
            addNoneImage(node, anchor)
        }
        guard anchor is ARPlaneAnchor,  objectMode == .plane else { return }
        
        let plane = Plane(anchor: anchor as! ARPlaneAnchor)
        self.planes.append(plane)
        node.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        let plane = self.planes.filter { plane in
            return plane.anchor.identifier == anchor.identifier
            }.first
        
        guard plane != nil else { return }
        plane?.update(anchor: anchor as! ARPlaneAnchor)
    }
}
