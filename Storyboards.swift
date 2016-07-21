// Generated using SwiftGen, by O.Halligon — https://github.com/AliSoftware/SwiftGen

import Foundation
import UIKit

protocol StoryboardSceneType {
  static var storyboardName: String { get }
}

extension StoryboardSceneType {
  static func storyboard() -> UIStoryboard {
    return UIStoryboard(name: self.storyboardName, bundle: nil)
  }

  static func initialViewController() -> UIViewController {
    guard let vc = storyboard().instantiateInitialViewController() else {
      fatalError("Failed to instantiate initialViewController for \(self.storyboardName)")
    }
    return vc
  }
}

extension StoryboardSceneType where Self: RawRepresentable, Self.RawValue == String {
  func viewController() -> UIViewController {
    return Self.storyboard().instantiateViewControllerWithIdentifier(self.rawValue)
  }
  static func viewController(identifier: Self) -> UIViewController {
    return identifier.viewController()
  }
}

protocol StoryboardSegueType: RawRepresentable { }

extension UIViewController {
  func performSegue<S: StoryboardSegueType where S.RawValue == String>(segue: S, sender: AnyObject? = nil) {
    performSegueWithIdentifier(segue.rawValue, sender: sender)
  }
}

struct StoryboardScene {
  enum LaunchScreen: StoryboardSceneType {
    static let storyboardName = "LaunchScreen"
  }
  enum Main: String, StoryboardSceneType {
    static let storyboardName = "Main"

    case AdminVCScene = "AdminVC"
    static func instantiateAdminVC() -> AdminVC {
      guard let vc = StoryboardScene.Main.AdminVCScene.viewController() as? AdminVC
      else {
        fatalError("ViewController 'AdminVC' is not of the expected class AdminVC.")
      }
      return vc
    }

    case CompetitorsVCScene = "CompetitorsVC"
    static func instantiateCompetitorsVC() -> CompetitorsVC {
      guard let vc = StoryboardScene.Main.CompetitorsVCScene.viewController() as? CompetitorsVC
      else {
        fatalError("ViewController 'CompetitorsVC' is not of the expected class CompetitorsVC.")
      }
      return vc
    }
  }
}

struct StoryboardSegue {
}
