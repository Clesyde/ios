//
//  GetCameraImage.swift
//  SiriIntents
//
//  Created by Robert Trencheny on 2/19/19.
//  Copyright © 2019 Robbie Trencheny. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit
import Shared
import Intents

class GetCameraImageIntentHandler: NSObject, GetCameraImageIntentHandling {
    func resolveCameraID(for intent: GetCameraImageIntent,
                         with completion: @escaping (INStringResolutionResult) -> Void) {
        guard let cameraID = intent.cameraID else {
            completion(.confirmationRequired(with: intent.cameraID))
            return
        }

        if !cameraID.hasPrefix("camera.") {
            completion(.confirmationRequired(with: intent.cameraID))
            return
        }

        completion(.success(with: cameraID))
    }

    func provideCameraIDOptions(for intent: GetCameraImageIntent,
                                with completion: @escaping ([String]?, Error?) -> Void) {
        guard let api = HomeAssistantAPI.authenticatedAPI() else {
            completion(nil, HomeAssistantAPI.APIError.managerNotAvailable)
            return
        }

        api.GetStates().compactMapValues { entity -> String? in
            if entity.Domain == "camera" {
                return entity.ID
            }
            return nil
        }.done { cameraIDs in
            completion(cameraIDs.sorted(), nil)
        }.catch { error in
            completion(nil, error)
        }
    }

    func confirm(intent: GetCameraImageIntent, completion: @escaping (GetCameraImageIntentResponse) -> Void) {
        HomeAssistantAPI.authenticatedAPIPromise.catch { (error) in
            Current.Log.error("Can't get a authenticated API \(error)")
            completion(GetCameraImageIntentResponse(code: .failureConnectivity, userActivity: nil))
            return
        }

        completion(GetCameraImageIntentResponse(code: .ready, userActivity: nil))
    }

    func handle(intent: GetCameraImageIntent, completion: @escaping (GetCameraImageIntentResponse) -> Void) {
        guard let api = HomeAssistantAPI.authenticatedAPI() else {
            completion(GetCameraImageIntentResponse(code: .failureConnectivity, userActivity: nil))
            return
        }

        if let cameraID = intent.cameraID {
            Current.Log.verbose("Getting camera frame for \(cameraID)")

            api.GetCameraImage(cameraEntityID: cameraID).done { frame in
                Current.Log.verbose("Successfully got camera image during shortcut")

                guard let pngData = frame.pngData() else {
                    Current.Log.error("Image data could not be converted to PNG")
                    completion(.failure(error: "Image could not be converted to PNG"))
                    return
                }

                let resp = GetCameraImageIntentResponse(code: .success, userActivity: nil)
                resp.cameraImage = INFile(data: pngData, filename: "\(cameraID)_still.png",
                    typeIdentifier: kUTTypePNG as String)
                resp.cameraID = cameraID
                completion(resp)
            }.catch { error in
                Current.Log.error("Error when getting camera image in shortcut \(error)")
                let resp = GetCameraImageIntentResponse(code: .failure, userActivity: nil)
                resp.error = "Error during api.GetCameraImage: \(error.localizedDescription)"
                completion(resp)
            }

        } else {
            Current.Log.error("Unable to unwrap intent.cameraID")
            let resp = GetCameraImageIntentResponse(code: .failure, userActivity: nil)
            resp.error = "Unable to unwrap intent.cameraID"
            completion(resp)
        }
    }
}
