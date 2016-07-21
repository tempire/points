// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS)
  import UIKit.UIImage
  typealias Image = UIImage
#elseif os(OSX)
  import AppKit.NSImage
  typealias Image = NSImage
#endif

enum Asset: String {
  case Glyphicons_174_Play = "glyphicons-174-play"
  case Glyphicons_175_Pause = "glyphicons-175-pause"
  case Glyphicons_44_Group = "glyphicons-44-group"
  case Glyphicons_646_Police = "glyphicons-646-police"

  var image: Image {
    return Image(asset: self)
  }
}

extension Image {
  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
