import Foundation
import EVReflection

class ModelData: EVObject {
    var locId: Int = 0
    var locLat: Double = 0
    var locLon: Double = 0
    var locModelFile: String = ""
    var locModelScale: Float = 1
    var locModelInitialRotX: Float = 0
    var locModelInitialRotY: Float = 0
    var locModelInitialRotZ: Float = 0
    var locModelInitialX: Float = 0
    var locModelInitialY: Float = 0
    var locModelInitialZ: Float = 0
    var locNotes: String = ""
    var locTextureFile: String = ""
    var locTextureFiles: LocTextureFile = LocTextureFile()
}

