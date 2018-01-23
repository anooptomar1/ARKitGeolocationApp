//
//  LocTextureFile.swift
//  GeoARDJ
//
//  Created by Mac on 7/27/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation
import EVReflection


class LocTextureFile: EVObject {
    
     var file1: String = ""
     var file2: String = ""
     var file3: String = ""
     var file4: String = ""
     var file5: String = ""
    
    func isEmpty() -> Bool {
        return file1 == "" && file2 == "" && file3 == "" && file4 == "" && file5 == ""
    }
    
    func getFilenames() -> [String] {
        var filenames: [String] = []
        if file1 != "" { filenames.append(Utils.getLastPathElementInUrl(url: file1)) }
        if file2 != "" { filenames.append(Utils.getLastPathElementInUrl(url: file2)) }
        if file3 != "" { filenames.append(Utils.getLastPathElementInUrl(url: file3)) }
        if file4 != "" { filenames.append(Utils.getLastPathElementInUrl(url: file4)) }
        if file5 != "" { filenames.append(Utils.getLastPathElementInUrl(url: file5)) }
        
        return filenames
    }
    
    func getUrls() -> [URL] {

        var urls: [URL] = []
        
        if file1 != "" {urls.append(URL( string: file1)!)}
        if file2 != "" {urls.append(URL( string: file2)!)}
        if file3 != "" {urls.append(URL( string: file3)!)}
        if file4 != "" {urls.append(URL( string: file4)!)}
        if file5 != "" {urls.append(URL( string: file5)!)}
        
        return urls
    }
}
