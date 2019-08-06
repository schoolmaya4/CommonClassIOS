//
//  DBManager.h
//
//  Created by Shiv on 19/02/16.
//  Copyright © 2016 MVD. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDB.h"
#import "NSString+SQLIGHTSTRING.h"

@interface DBManager : NSObject
@property (nonatomic) FMDatabase *database;
+ (DBManager *)sharedInstance;
+(NSString *)getCachesDirectoryPath:(NSString *)dirPath;
+(NSString *)getDirectoryPath:(NSString *)dirPath;
+(void)copyFile:(NSString *)fileName isReplace:(BOOL)isReplace;
            
-(NSArray *)getRecode:(NSString *)query :(NSArray *)argu;
-(BOOL)allQuery:(NSString *)query :(NSArray *)argu;
-(NSString *)insert:(NSString*)tableName :(NSDictionary*)dataInDic;
-(NSString *)insert:(NSString *)tableName allInfoDic:(NSDictionary *)dataInDic columns:(NSArray *)columsArray;
-(NSString *)insert:(NSString*)tableName allInfoDic:(NSDictionary*)dataInDic removeKeyName:(NSArray *)removeKeyArr;
-(NSString *)insert:(NSString *)tableName allInfoDic:(NSDictionary *)dataInDic removeKeyName:(NSArray *)removeKeyArr addDic:(NSArray *)addDic;
-(BOOL)update:(NSString *)tableName  updateColume:(NSDictionary *)dataInDic Conidion:(NSString *)conidition;



@end
