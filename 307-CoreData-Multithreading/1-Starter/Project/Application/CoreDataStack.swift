//
//  CoreDataStack.swift
//  CourseCatalog
//
//  Created by Saul Mora on 12/7/14.
//  Copyright (c) 2014 Magical Panda. All rights reserved.
//

import CoreData
import Swell

@IBDesignable @objc
public class CoreDataStack : NSObject
{
    
    // Use this logger.......
  internal lazy var logger : Logger = Swell.getLogger("CoreDataStack")
  
  var storeName : String?
  private lazy var storeURL : NSURL? = {
    let searchPaths = NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)
    let searchPath : String = searchPaths.first? as String
    let storeURL = NSURL(fileURLWithPath: searchPath)!
    if !storeURL.checkResourceIsReachableAndReturnError(nil) {
      NSFileManager.defaultManager().createDirectoryAtURL(storeURL, withIntermediateDirectories: true, attributes: nil, error: nil)
    }
    if let storeName = self.storeName {
      return storeURL.URLByAppendingPathComponent(storeName)
    }
    return nil
    }()
  
  func description() -> String
  {
    return "CoreDataStack:\n" +
      "Context: \(context)\n" +
      "Model: \(model.entityVersionHashesByName)\n" +
    "Coordinator: \(coordinator)"
  }
  
  public override init()
  {
  }
  
  init(storeName:String)
  {
    self.storeName = storeName
  }
  
  init(url:NSURL)
  {
    super.init()
    self.storeName = url.lastPathComponent!
    storeURL = url
  }
  
  internal var mainContext : NSManagedObjectContext {
    return context
  }
  
  private lazy var context : NSManagedObjectContext = {
    let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    //        context.persistentStoreCoordinator = self.coordinator
    return context
    }()
  
  private lazy var coordinator : NSPersistentStoreCoordinator = {
    let coordinator : NSPersistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
    self.logger.debug("Loaded Coordinator: \(coordinator)")
    self.configureCoordinator(coordinator)
    return coordinator
    }()
  
  private func configureCoordinator(coordinator:NSPersistentStoreCoordinator) {
    var error : NSError?
    var store : NSPersistentStore?
    switch (storeURL) {
    case .Some(let storeURL):
      let options = [NSSQLitePragmasOption : ["journal_mode": "DELETE"]]
      store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: options, error: &error)
    case .None:
      store = coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error)
    }
    
    if let store = store
    {
      logger.debug("-- Added Store: \(store)")
    }
    if let error = error {
      logger.error("\(error)")
    }
  }
  
  private lazy var model : NSManagedObjectModel = {
    let bundle = NSBundle(forClass: CoreDataStack.self)
    let model = NSManagedObjectModel.mergedModelFromBundles([bundle])!
    
    let logger = self.logger
    logger.debug("Loaded Model: \(model.entityVersionHashesByName)")
    logger.debug("-- from Bundle: \(bundle)")
    return model
    }()
}

