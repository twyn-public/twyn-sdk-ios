// Bridging header for the Twyn C cores (distributed as static xcframeworks).
// CocoaPods adds the xcframework Headers/ dirs to HEADER_SEARCH_PATHS, so the
// Swift sample can call the C ABI directly.
//
//   TwynTrustCore  -> sentinel_ios.h, twyn_runtime.h
//   TwynDeviceCore -> twyn_device_core.h

#import "twyn_device_core.h"
#import "twyn_runtime.h"
#import "sentinel_ios.h"
