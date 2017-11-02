//
//  do_LocalNotification_App.m
//  DoExt_SM
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_LocalNotification_App.h"
#import "doJsonHelper.h"
#import "do_LocalNotification_SM.h"
#import "doScriptEngineHelper.h"

static NSString *NotificationClickKey = @"NotificationClickKey";

static do_LocalNotification_App* instance;
@implementation do_LocalNotification_App
@synthesize OpenURLScheme;
+(id) Instance
{
    if(instance==nil)
        instance = [[do_LocalNotification_App alloc]init];
    return instance;
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //注册本地通知
    //ios 8
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication]registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound  categories:nil]];
    }
    UILocalNotification *notification=[launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (notification)
    {
        [self fireEvent:@"messageClicked" withdidReceiveLocalNotification:notification];
    }
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSDictionary *notiDict = [[NSUserDefaults standardUserDefaults]dictionaryForKey:@"LocalNotificationKey"];
    if (notiDict) {
        BOOL isBackground = [[NSUserDefaults standardUserDefaults]boolForKey:NotificationClickKey];
        if (isBackground) {
            [self fireNotification:notiDict];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NotificationClickKey];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"LocalNotificationKey"];
        }
    }
}
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{

    if(application.applicationState == UIApplicationStateActive)//收到
    {
        [self fireEvent:@"message" withdidReceiveLocalNotification:notification];
        return;
    }
    else//点击
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:NotificationClickKey];
        //存储
        [self saveNotification:notification];
    }
}
- (void)fireEvent:(NSString *)eventName withdidReceiveLocalNotification:(UILocalNotification *)notification
{
    NSMutableDictionary *node = [self getNode:notification];
    do_LocalNotification_SM *localNotification = (do_LocalNotification_SM*)[doScriptEngineHelper ParseSingletonModule:nil :@"do_LocalNotification" ];
    doInvokeResult *resul = [[doInvokeResult alloc]init];
    [resul SetResultNode:node];
    [localNotification.EventCenter FireEvent:eventName :resul];
}
- (void)fireNotification:(NSDictionary *)node
{
    do_LocalNotification_SM *localNotification = (do_LocalNotification_SM*)[doScriptEngineHelper ParseSingletonModule:nil :@"do_LocalNotification" ];
    doInvokeResult *resul = [[doInvokeResult alloc]init];
    [resul SetResultNode:node];
    [localNotification.EventCenter FireEvent:@"messageClicked" :resul];
}
- (void)saveNotification:(UILocalNotification *)notification
{
    NSMutableDictionary *node = [self getNode:notification];
    [[NSUserDefaults standardUserDefaults]setObject:node forKey:@"LocalNotificationKey"];
}
- (NSMutableDictionary *)getNode:(UILocalNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    [mutableUserInfo removeObjectForKey:@"doLocalNotifitionID"];

    NSMutableDictionary *node = [NSMutableDictionary dictionary];

    id contentText = notification.alertBody;
    if (!contentText) {
        contentText = @"";
    }
    id doLocalNotifitionID = [userInfo objectForKey:@"doLocalNotifitionID"];
    if (!doLocalNotifitionID) {
        doLocalNotifitionID = @"";
    }
    if (!mutableUserInfo) {
        mutableUserInfo = [NSMutableDictionary dictionary];
    }
    [node setObject:contentText forKey:@"contentText"];
    [node setObject:doLocalNotifitionID forKey:@"notifyId"];
    [node setObject:mutableUserInfo forKey:@"extra"];
    
    return node;
}
@end
