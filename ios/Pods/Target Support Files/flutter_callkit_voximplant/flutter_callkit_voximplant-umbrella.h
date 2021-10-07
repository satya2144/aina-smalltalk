#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "CXAction+ConvertToDictionary.h"
#import "CXCall+ConvertToDictionary.h"
#import "CXCallUpdate+ConvertToDictionary.h"
#import "CXHandle+ConvertToDictionary.h"
#import "CXProviderConfiguration+ConvertToDictionary.h"
#import "CXTransaction+ConvertToDictionary.h"
#import "FlutterError+FlutterCallKitError.h"
#import "FlutterMethodCall+FCXMethodType.h"
#import "NSISO8601DateFormatter+WithoutMS.h"
#import "NullChecks.h"
#import "FCXActionManager.h"
#import "FCXCallControllerManager.h"
#import "FCXCallDirectoryPhoneNumber.h"
#import "FCXIdentifiablePhoneNumber.h"
#import "FCXProviderManager.h"
#import "FCXTransactionManager.h"
#import "FlutterCallkitPlugin.h"

FOUNDATION_EXPORT double flutter_callkit_voximplantVersionNumber;
FOUNDATION_EXPORT const unsigned char flutter_callkit_voximplantVersionString[];

