package expo.modules.hashcashold

import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class ReactNativeHashcashModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("ReactNativeHashcash")

//    AsyncFunction("calculateHashcash") { k: Int, identifier: String, promise: Promise ->
//      promise.resolve(calculateHashcashSequential(k.toUInt(), identifier))
//    }

    AsyncFunction("calculateHashcash") { k: Int, identifier: String, promise: Promise ->
      promise.resolve(calculateHashcashMulti(k.toUInt(), identifier))
    }
  }
}
