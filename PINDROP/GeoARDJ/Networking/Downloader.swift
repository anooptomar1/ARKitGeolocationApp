//
//  Downloader.swift
//  GeoARDJ
//
//  Created by Mac on 7/27/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation
import Alamofire
import Zip
class Downloader {
    
    
    class func loadAlamoForZip(url: URL, subfolder: String, filename: String, completionHandler: @escaping (Bool) -> Void, failure: @escaping ()->()) {
        var zipFileName:String = ""
        
        let destinationPath: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            
            documentsURL.appendPathComponent(subfolder)
            documentsURL.appendPathComponent(filename + ".zip")
            return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        zipFileName = filename
        
        Alamofire.download(url, to: destinationPath)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
                if progress.isFinished {
                    print ("Download complete")
                    
                    var documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
                    documentsURL = documentsURL.appendingPathComponent(subfolder, isDirectory: true)
                    
                    let zipFileURL:URL = documentsURL.appendingPathComponent(zipFileName + ".zip")
                    //                    documentsURL = documentsURL.appendingPathComponent(zipFileName, isDirectory: true)
                    do {
                        try Zip.unzipFile(zipFileURL, destination: documentsURL, overwrite: true, password: nil)
                        print(documentsURL.absoluteString)
                    }
                    catch let errors {
                        print("Something went wrong" + errors.localizedDescription)
                        failure()
                        return
                    }
                    
                    completionHandler(true)
                }
        }
    }
    
    class func loadAlamo(url: URL, subfolder: String, filename: String, completionHandler: @escaping (Bool) -> Void) {
        
        let destinationPath: DownloadRequest.DownloadFileDestination = { _, _ in
            var documentsURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            
            documentsURL.appendPathComponent(subfolder)
            documentsURL.appendPathComponent(filename)
            return (documentsURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(url, to: destinationPath)
            .downloadProgress { progress in
                print("Download Progress: \(progress.fractionCompleted)")
                if progress.isFinished {
                    print ("Download complete")
                    
                    completionHandler(true)
                }
        }
    }
    
    class func loadList(urls: [URL], subfolder: String, filenames: [String], completionHandler: @escaping (Bool) -> Void) {
        var urlArray = urls
        var filenamesArray = filenames
        if let sUrl = urlArray.popLast(), let filename = filenamesArray.popLast() {
            //let sUrl2 = URL(string: "http://192.168.0.187:8080/Models/scaled_cone.dae")!
            loadAlamo(url: sUrl, subfolder: subfolder, filename: filename, completionHandler: {(flag: Bool) -> Void in
                print("file \(filename) downloaded")
                
                if (filename as NSString).pathExtension == "dae"
                {
                    loadList(urls:urlArray, subfolder: subfolder, filenames: filenamesArray, completionHandler: completionHandler)
                }
                else
                {
                    if (filename as NSString).pathExtension == "zip"
                    {
                        print("ZipFile downloaded.")
                    }
                }
            })
        } else {
            print ("download finished")
            completionHandler(true)
        }
    }
    
}

