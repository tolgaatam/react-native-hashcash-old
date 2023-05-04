import ExpoModulesCore

public class ReactNativeHashcashModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ReactNativeHashcash")


//    AsyncFunction("calculateHashcash") { (k: UInt, identifier: String, promise: Promise) in
//      Task {
//        promise.resolve(await calculateHashcashTask(k: k, identifier: identifier))
//      }
//    }
      
    AsyncFunction("calculateHashcash") { (k: UInt, identifier: String) in
        calculateHashcashQueue(k: k, identifier: identifier)
    }

    // AsyncFunction("calculateHashcash") { (k: UInt, identifier: String) in
    //   calculateHashcashSequential(k: k, identifier: identifier)
    // }
  }
}
