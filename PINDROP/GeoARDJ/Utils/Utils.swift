//
//  Utils.swift
//  GeoARDJ
//
//  Created by Mac on 7/28/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

class Utils {
    class func distanceSQR(_ aLat: Double, _ aLon: Double, _ bLat: Double, _ bLon: Double) -> Double {
        let xDist = aLat - bLat
        let yDist = aLon - bLon
        return ((xDist * xDist) + (yDist * yDist))
    }
    
    static func isInAreaOf(radius: Double, location: CLLocation, points: [ModelData]) -> ModelData? {
        let curLat = Double(location.coordinate.latitude)
        let curLon = Double(location.coordinate.longitude)
        for point in points {
            let meters = calculateDistanceMeters(coordFromLat: curLat, coordFromLon: curLon, coordToLat: point.locLat, coordToLon: point.locLon)//location.distance(from: pointLoc)
            if meters <= radius { return point }
        }
        
        return nil
    }
    
    static func calculateGeoVector(coordToLat: Double, coordToLon: Double, coordFrom: CLLocation) -> SCNVector3 {
        
        let coordFromLat: Double = coordFrom.coordinate.latitude
        let coordFromLon: Double = coordFrom.coordinate.longitude
        
        print ("coords are coordFromLat:\(coordFromLat) \(coordFromLon) \(coordToLat) \(coordToLon)")
        
        let xSetoff = sign(coordToLon - coordFromLon) * calculateDistanceMeters(coordFromLat: coordToLat, coordFromLon: coordFromLon, coordToLat: coordToLat, coordToLon: coordToLon)
        let zSetoff = sign(coordToLat - coordFromLat) * calculateDistanceMeters(coordFromLat: coordFromLat, coordFromLon: coordToLon, coordToLat: coordToLat, coordToLon: coordToLon)
      
        print ("distance \(calculateDistanceMeters(coordFromLat: coordFromLat, coordFromLon: coordFromLon, coordToLat: coordToLat, coordToLon: coordToLon))")
        
        print ("xS: \(xSetoff) zS: \(zSetoff)")
        
        return SCNVector3(CGFloat(xSetoff), CGFloat(coordFrom.altitude), CGFloat(zSetoff))
    }
    
    static func calculateDistanceMeters(coordFromLat: Double, coordFromLon: Double, coordToLat: Double, coordToLon: Double) -> Double {

        let dlon = degreesToRads(degr: coordToLon - coordFromLon)
        let dlat = degreesToRads(degr: coordToLat - coordFromLat)

        let coordFromLatRad = degreesToRads(degr: coordFromLat)
        let coordToLatRad = degreesToRads(degr: coordToLat)

        let a = pow((sin(dlat/2)), Double(2)) + cos(coordFromLatRad) * cos(coordToLatRad) * pow((sin(dlon/2)), Double(2))
        let cd = 2 * atan2( sqrt(a), sqrt(1-a) )
        return 6373000 * cd

    }
    
    static func degreesToRads(degr: Double) -> Double {
        return (degr * .pi) / 180
    }
    
    static func rotatePositionToNorthOnDir(position: SCNVector3, direction: CLLocationDirection) -> SCNVector3{
        let xMod = position.x * Float(cos(-direction * .pi / 180)) - position.z * Float(sin(-direction * .pi / 180))
        let zMod = position.z * Float(cos(-direction * .pi / 180)) + position.x * Float(sin(-direction * .pi / 180))

        return SCNVector3(x: xMod,y: position.y, z: zMod)
    }
    
    static func getLastPathElementInUrl(url: String) -> String {
        if url == ""{
            return ""
        }
        return url.substring(from: url.index(url.lastIndex(of: "/")!, offsetBy: 1))
    }
    
    static func updatePosition(point: ModelData, location: CLLocation, direction: Double, yOffset: Float, locationModelInitialZ: Float) -> SCNVector3{
        let geoCompensPos = Utils.calculateGeoVector(coordToLat: point.locLat, coordToLon: point.locLon, coordFrom: location)
        let initialCompensPos = SCNVector3(geoCompensPos.x + point.locModelInitialX, geoCompensPos.y + point.locModelInitialY, geoCompensPos.z + locationModelInitialZ - 10)
        var northedPos = Utils.rotatePositionToNorthOnDir(position: initialCompensPos, direction: direction)
        
        northedPos.y = -10.0//yOffset
        print("Model Pos: \(northedPos)")
        return northedPos
    }
}
