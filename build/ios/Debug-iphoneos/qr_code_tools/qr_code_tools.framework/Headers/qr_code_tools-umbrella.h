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

#import "QrCodeToolsPlugin.h"

FOUNDATION_EXPORT double qr_code_toolsVersionNumber;
FOUNDATION_EXPORT const unsigned char qr_code_toolsVersionString[];

