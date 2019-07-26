//
//  ESPFBYDataBase.m
//  ESPMeshLibrary
//
//  Created by fanbaoying on 2019/7/24.
//  Copyright © 2019 zhaobing. All rights reserved.
//

#import "ESPFBYDataBase.h"
#import "ESPDataConversion.h"
#import "YTKKeyValueStore.h"
#import "NSString+URL.h"

#define ValidArray(f) (f!=nil && [f isKindOfClass:[NSArray class]] && [f count]>0)

@implementation ESPFBYDataBase

static YTKKeyValueStore *dbStore;
static NSString *username;

+ (void)espDataBaseInit:(NSString *)message {
    username = message;
    dbStore = [[YTKKeyValueStore alloc] initDBWithName:[NSString stringWithFormat:@"%@.db",message]];
}
//hwdevice_table表  保存本地配对信息
+ (void)saveHWDevicefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSDictionary* argsDic = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    NSString *key = argsDic[@"mac"];
    [dbStore putObject:argsDic withId:key intoTable:@"hwdevice_table"];
}
+ (void)saveHWDevicesfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsArr = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    
    for (int i=0; i<argsArr.count; i++) {
        NSDictionary* itemDic=argsArr[i];
        NSString *key = itemDic[@"mac"];
        [dbStore putObject:itemDic withId:key intoTable:@"hwdevice_table"];
    }
}
+ (void)deleteHWDevicefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString* mac = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    [dbStore deleteObjectById:mac fromTable:@"hwdevice_table"];
}
+ (void)deleteHWDevicesfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"hwdevice_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        id mac = argsDic[j];
        [dbStore deleteObjectById:mac fromTable:@"hwdevice_table"];
    }
}
+ (NSString *)loadHWDevicesfby {
    [dbStore createTableWithName:@"hwdevice_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"hwdevice_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    
    return json;
}

//表  Group组
+ (id)saveGroupfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return nil;
    }
    NSMutableDictionary* argsDic = msg;
    [dbStore createTableWithName:@"group_table"];
    id key = argsDic[@"id"];
    if (key==nil) {
        key=[ESPDataConversion getRandomStringWithLength];
        argsDic[@"id"]=key;
    }
    [dbStore putObject:argsDic withId:key intoTable:@"group_table"];
    
    return key;
}
+ (void)saveGroupsfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if ([msg isEqual:[NSNull null]]) {
        return;
    }
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"group_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        NSMutableDictionary* itemDic=argsDic[j];
        id key = itemDic[@"id"];
        if (key==nil) {
            key=[ESPDataConversion getRandomStringWithLength];
            itemDic[@"id"]=key;
        }
        [dbStore putObject:itemDic withId:key intoTable:@"group_table"];
    }
}
+ (NSString *)loadGroupsfby {
    [dbStore createTableWithName:@"group_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"group_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    
    return json;
}
+ (void)deleteGroupfby:(NSString *)message {
    if (message==nil) {
        return;
    }
    dbStore = [[YTKKeyValueStore alloc] initDBWithName:[NSString stringWithFormat:@"%@.db",username]];
    [dbStore createTableWithName:@"group_table"];
    id key = message;
    [dbStore deleteObjectById:key fromTable:@"group_table"];
}

//Mac  Mac表
+ (void)saveMacfby:(NSString *)message {
    NSString* mac = message;
    [dbStore createTableWithName:@"mac_table"];
    [dbStore putObject:@{@"mac":mac} withId:mac intoTable:@"mac_table"];
}
+ (void)deleteMacfby:(NSString *)message {
    NSString* mac = message;
    [dbStore createTableWithName:@"mac_table"];
    [dbStore deleteObjectById:mac fromTable:@"mac_table"];
}
+ (void)deleteMacsfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"mac_table"];
    
    for (int j=0; j<argsDic.count; j++) {
        id mac = argsDic[j];
        [dbStore deleteObjectById:mac fromTable:@"mac_table"];
    }
}
+ (NSString *)loadMacsfby {
    [dbStore createTableWithName:@"mac_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"mac_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject[@"mac"];
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    return json;
}

//meshId表
+ (void)saveMeshIdfby:(NSString *)message {
    NSString* meshid = message;
    [dbStore createTableWithName:@"meshid_table"];
    [dbStore putObject:@{@"meshid":meshid} withId:meshid intoTable:@"meshid_table"];
}
+ (void)deleteMeshIdfby:(NSString *)message {
    NSString* meshid = message;
    [dbStore createTableWithName:@"meshid_table"];
    [dbStore deleteObjectById:meshid fromTable:@"meshid_table"];
}
+ (NSString *)loadLastMeshIdfby {
    [dbStore createTableWithName:@"meshid_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"meshid_table"];
    NSString* meshid=@"";
    if (dataArr.count>0) {
        meshid=((YTKKeyValueItem*)dataArr[0]).itemObject[@"meshid"];
        NSDate* oldDate=((YTKKeyValueItem*)dataArr[0]).createdTime;
        for (int i=1; i<dataArr.count; i++) {
            NSDate* itemDate=((YTKKeyValueItem*)dataArr[i]).createdTime;
            if (([itemDate timeIntervalSince1970]-[oldDate timeIntervalSince1970])>0) {
                oldDate=itemDate;
                meshid=((YTKKeyValueItem*)dataArr[i]).itemObject[@"meshid"];
            }
        }
    }
    return meshid;
}
+ (NSString *)loadMeshIdsfby {
    [dbStore createTableWithName:@"meshid_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"meshid_table"];
    NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject[@"meshid"];
        [needArr addObject:item];
    }
    NSString* json=[ESPDataConversion jsonFromObject:needArr];
    return json;
}

//文件 Key - Value 增删改查
+ (void)saveValuesForKeysInFilefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName = [msg objectForKey:@"name"];
    NSArray *contentArr = [msg objectForKey:@"content"];
    for (int i = 0; i < contentArr.count; i ++) {
        NSDictionary *contentDic = contentArr[i];
        NSString *keyStr = [contentDic objectForKey:@"key"];
        NSString *valueStr = [contentDic objectForKey:@"value"];
        [dbStore putObject:@{keyStr:valueStr} withId:keyStr intoTable:tableName];
    }
}
+ (void)removeValuesForKeysInFilefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=[msg objectForKey:@"name"];
    NSArray *keysArr=[msg objectForKey:@"keys"];
    [dbStore createTableWithName:tableName];
    for (int i = 0; i < keysArr.count; i ++) {
        [dbStore deleteObjectById:keysArr[i] fromTable:tableName];
    }
}
+ (NSString *)loadValueForKeyInFilefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return nil;
    }
    NSString *tableName=[msg objectForKey:@"name"];
    NSString *tableKey=[msg objectForKey:@"key"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        if ([tableKey isEqualToString:[NSString stringWithFormat:@"%@",itemId]]) {
            id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
            contetDic[itemId] = [item objectForKey:itemId];
        }
    }
    needDic[@"name"] = tableName;
    needDic[@"content"] = contetDic;
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    return json;
}
+ (NSString *)loadAllValuesInFilefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return nil;
    }
    NSString *tableName = [msg objectForKey:@"name"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSString *firstItemKey = @"";
    for (int i=0; i<dataArr.count; i++) {
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        firstItemKey = itemId;
        contetDic[itemId] = [item objectForKey:itemId];
    }
    needDic[@"name"] = tableName;
    needDic[@"content"] = contetDic;
    needDic[@"latest_key"] = firstItemKey;
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    return json;
}

