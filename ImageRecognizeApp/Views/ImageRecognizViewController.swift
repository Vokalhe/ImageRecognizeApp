//
//  ImageRecognizViewController.swift
//  ImageRecognizeApp
//
//  Created by Developer on 23.12.2021.
//

import UIKit
import PhotosUI

protocol ImageRecognizViewControllerProtocol: AnyObject {
    func setupDate(_ model: ResponseModel, image: UIImage)
    func showError(_ error: Error?)
}

class ImageRecognizViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var label: UILabel!
    @IBOutlet var button: UIButton!
    
    var model: ResponseModel?
    var type: ImageRecognizeEndpoint = .loadCelebrities

    var presenter: ImageRecognizerPresenter!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupConnections()
    }

    // MARK: - Private Methods
    private func setupConnections() {
        let presenter = ImageRecognizerPresenter(view: self)
        self.presenter = presenter
    }
    
    private func chooseType() {
        let alert = UIAlertController(title: "Choose type of endpoint",
                                      message: "",
                                      preferredStyle: UIAlertController.Style.alert)
        
        ImageRecognizeEndpoint.allCases.forEach { endpoint in
            alert.addAction(UIAlertAction(title: endpoint.rawValue, style: UIAlertAction.Style.default, handler: { _ in
                self.type = endpoint
                self.openImagePicker()
            }))
        }
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func enabledButton(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.button.isEnabled = enabled
        }
    }
    // MARK: - Actions
    @IBAction func tapLoadImage() {
        self.chooseType()
    }
}

// MARK: - ImageRecognizViewControllerProtocol
extension ImageRecognizViewController: ImageRecognizViewControllerProtocol {
    func setupDate(_ model: ResponseModel, image: UIImage) {
        self.enabledButton(true)
        self.model = model
        
        var textLabel = "Names: "
        let objects = model.data?["objects"] as? [[String : Any]]
        objects?.forEach { object in
            switch self.type {
            case .loadCelebrities, .loadObjects:
                if let name = object["name"] as? String {
                    textLabel += name + "; "
                }
            case .loadText:
                if let name = object["name"] as? String,
                   let text = object["text"] as? String  {
                    textLabel += name + ": " + text + "; "
                }
            }
        }
        
        let alert = UIAlertController(title: model.message,
                                      message: "",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))

        DispatchQueue.main.async {
            self.imageView.image = image
            self.label.text = textLabel
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showError(_ error: Error?) {
        self.enabledButton(true)
        let alert = UIAlertController(title: "Error",
                                      message: error?.localizedDescription,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}

// MARK: - Image Pickers
extension ImageRecognizViewController {
    private func openImagePicker() {
        if #available(iOS 14, *) {
            var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            config.filter = .images // filter only to images
            config.selectionLimit = 1 // ignore limit
            
            let pickerViewController = PHPickerViewController(configuration: config)
            pickerViewController.delegate = self
            
            DispatchQueue.main.async { [weak self] in
                self?.present(pickerViewController, animated: true, completion: nil)
            }
        } else {
            guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) else { return }
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = ["public.image"]
            imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
            
            DispatchQueue.main.async { [weak self] in
                self?.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    
}

extension ImageRecognizViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - UIImagePickerControllerDelegat
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        var urlOptional: URL?
        
        if #available(iOS 11.0, *) {
            guard let urlTemp = info[.imageURL] as? URL else { return }
            urlOptional = urlTemp
        } else {
            guard let urlTemp = info[.mediaURL] as? URL else { return }
            urlOptional = urlTemp
        }

        guard let url = urlOptional else { return }
        
        self.enabledButton(false)
        self.presenter.addRequestData(model: RequestModel(image: image, url: url, filename: url.lastPathComponent), endpoint: self.type)
        
        DispatchQueue.main.async { [weak self] in
            self?.dismiss(animated: true)
        }
    }
}

extension ImageRecognizViewController: PHPickerViewControllerDelegate {
    // MARK: - PHPickerViewControllerDelegate
    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard !results.isEmpty else { return }
        var fileModelImage: UIImage?
        var fileModelUrl: URL?

        if let assetId = results.first?.assetIdentifier,
           let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject {
            let group = DispatchGroup()
            let assetResources = PHAssetResource.assetResources(for: asset)
            let fileName: String = assetResources.first!.originalFilename

                        
            group.enter()
            PHImageManager.default().requestImageData(for: asset,
                                                      options: nil) { (imageData, dataUTI, orientation, info) in
                group.leave()
                if let path = info?["PHImageFileURLKey"] as? URL {
                    fileModelUrl = path
                }
                
                if let data = imageData,
                   let image = UIImage(data: data) {
                    fileModelImage = image
                }
            }
            
            group.enter()
            asset.requestContentEditingInput(with: PHContentEditingInputRequestOptions()) { (input, info) in
                group.leave()
                
                if let url = input?.fullSizeImageURL {
                    fileModelUrl = url
                }
            }
            
            group.notify(queue: .main) { [weak self] in
                guard let self = self else { return }

                if let path = fileModelUrl,
                   let image = fileModelImage {
                    self.enabledButton(false)
                    self.presenter.addRequestData(model: RequestModel(image: image, url: path, filename: fileName), endpoint: self.type)
                }
            }
        }
    }
}
