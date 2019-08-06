//
//  DBManager.h
//
//  Created by Shiv on 19/02/16.
//  Copyright © 2016 MVD. All rights reserved.
//

#import "DBManager.h"
#import "NSDictionary+CheckKey.h"
#import "FMDB.h"

#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
//#   define DLog(...)
#else
#   define DLog(...)
#endif


@implementation DBManager

+ (DBManager *)sharedInstance {
    static DBManager *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DBManager alloc] init];
        NSString *dbPath = [self getCachesDirectoryPath:@"abc.sqlite"];
        sharedInstance.database = [FMDatabase databaseWithPath:dbPath];
    });
    return sharedInstance;
}

+(NSString *)getCachesDirectoryPath:(NSString *)dirPath{
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:dirPath];
    
    return path;
}

+(NSString *)getDirectoryPath:(NSString *)dirPath{
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:dirPath];
    
    return path;
}

+(void)copyFile:(NSString *)fileName isReplace:(BOOL)isReplace{
    NSString *dbPath = [self getCachesDirectoryPath:fileName];
    
    DLog(@"db Path :%@",dbPath);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (isReplace) {
        NSError *error;
        
        NSURL *documentsURL = [[NSBundle mainBundle]resourceURL];
        NSURL *fromPath = [documentsURL URLByAppendingPathComponent:fileName];
        [fileManager copyItemAtPath:fromPath.path toPath:dbPath error:&error];
        if (error != NULL){
            DLog(@"Data bas copy error , message : %@",error);
        }
    }else{
        if (![fileManager fileExistsAtPath:dbPath]){
            
            NSError *error;
            
            NSURL *documentsURL = [[NSBundle mainBundle]resourceURL];
            NSURL *fromPath = [documentsURL URLByAppendingPathComponent:fileName];
            [fileManager copyItemAtPath:fromPath.path toPath:dbPath error:&error];
            if (error != NULL){
                DLog(@"Data bas copy error , message : %@",error);
            }
        }
    }
    
    
}

-(NSArray *)getRecode:(NSString *)query :(NSArray *)argu{
    
    [_database open];
    NSError *error;
    FMResultSet *rs = [_database executeQuery:query values:argu error:&error];
    NSMutableArray *array = [NSMutableArray array];
    if ( rs != NULL) {
        while ([rs next]) {
        
            [ array addObject:[rs resultDictionary]];
        }
    }
    [rs close];
    [_database close];
    if (error != NULL){
        NSLog(@"Database error (getRecode) : %@",error);
    }
    return (NSArray *)array;
}

-(BOOL)allQuery:(NSString *)query :(NSArray *)argu{
    [_database open];
    NSError *error;
    BOOL isReturn = [_database executeUpdate:query values:argu error:&error];
    [_database close];
    if (error != NULL){
        NSLog(@"Database error (all Query) : %@",error);
    }
    return isReturn;
}

-(NSString *)insert:(NSString*)tableName :(NSDictionary*)dataInDic{
    
    
    NSArray *dicKey = dataInDic.allKeys;
    NSString *column = [[NSString alloc]init];
    NSString *values = [[NSString alloc]init];
    
    for (NSString *dicK in dicKey) {
        NSString *value = [dataInDic valueForKey:dicK];
        if ( value != nil) {
            values = [values stringByAppendingString:[NSString stringWithFormat:@"'%@',",[[NSString stringWithFormat:@"%@",value] sqlString]] ];
            column = [column stringByAppendingString:[NSString stringWithFormat:@"'%@',",dicK]];
        }
    }
    
    column = [column substringToIndex:[column length]-1] ;
    values = [values substringToIndex:[values length]-1] ;
    
    NSString *query = [NSString stringWithFormat:@" Insert OR REPLACE  Into %@ (%@) values (%@)",tableName,column,values];
    NSLog(@"Insert Query : %@ ",query);
    
    [_database open];
    NSError *error;
    BOOL isReturn = [_database executeUpdate:query values:nil error:&error];
    
    if (error != NULL){
        NSLog(@"Database error (Insert Query) : %@",error);
        return @"-1";
    }
    
    FMResultSet *rs = [_database executeQuery:@"select last_insert_rowid() as lastID"  values:nil error:&error];
    NSString *lastInsertID=@"0";
    if ( rs != NULL) {
        while ([rs next]) {
            
            lastInsertID = [ NSString stringWithFormat:@"%@",[[rs resultDictionary]valueForKey:@"lastID"]];
        }
    }
    [rs close];
    
    [_database close];
    if (error != NULL){
        NSLog(@"Database error (Insert Query) : %@",error);
    }
    
    if (!isReturn) {
        
        return @"-1";
    }
    
    
    return lastInsertID;//[self allQuery:query :NULL];
}

-(NSString *) insert:(NSString *)tableName allInfoDic:(NSDictionary *)dataInDic removeKeyName:(NSArray *)removeKeyArr{
    

    //delete Key of Dic
    NSMutableDictionary *tempDic = [dataInDic mutableCopy];
    for (NSString *removekey in removeKeyArr) {
        [tempDic removeObjectForKey:removekey];
    }
    
    return [self insert:tableName :(NSDictionary *)tempDic];
}

-(NSString *) insert:(NSString *)tableName allInfoDic:(NSDictionary *)dataInDic columns:(NSArray *)columsArray{
    
    //delete Key of Dic
    NSMutableDictionary *tempDic = [[NSMutableDictionary alloc] init];
    for (NSString *columnName in columsArray) {
        @try {
            if ([dataInDic checkKey:columnName]) {
                [tempDic setObject:[dataInDic valueForKey:columnName] forKey:columnName];
            }else{
                [tempDic setObject:@"" forKey:columnName];
            }
            
        } @catch (NSException *exception) {
            
        }
        
    }
    return [self insert:tableName :(NSDictionary *)tempDic];
}

-(NSString *) insert:(NSString *)tableName allInfoDic:(NSDictionary *)dataInDic removeKeyName:(NSArray *)removeKeyArr addDic:(NSArray *)addDic{
    
    
    //delete Key of Dic
    NSMutableDictionary *tempDic = [dataInDic mutableCopy];
    for (NSString *removekey in removeKeyArr) {
        [tempDic removeObjectForKey:removekey];
    }
    
    for (NSDictionary *aDic in addDic) {
        NSArray *dicKey = aDic.allKeys;
        for (NSString *dicK in dicKey) {
            [tempDic setObject:[aDic valueForKey:dicK] forKey:dicK];
        }
    }
    
    return [self insert:tableName :(NSDictionary *)tempDic];
}

-(BOOL)update:(NSString *)tableName  updateColume:(NSDictionary *)dataInDic Conidion:(NSString *)conidition{
    
    NSArray *dicKey = dataInDic.allKeys;
    NSString *updateColumns = [[NSString alloc]init];
    
    for (NSString *dicK in dicKey) {
        NSString *value = [dataInDic valueForKey:dicK];
        if ( value != nil) {
            updateColumns = [updateColumns stringByAppendingString:[NSString stringWithFormat:@" %@='%@',",dicK,value]];
        }
    }
    
    updateColumns = [updateColumns substringToIndex:[updateColumns length]-1];
    
    NSString *query;
    
    if ([conidition isEqualToString:@""]) {
        query = [NSString stringWithFormat:@" Update %@ SET %@",tableName,updateColumns];
    }else{
        query = [NSString stringWithFormat:@" Update %@ SET %@ Where %@",tableName,updateColumns,conidition];
    }

    NSLog(@"update Query : %@ ",query);
    
    return [self allQuery:query :NULL];
    
}


@end
