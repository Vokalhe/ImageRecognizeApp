//
//  ImageRecognizeEndpoint.swift
//  ImageRecognizeApp
//
//  Created by Developer on 23.12.2021.
//

import Foundation
import UIKit

enum ImageRecognizeEndpoint: CaseIterable {
    case loadCelebrities
    case loadObjects
    case loadText
    
    var rawValue: String {
        switch self {
        case .loadCelebrities: return "Celebrities"
        case .loadObjects: return "Objects"
        case .loadText: return "Extract text"
        }
    }
}

extension ImageRecognizeEndpoint {
    
    func createRequest(_ model: RequestModel) -> (request: URLRequest, body: Data) {
        let url = URL(string: "https://imagerecognize.com/api/v2/")
        let boundary = "------WebKitFormBoundary38Nh2PBHpWDuAlHp"
        
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"apikey\"".data(using: .utf8)!)
        data.append("\r\n\r\nlocal".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"type\"".data(using: .utf8)!)
        
        switch self {
        case .loadCelebrities: data.append("\r\n\r\ncelebrities".data(using: .utf8)!)
        case .loadObjects: data.append("\r\n\r\nobjects".data(using: .utf8)!)
        case .loadText: data.append("\r\n\r\ndetect_text".data(using: .utf8)!)
        }
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=file; filename=\"\(model.filename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        
        // MARK: - TEST
        /*
         var imageString = ""
         
         
         switch self {
         case .loadCelebrities: imageString = "brad_pitt"
         case .loadObjects: imageString = "objects"
         case .loadText: imageString = "text"
         }
         if let image = UIImage(named: imageString),
         let imageData = image.pngData() {
         data.append(imageData)
         }
         */

        // MARK: - Release
        if let imageData = model.image.pngData() {
            data.append(imageData)
        }
        
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        return (urlRequest, data)
    }
}