//保存本地事件
+ (void)saveDeviceEventsCoordinatefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName = @"localEvents";
    NSString *keyStr = [msg objectForKey:@"mac"];
    [dbStore putObject:@{keyStr:msg} withId:keyStr intoTable:tableName];
}
+ (NSString *)loadDeviceEventsCoordinatefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return nil;
    }
    NSString *tableName=@"localEvents";
    NSString *tableKey=[msg objectForKey:@"mac"];
    NSString *tag=[msg objectForKey:@"tag"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* contetDic=[NSMutableDictionary dictionaryWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        if ([tableKey isEqualToString:[NSString stringWithFormat:@"%@",itemId]]) {
            id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
            contetDic = [item objectForKey:itemId];
        }
    }
    contetDic[@"tag"] = tag;
    NSString* json=[ESPDataConversion jsonFromObject:contetDic];
    return json;
}
+ (NSString *)loadAllDeviceEventsCoordinatefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return nil;
    }
    NSString *tableName=@"localEvents";
    NSString *tag=[msg objectForKey:@"tag"];
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    NSMutableDictionary* needDic=[NSMutableDictionary dictionaryWithCapacity:0];
    NSMutableArray* contetArr=[NSMutableArray arrayWithCapacity:0];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
        [contetArr addObject:[item objectForKey:itemId]];
    }
    needDic[@"tag"] = tag;
    needDic[@"content"] = [[ESPDataConversion jsonFromObject:contetArr] URLEncodedString];
    NSString* json=[ESPDataConversion jsonFromObject:needDic];
    return json;
}
+ (void)deleteDeviceEventsCoordinatefby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSString *tableName=@"localEvents";
    NSString *keyStr=[msg objectForKey:@"keys"];
    [dbStore createTableWithName:tableName];
    [dbStore deleteObjectById:keyStr fromTable:tableName];
}
+ (void)deleteAllDeviceEventsCoordinatefby {
    NSString *tableName=@"localEvents";
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        [dbStore deleteObjectById:itemId fromTable:tableName];
    }
}



