// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

#if os(iOS)
  import UIKit.UIImage
  typealias Image = UIImage
#elseif os(OSX)
  import AppKit.NSImage
  typealias Image = NSImage
#endif

enum Asset: String {
  case _889_Sort_Descending_Selected = "889-sort-descending-selected"
  case Glyphicons_174_Play = "glyphicons-174-play"
  case Glyphicons_175_Pause = "glyphicons-175-pause"
  case Glyphicons_193_Remove_Sign = "glyphicons-193-remove-sign"
  case Glyphicons_44_Group = "glyphicons-44-group"
  case Glyphicons_646_Police = "glyphicons-646-police"
  case Icon_Error = "icon-error"
  case Icon_Info = "icon-info"
  case Icon_Success = "icon-success"
  case Partner_Group = "partner group"
  case Partner = "partner"

  var image: Image {
    return Image(asset: self)
  }
}

extension Image {
  convenience init!(asset: Asset) {
    self.init(named: asset.rawValue)
  }
}
