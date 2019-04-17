//
//  JSRSA.m
//  RSA Example
//
//  Created by Js on 12/23/14.
//  Copyright (c) 2014 JS Lim. All rights reserved.
//

#include "js_rsa.h"
#import "JSRSA.h"
#import <UIKit/UIKit.h>
#ifdef HGBLogFlag
#define HGBLog(FORMAT,...) fprintf(stderr,"**********HGBErrorLog-satrt***********\n{\n文件名称:%s;\n方法:%s;\n行数:%d;\n提示:%s\n}\n**********HGBErrorLog-end***********\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],[[NSString stringWithUTF8String:__func__] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define HGBLog(...);
#endif

@implementation JSRSA

#pragma mark - helper
- (NSString *)publicKeyPath
{
    if (_publicKey == nil || [_publicKey isEqualToString:@""]) return nil;
    
	NSString *keyPath=[JSRSA urlAnalysisToPath:_publicKey];
    
    return keyPath;
}

- (NSString *)privateKeyPath
{
    if (_privateKey == nil || [_privateKey isEqualToString:@""]) return nil;
    
	NSString *keyPath=[JSRSA urlAnalysisToPath:_privateKey];
	
	return keyPath;
}

#pragma mark - implementation
- (NSString *)publicEncrypt:(NSString *)plainText
{
    NSString *keyPath = [self publicKeyPath];
    if (keyPath == nil) {
        HGBLog(@"密钥文件地址不能为空");
        return nil;

    }
    if(plainText==nil){
        HGBLog(@"字符串不能为空");
        return nil;
    }
        
    char *cipherText = js_public_encrypt([plainText UTF8String], [keyPath UTF8String]);
    
    NSString *cipherTextString = [NSString stringWithUTF8String:cipherText];
    
    free(cipherText);
    
    return cipherTextString;
}

- (NSString *)privateDecrypt:(NSString *)cipherText
{
    NSString *keyPath = [self privateKeyPath];
    if (keyPath == nil) {
        HGBLog(@"密钥文件地址不能为空");
        return nil;

    }
    if(cipherText==nil){
        HGBLog(@"字符串不能为空");
        return nil;
    }
    
    char *plainText = js_private_decrypt([cipherText UTF8String], [keyPath UTF8String]);
    
    NSString *planTextString = [NSString stringWithUTF8String:plainText];
    
    free(plainText);
    
    return planTextString;
}

- (NSString *)privateEncrypt:(NSString *)plainText
{
    NSString *keyPath = [self privateKeyPath];
    if (keyPath == nil) {
        HGBLog(@"密钥文件地址不能为空");
        return nil;

    }
    if(plainText==nil){
        HGBLog(@"字符串不能为空");
        return nil;
    }
        
    char *cipherText = js_private_encrypt([plainText UTF8String], [keyPath UTF8String]);
    
    NSString *cipherTextString = [NSString stringWithUTF8String:cipherText];
    
    free(cipherText);
    
    return cipherTextString;
}

- (NSString *)publicDecrypt:(NSString *)cipherText
{
    NSString *keyPath = [self publicKeyPath];
    if (keyPath == nil) {
        HGBLog(@"密钥文件地址不能为空");
        return nil;

    }
    if(cipherText==nil){
        HGBLog(@"字符串不能为空");
        return nil;
    }
    
    char *plainText = js_public_decrypt([cipherText UTF8String], [keyPath UTF8String]);
    
    NSString *plainTextString = [NSString stringWithUTF8String:plainText];
    
    free(plainText);
    
    return plainTextString;
}

#pragma mark - instance method
+ (JSRSA *)sharedInstance
{
    static JSRSA *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}
#pragma mark url
/**
 判断路径是否是URL
 
 @param url url路径
 @return 结果
 */
+(BOOL)isURL:(NSString*)url{
	if([url hasPrefix:@"project://"]||[url hasPrefix:@"home://"]||[url hasPrefix:@"document://"]||[url hasPrefix:@"caches://"]||[url hasPrefix:@"tmp://"]||[url hasPrefix:@"defaults://"]||[url hasPrefix:@"/User"]||[url hasPrefix:@"/var"]||[url hasPrefix:@"http://"]||[url hasPrefix:@"https://"]||[url hasPrefix:@"file://"]){
		return YES;
	}else{
		return NO;
	}
}
/**
 url校验存在
 
 @param url url
 @return 是否存在
 */
