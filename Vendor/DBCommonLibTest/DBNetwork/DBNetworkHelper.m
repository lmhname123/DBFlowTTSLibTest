//
//  DBNetworkHelper.m
//  DBFlowTTS
//
//  Created by linxi on 2019/11/14.
//  Copyright © 2019 biaobei. All rights reserved.
//

#import "DBNetworkHelper.h"
#import "DBCommonConst.h"
@implementation DBNetworkHelper

//GET请求
+ (void)getWithUrlString:(NSString *)url parameters:(id)parameters success:(DBSuccessBlock)successBlock failure:(DBFailureBlock)failureBlock
{
    NSMutableString *mutableUrl = [[NSMutableString alloc] initWithString:url];
    if ([parameters allKeys]) {
        [mutableUrl appendString:@"?"];
        for (id key in parameters) {
            NSString *value = [[parameters objectForKey:key] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [mutableUrl appendString:[NSString stringWithFormat:@"%@=%@&", key, value]];
        }
    }
    NSString *urlEnCode = [[mutableUrl substringToIndex:mutableUrl.length - 1] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:urlEnCode] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    NSURLSession *urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        bb_dispatch_main_async_safe(^{
            if (error) {
                failureBlock(error);
            } else {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                successBlock(dic);
            }
        });
    }];
    [dataTask resume];
}

//POST请求 使用NSMutableURLRequest可以加入请求头
+ (void)postWithUrlString:(NSString *)url parameters:(id)parameters success:(DBSuccessBlock)successBlock failure:(DBFailureBlock)failureBlock
{
    NSURL *nsurl = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:nsurl];
    //如果想要设置网络超时的时间的话，可以使用下面的方法：
    //NSMutableURLRequest *mutableRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    
    //设置请求类型
    request.HTTPMethod = @"POST";
    //将需要的信息放入请求头 随便定义了几个
    [request setValue:@"xxx" forHTTPHeaderField:@"Authorization"];//token
    [request setValue:@"xxx" forHTTPHeaderField:@"Gis-Lng"];//坐标 lng
    [request setValue:@"xxx" forHTTPHeaderField:@"Gis-Lat"];//坐标 lat
    [request setValue:@"xxx" forHTTPHeaderField:@"Version"];//版本
//    NSLog(@"POST-Header:%@",request.allHTTPHeaderFields);
    
    //把参数放到请求体内
    NSString *postStr = [DBNetworkHelper parseParams:parameters];
    request.HTTPBody = [postStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        bb_dispatch_main_async_safe(^{
            if (error) { //请求失败
                failureBlock(error);
            } else {  //请求成功
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                successBlock(dic);
            }
        });
    }];
    [dataTask resume];  //开始请求
}

//重新封装参数 加入app相关信息
+ (NSString *)parseParams:(NSDictionary *)params
{
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithDictionary:params];
    [parameters setValue:@"ios" forKey:@"client"];
    [parameters setValue:@"请替换版本号" forKey:@"auth_version"];
    NSString* phoneModel = @"获取手机型号" ;
    NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];//ios系统版本号
    NSString *system = [NSString stringWithFormat:@"%@(%@)",phoneModel, phoneVersion];
    [parameters setValue:system forKey:@"system"];
    NSDate *date = [NSDate date];
    NSTimeInterval timeinterval = [date timeIntervalSince1970];
    [parameters setObject:[NSString stringWithFormat:@"%.0lf",timeinterval] forKey:@"auth_timestamp"];//请求时间戳
    NSString *devicetoken = @"请替换DeviceToken";
    [parameters setValue:devicetoken forKey:@"uuid"];
//    NSLog(@"请求参数:%@",parameters);

    NSString *keyValueFormat;
    NSMutableString *result = [NSMutableString new];
    //实例化一个key枚举器用来存放dictionary的key
   
   //加密处理 将所有参数加密后结果当做参数传递
   //parameters = @{@"i":@"加密结果 抽空加入"};
   
    NSEnumerator *keyEnum = [parameters keyEnumerator];
    id key;
    while (key = [keyEnum nextObject]) {
        keyValueFormat = [NSString stringWithFormat:@"%@=%@&", key, [params valueForKey:key]];
        [result appendString:keyValueFormat];
    }
    return result;
}

@end
