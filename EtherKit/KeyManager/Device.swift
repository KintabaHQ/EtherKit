//
//  Device.swift
//  EtherKit
//
//  Created by Cole Potrocky on 8/8/18.
//

import LocalAuthentication

public enum Device {
  public static var hasSecureEnclave: Bool {
    return !isSimulator && hasBiometricSupport
  }

  public static var isSimulator: Bool {
    return TARGET_OS_SIMULATOR == 1
  }

  public static var hasBiometricSupport: Bool {
    var error: NSError?
    var hasBiometricSupport = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    guard error == nil else {
      guard #available(iOS 11, *) else {
        return error?.code != LAError.touchIDNotAvailable.rawValue
      }
      return error?.code != LAError.biometryNotAvailable.rawValue
    }
    return hasBiometricSupport
  }
}