//table信息存储(ipad)
+ (void)saveDeviceTablefby:(NSString *)message {
    NSString *ipadDeviceTablemsg = message;
    [dbStore createTableWithName:@"ipadDevice_table"];
    [dbStore putObject:@{@"ipaddevicetable":ipadDeviceTablemsg} withId:@"ipaddevicetable" intoTable:@"ipadDevice_table"];
}
+ (NSString *)loadDeviceTablefby {
    [dbStore createTableWithName:@"ipadDevice_table"];
    NSArray* dataArr=[dbStore getAllItemsFromTable:@"ipadDevice_table"];
    NSString *itemStr = @"";
    if (ValidArray(dataArr)) {
        itemStr = ((YTKKeyValueItem*)dataArr[0]).itemObject[@"ipaddevicetable"];
    }
    return itemStr;
}

//table设备信息存储(ipad)
+ (void)saveTableDevicesfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray *argsArr = msg;
    [dbStore createTableWithName:@"ipadtable_devices"];
    if (ValidArray(argsArr)) {
        for (int i = 0; i < argsArr.count; i ++) {
            NSString *key = argsArr[i][@"mac"];
            NSDictionary *value = argsArr[i];
            [dbStore putObject:value withId:key intoTable:@"ipadtable_devices"];
        }
    }
}
+ (NSString *)loadTableDevicesfby {
    [dbStore createTableWithName:@"ipadtable_devices"];
    NSArray *dataArr=[dbStore getAllItemsFromTable:@"ipadtable_devices"];
    NSString *json = @"";
    if (ValidArray(dataArr)) {
        NSMutableArray* needArr=[NSMutableArray arrayWithCapacity:0];
        for (int i=0; i<dataArr.count; i++) {
            id item=((YTKKeyValueItem*)dataArr[i]).itemObject;
            [needArr addObject:item];
        }
        json=[ESPDataConversion jsonFromObject:needArr];
    }
    return json;
}
+ (void)removeTableDevicesfby:(NSString *)message {
    id msg=[ESPDataConversion objectFromJsonString:message];
    if (msg==nil) {
        return;
    }
    NSArray* argsDic = msg;
    [dbStore createTableWithName:@"ipadtable_devices"];
    
    for (int j=0; j<argsDic.count; j++) {
        id mac = argsDic[j];
        [dbStore deleteObjectById:mac fromTable:@"ipadtable_devices"];
    }
}
+ (void)removeAllTableDevicesfby {
    NSString *tableName = @"ipadtable_devices";
    [dbStore createTableWithName:tableName];
    NSArray* dataArr=[dbStore getAllItemsFromTable:tableName];
    for (int i=0; i<dataArr.count; i++) {
        NSString *itemId = ((YTKKeyValueItem*)dataArr[i]).itemId;
        [dbStore deleteObjectById:itemId fromTable:tableName];
    }
}

// 保存配网记录
+ (void)saveObject:(NSDictionary *)objItem withNameTable:(NSString *)nameTable withId:(NSString *)ssid {
    [dbStore createTableWithName:nameTable];
    [dbStore putObject:objItem withId:ssid intoTable:nameTable];
}

// 获取配网记录
+ (NSArray *)getAllItemsFromTablefby:(NSString *)message {
    NSArray* dataArr = [dbStore getAllItemsFromTable:message];
    return dataArr;
}

@end
