//
//  ImageRecognizerPresenter.swift
//  ImageRecognizeApp
//
//  Created by Developer on 26.12.2021.
//

import Foundation

protocol ImageRecognizerPresenterProtocol {
    func addRequestData(model: RequestModel, endpoint: ImageRecognizeEndpoint)
}

class ImageRecognizerPresenter {
    weak var view: ImageRecognizViewController?
    var endpoint: ImageRecognizeEndpoint?

    var requestModel: RequestModel?
    
    init(view: ImageRecognizViewController) {
        self.view = view
    }
    
    private func uploadModel(request: URLRequest, body: Data, completion: @escaping ((ResponseModel?, Error?) -> Void)) {
        let session = URLSession.shared
        
        session.uploadTask(with: request, from: body, completionHandler: { responseData, response, error in
            guard let responseData = responseData else {
                completion(nil, error)
                return
            }
            
            do {
                let responseDict = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any]
                
                if let message = responseDict?["message"] as? String,
                   let data = responseDict?["data"] as? [String : Any] {
                    let responseModel = ResponseModel(message: message,
                                                      data: data)
                    completion(responseModel, nil)
                } else {
                    completion(nil, .none)
                }
            } catch {
                completion(nil, error)
            }
        }).resume()
    }
}

// MARK: - ImageRecognizerPresenterProtocol
extension ImageRecognizerPresenter: ImageRecognizerPresenterProtocol {
    func addRequestData(model: RequestModel, endpoint: ImageRecognizeEndpoint) {
        self.requestModel = model
        self.endpoint = endpoint
        
        guard let request = self.endpoint?.createRequest(model) else { return }
        self.uploadModel(request: request.request, body: request.body, completion: { responseModel, error in
            if let responseModel = responseModel {
                self.view?.setupDate(responseModel, image: model.image)
            } else {
                self.view?.showError(error)
            }
        })
    }
}
