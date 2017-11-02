//
//  do_LocalNotification_SM.m
//  DoExt_API
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_LocalNotification_SM.h"

#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doInvokeResult.h"
#import "doJsonHelper.h"
#import "doIOHelper.h"
#import "doIApp.h"
#import "doIPage.h"
#import "doILogEngine.h"
#import "doServiceContainer.h"
#import <UIKit/UIKit.h>

@implementation do_LocalNotification_SM
#pragma mark - 方法
#pragma mark - 同步异步方法的实现
//同步
- (void)addNotify:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    //自己的代码实现
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    
    UILocalNotification *notification;
    NSString *notifyTime = [doJsonHelper GetOneText:_dictParas :@"notifyTime" :@""];
    int notifyId = [doJsonHelper GetOneInteger:_dictParas :@"notifyId" :0];
    NSString *repeatMode = [doJsonHelper GetOneText:_dictParas :@"repeatMode" :@"None"];
    NSCalendarUnit repeat;
    if ([repeatMode caseInsensitiveCompare:@"Minute"] == NSOrderedSame) {
        repeat = NSCalendarUnitMinute;
    }
    else if ([repeatMode caseInsensitiveCompare:@"Hour"] == NSOrderedSame)
    {
        repeat = NSCalendarUnitHour;
    }
    else if ([repeatMode caseInsensitiveCompare:@"Day"] == NSOrderedSame)
    {
        repeat = NSCalendarUnitDay;
    }
    else if ([repeatMode caseInsensitiveCompare:@"Week"] == NSOrderedSame)
    {
        repeat = NSCalendarUnitWeekday;
    }
    else
    {
        repeat = 0;
    }
    notification = [[UILocalNotification alloc]init];
    //设置转换格式
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone localTimeZone]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];

//    NSString转NSDate
    NSDate *date =  [formatter dateFromString:notifyTime];
    NSString *contentText = [doJsonHelper GetOneText:_dictParas :@"contentText" :@""];
    NSDictionary *extra = [doJsonHelper GetOneNode:_dictParas :@"extra"];
    NSString *ringing = [doJsonHelper GetOneText:_dictParas :@"ringing" :@""];
    //iOS不支持
//    BOOL isVibrate = [doJsonHelper GetOneBoolean:_dictParas :@"isVibrate" :YES];
    NSString *path = @"";
    NSString *fileName = @"";
    if (ringing.length>0&&[ringing hasPrefix:@"data://"]) {
        path = [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentPage.CurrentApp :ringing];
        fileName = [path lastPathComponent];
        if (fileName.length>0&&![fileName hasSuffix:@"/"]) {
            NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask,YES) firstObject];
            NSString *name = [NSString stringWithFormat:@"%@/Sounds",libraryPath];
            if (![doIOHelper ExistDirectory:name]) {
                [doIOHelper CreateDirectory:name];
            }
            NSString *targetFile = [NSString stringWithFormat:@"%@/Sounds/%@",libraryPath,fileName];
            [doIOHelper FileCopy:path :targetFile];
        }
        if (fileName.length>0) {
            NSString *extension = [fileName pathExtension];
            notification.soundName = fileName;
            if (![extension isEqualToString:@"m4a"]) {
                notification.soundName =  UILocalNotificationDefaultSoundName;
                [[doServiceContainer Instance].LogEngine WriteError:nil :@"iOS仅支持m4a格式的音频文件。"];
            }
        }else {
            notification.soundName = UILocalNotificationDefaultSoundName;
        }
    }else {
        notification.soundName = UILocalNotificationDefaultSoundName;
    }

    
    notification.fireDate = date;
    notification.timeZone = [NSTimeZone localTimeZone];
    notification.alertBody= contentText;
    NSMutableDictionary *mutableExtra = [NSMutableDictionary dictionaryWithDictionary:extra];
    [mutableExtra setObject:[NSNumber numberWithInt:notifyId] forKey:@"doLocalNotifitionID"];
    notification.alertAction = @"打开";  //提示框按钮
    notification.hasAction = YES;
    notification.userInfo = mutableExtra;
    notification.repeatInterval = repeat;

    for (UILocalNotification *notification in [UIApplication sharedApplication].scheduledLocalNotifications) {
        NSDictionary *userInfo = notification.userInfo;
        NSNumber *userInfoKey = [userInfo objectForKey:@"doLocalNotifitionID"];
        if (userInfoKey.intValue == notifyId) {
            [[UIApplication sharedApplication]cancelLocalNotification:notification];
        }
    }
    //ios 8 注册
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        if ([[UIApplication sharedApplication]currentUserNotificationSettings].types==UIUserNotificationTypeNone)
        {
            [[UIApplication sharedApplication]registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound  categories:nil]];
        }
    }
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}
- (void)removeNotify:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    NSArray *notifyIds = [doJsonHelper GetOneArray:_dictParas :@"notifyIds"];
    if (!notifyIds || notifyIds.count == 0) {
        [[UIApplication sharedApplication]cancelAllLocalNotifications];
    }
    else
    {
        for (NSNumber *notifyId in notifyIds) {
            for (UILocalNotification *notification in [UIApplication sharedApplication].scheduledLocalNotifications) {
                NSDictionary *userInfo = notification.userInfo;
                NSNumber *userInfoKey = [userInfo objectForKey:@"doLocalNotifitionID"];
                if (userInfoKey.intValue == notifyId.intValue) {
                    [[UIApplication sharedApplication]cancelLocalNotification:notification];
                }
            }
        }
    }
}
//异步

@end