+(BOOL)urlExistCheck:(NSString *)url{
	if(url==nil||url.length==0){
		return NO;
	}
	if(![JSRSA isURL:url]){
		return NO;
	}
	url=[JSRSA urlAnalysis:url];
	if(![url containsString:@"://"]){
		url=[[NSURL fileURLWithPath:url]absoluteString];
	}
	if([url hasPrefix:@"file://"]){
		NSString *filePath=[[NSURL URLWithString:url]path];
		if(filePath==nil||filePath.length==0){
			return NO;
		}
		NSFileManager *filemanage=[NSFileManager defaultManager];//创建对象
		return [filemanage fileExistsAtPath:filePath];
	}else{
		NSURL *urlCheck=[NSURL URLWithString:url];
		
		return [[UIApplication sharedApplication]canOpenURL:urlCheck];
		
	}
}
/**
 url解析
 
 @return 解析后url
 */
+(NSString *)urlAnalysisToPath:(NSString *)url{
	if(url==nil){
		return nil;
	}
	if(![JSRSA isURL:url]){
		return nil;
	}
	NSString *urlstr=[JSRSA urlAnalysis:url];
	return [[NSURL URLWithString:urlstr]path];
}
/**
 url解析
 
 @return 解析后url
 */
+(NSString *)urlAnalysis:(NSString *)url{
	if(url==nil){
		return nil;
	}
	if(![JSRSA isURL:url]){
		return nil;
	}
	if([url containsString:@"://"]){
		//project://工程包内
		//home://沙盒路径
		//http:// https://网络路径
		//document://沙盒Documents文件夹
		//caches://沙盒Caches
		//tmp://沙盒Tmp文件夹
		if([url hasPrefix:@"project://"]||[url hasPrefix:@"home://"]||[url hasPrefix:@"document://"]||[url hasPrefix:@"defaults://"]||[url hasPrefix:@"caches://"]||[url hasPrefix:@"tmp://"]){
			if([url hasPrefix:@"project://"]){
				url=[url stringByReplacingOccurrencesOfString:@"project://" withString:@"/"];
				NSString *projectPath=[[NSBundle mainBundle]resourcePath];
				url=[projectPath stringByAppendingPathComponent:url];
			}else if([url hasPrefix:@"home://"]){
				url=[url stringByReplacingOccurrencesOfString:@"home://" withString:@""];
				NSString *homePath=NSHomeDirectory();
				url=[homePath stringByAppendingPathComponent:url];
			}else if([url hasPrefix:@"document://"]){
				url=[url stringByReplacingOccurrencesOfString:@"document://" withString:@""];
				NSString  *documentPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject];
				url=[documentPath stringByAppendingPathComponent:url];
			}else if([url hasPrefix:@"defaults://"]){
				url=[url stringByReplacingOccurrencesOfString:@"defaults://" withString:@""];
				NSString  *documentPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject];
				url=[documentPath stringByAppendingPathComponent:url];
			}else if([url hasPrefix:@"caches://"]){
				url=[url stringByReplacingOccurrencesOfString:@"caches://" withString:@""];
				NSString  *cachesPath =[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) lastObject];
				url=[cachesPath stringByAppendingPathComponent:url];
			}else if([url hasPrefix:@"tmp://"]){
				url=[url stringByReplacingOccurrencesOfString:@"tmp://" withString:@""];
				NSString *tmpPath =NSTemporaryDirectory();
				url=[tmpPath stringByAppendingPathComponent:url];
			}
			url=[[NSURL fileURLWithPath:url]absoluteString];
			
		}else{
			
		}
	}else {
		url=[[NSURL fileURLWithPath:url]absoluteString];
	}
	return url;
}
/**
 url封装
 
 @return 封装后url
 */
+(NSString *)urlEncapsulation:(NSString *)url{
	if(![JSRSA isURL:url]){
		return nil;
	}
	NSString *homePath=NSHomeDirectory();
	NSString  *documentPath =[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject];
	NSString  *cachesPath =[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) lastObject];
	NSString *projectPath=[[NSBundle mainBundle]resourcePath];
	NSString *tmpPath =NSTemporaryDirectory();
	
	if([url hasPrefix:@"file://"]){
		url=[url stringByReplacingOccurrencesOfString:@"file://" withString:@""];
	}
	if([url hasPrefix:projectPath]){
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",projectPath] withString:@"project://"];
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",projectPath] withString:@"project://"];
	}else if([url hasPrefix:documentPath]){
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",documentPath] withString:@"defaults://"];
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",documentPath] withString:@"defaults://"];
	}else if([url hasPrefix:cachesPath]){
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",cachesPath] withString:@"caches://"];
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",cachesPath] withString:@"caches://"];
	}else if([url hasPrefix:tmpPath]){
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",tmpPath] withString:@"tmp://"];
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",tmpPath] withString:@"tmp://"];
	}else if([url hasPrefix:homePath]){
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@/",homePath] withString:@"home://"];
		url=[url stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@",homePath] withString:@"home://"];
	}else if([url containsString:@"://"]){
		
	}else{
		url=[[NSURL fileURLWithPath:url]absoluteString];
	}
	return url;
}

@end
