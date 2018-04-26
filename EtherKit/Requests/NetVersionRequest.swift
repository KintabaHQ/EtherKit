//
//  NetVersionRequest.swift
//  EtherKit
//
//  Created by Cole Potrocky on 4/26/18.
//

public class NetVersionRequest: Request {
  public typealias Parameters = Void
  public typealias Result = Network

  public var method: String {
    return "net_version"
  }
}
