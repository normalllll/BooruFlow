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
                        filePath: args["filePath"] as! String,
                        fileName: args["fileName"] as! String
                ) { (success: BooleanLiteralType) in
                    result(success)
                }
            }
        case .imageIsExist:
            let args = call.arguments as! Dictionary<String, Any>
            result(ImageSaverPlugin.imageIsExist(fileName: args["fileName"] as! String))

        }
    }

    private enum Method: String, CaseIterable & Hashable {
        case saveImage = "saveImage"
        case imageIsExist = "imageIsExist"
    }
    
    


    static func saveImage(filePath: String, fileName: String, completion: ((Bool) -> Void)?) {
        let albumName = "YandeGUI"
        let fileURL = URL(fileURLWithPath: filePath)

        // Check photo library authorization status
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .denied || status == .restricted {
            print("Photo library access denied or restricted.")
            completion?(false)
            return
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    saveImage(filePath: filePath, fileName: fileName, completion: completion)
                } else {
                    print("Photo library access not authorized.")
                    completion?(false)
                }
            }
            return
        }

        // Fetch the album or create it if it doesn't exist
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
                    saveImage(filePath: filePath, fileName: fileName, completion: completion)
                } else {
                    print("Error creating album: \(error?.localizedDescription ?? "unknown error")")
                    completion?(false)
                }
            }
            return
        }

        // Perform the image save action
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.originalFilename = fileName
            print(fileName)
            print(filePath)
            request.addResource(with: .photo, fileURL: fileURL, options: options)

            if let assetPlaceholder = request.placeholderForCreatedAsset, let albumChangeRequest = PHAssetCollectionChangeRequest(for: assetAlbum!) {
                albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
            }
        }) { (isSuccess, error) in
            if isSuccess {
                completion?(true)
            } else {
                print("Error saving image to photo library: \(error?.localizedDescription ?? "unknown error")")
                completion?(false)
            }
        }
    }

    static func imageIsExist(fileName: String) -> Bool {
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
                    if let originalFilename = resource.first?.originalFilename, fileName == originalFilename {
                        exist = true
                        stop.initialize(to: true)
                    }
                }
            }
        }
        return exist
    }

}
