//
//  CachingStorageStrategy.swift
//  EtherKit
//
//  Created by Zac Morris on 2018-11-28.
//

import EtherKit
import Result

fileprivate class DataCache {
  private var data: Data?
  
  private let cachingTime: TimeInterval
  private var cacheTimer: Timer?
  
  public init(cachingTime: TimeInterval) {
    self.cachingTime = cachingTime
  }
  
  func store(data: Data) {
    DispatchQueue.main.async {
      self.data = data
      if let currentTimer = self.cacheTimer {
        currentTimer.invalidate()
        self.cacheTimer = nil
      }
      self.cacheTimer = Timer.scheduledTimer(withTimeInterval: self.cachingTime, repeats: false) { _ in
        self.delete()
      }
    }
  }
  
  func retrieve() -> Data? {
    return data
  }
  
  func delete() {
    DispatchQueue.main.async {
      if let data = self.data {
        self.data?.resetBytes(in: 0..<data.count)
      }
      self.data = nil
      if let currentTimer = self.cacheTimer {
        currentTimer.invalidate()
        self.cacheTimer = nil
      }
    }
  }
}

public struct CachingStorageStrategy: StorageStrategyType {
  public let storageStrategy: StorageStrategyType
  private let cache: DataCache
  
  public init(_ storageStrategy: StorageStrategyType, cachingTime: Double) {
    self.storageStrategy = storageStrategy
    cache = DataCache(cachingTime: cachingTime)
  }
  
  // MARK: - StorageStrategyType
  
  public func store(data: Data) -> Result<Void, EtherKitError> {
    cache.store(data: data)
    return storageStrategy.store(data: data)
  }
  
  public func map<T>(secureContext: @escaping (Data) -> Result<T, EtherKitError>) -> Result<T, EtherKitError> {
    if let cachedData = self.cache.retrieve() {
      return secureContext(cachedData)
    }
    
    return storageStrategy.map { data in
      self.cache.store(data: data)
      return secureContext(data)
    }
  }
  
  public func delete() -> Result<Void, EtherKitError> {
    cache.delete()
    return storageStrategy.delete()
  }
}
