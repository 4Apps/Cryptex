//
//  PasswordManager.h
//  PasswordManager
//
//  Created by Gints Murans on 24/06/14.
//  Copyright (c) 2014 Early Bird. All rights reserved.
//


#import <Foundation/Foundation.h>

//! Project version number for PasswordManager.
FOUNDATION_EXPORT double PasswordManagerVersionNumber;

//! Project version string for PasswordManager.
FOUNDATION_EXPORT const unsigned char PasswordManagerVersionString[];



@interface PasswordManager : NSObject

+ (NSData *)hashWhirlpool:(NSData *)data;
+ (NSData *)hashSHA256:(NSData *)data;

//+ (NSData *)encryptAES128:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(CCCryptorStatus *)error;
//+ (NSData *)decryptAES128:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(CCCryptorStatus *)error;
//+ (NSData *)encryptTwofish:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(CCCryptorStatus *)error;
//+ (NSData *)decryptTwofish:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(CCCryptorStatus *)error;

+ (NSData *)encryptData:(NSData *)data withPassword:(NSString *)password error:(NSError **)error;
+ (NSData *)decryptData:(NSData *)data withPassword:(NSString *)password error:(NSError **)error;

#pragma mark - Helpers
+ (NSData *)randomDataOfLength:(size_t)length;
+ (NSString *)hexadecimalEncodedStringWithData:(NSData *)data;

#pragma mark - Tests
//+ (NSData *)encryptTwofishTest:(NSData *)data key:(NSData *)key iv:(NSData *)iv;
//+ (NSData *)v1_encryptData:(NSData *)data withPassword:(NSString *)password error:(NSError **)error;

@end