import Flutter
import UIKit
import Photos

public class ImageSaverPlugin: NSObject, FlutterPlugin {
    private static let pluginName = "io.github.normalllll.yandegui/image_saver"




    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: pluginName, binaryMessenger: registrar.messenger())
        let instance = ImageSaverPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

        guard let method = Method(rawValue: call.method) else {
            return result(FlutterMethodNotImplemented)
        }

        switch (method) {
        case .saveImage:
            let args = call.arguments as! Dictionary<String, Any>
            DispatchQueue.global(qos: .userInitiated).async {
                ImageSaverPlugin.saveImage(
                        imageBytes: (args["imageBytes"] as! FlutterStandardTypedData).data,
                        filename: args["filename"] as! String
                ) { (success: BooleanLiteralType) in
                    result(success)
                }
            }
        case .imageIsExist:
            let args = call.arguments as! Dictionary<String, Any>
            result(ImageSaverPlugin.imageIsExist(filename: args["filename"] as! String))

        }
    }

    private enum Method: String, CaseIterable & Hashable {
        case saveImage = "saveImage"
        case imageIsExist = "imageIsExist"
    }
    
    


    static func saveImage(imageBytes: Data, filename: String, completion: ((Bool) -> Void)?) {
        let albumName = "YandeGUI"

        // Check photo library authorization status
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .denied || status == .restricted {
            print("Photo library access denied or restricted.")
            completion?(false)
            return
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    saveImage(imageBytes: imageBytes, filename: filename, completion: completion)
                } else {
                    print("Photo library access not authorized.")
                    completion?(false)
                }
            }
            return
        }

        var assetAlbum: PHAssetCollection?
        let list = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        list.enumerateObjects { (album, _, stop) in
            if albumName == album.localizedTitle {
                assetAlbum = album
                stop.initialize(to: true)
            }
        }

        if assetAlbum == nil {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }) { (isSuccess, error) in
                if isSuccess {
                    saveImage(imageBytes: imageBytes, filename: filename, completion: completion)
                } else {
                    print("Error creating album: \(error?.localizedDescription ?? "unknown error")")
                    completion?(false)
                }
            }
            return
        }

        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let createOptions = PHAssetResourceCreationOptions()
            createOptions.originalFilename = filename
            request.addResource(with: .photo, data: imageBytes, options: createOptions)

            if let assetPlaceholder = request.placeholderForCreatedAsset, let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetAlbum!) {
                albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
            }
        }) { (isSuccess, error) in
            if isSuccess {
                completion?(true)
            } else {
                print("Error saving image: \(error?.localizedDescription ?? "unknown error")")
                completion?(false)
            }
        }
    }

    static func imageIsExist(filename: String) -> Bool {
        var exist = false
        var assetAlbum: PHAssetCollection?

        // Check photo library authorization status
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .denied || status == .restricted {
            print("Photo library access denied or restricted.")
            return false
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus != .authorized {
                    print("Photo library access not authorized.")
                }
            }
            return false
        }

        let list = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        list.enumerateObjects { (album, _, stop) in
            if "YandeGUI" == album.localizedTitle {
                assetAlbum = album
                stop.initialize(to: true)
            }
        }

        if let assetAlbum = assetAlbum {
            let fetchResult = PHAsset.fetchAssets(in: assetAlbum, options: nil)
            if fetchResult.count > 0 {
                fetchResult.enumerateObjects { (asset, _, stop) in
                    let resource = PHAssetResource.assetResources(for: asset)
                    if let originalFilename = resource.first?.originalFilename, filename == originalFilename {
                        exist = true
                        stop.initialize(to: true)
                    }
                }
            }
        }
        return exist
    }

}
