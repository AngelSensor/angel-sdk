

#import "NSObject+BSUserDefaults.h"
#import "BSHelperFunctions.h"

@implementation NSObject (BSUserDefaults)


#pragma mark - Update Objects

- (void)bs_updateObject:(id)object forKey:(NSString*)key
{
    if (!BSIsEmpty(key))
    {
        if (object)
        {
            [[self bs_dataSource] setObject:object forKey:key];
        }
        else
        {
            [[self bs_dataSource] removeObjectForKey:key];
        }
        [[self bs_dataSource] synchronize];
    }
}

- (void)bs_updateBool:(BOOL)object forKey:(NSString*)key
{
    if (!BSIsEmpty(key))
    {
        [[self bs_dataSource] setBool:object forKey:key];
        [[self bs_dataSource] synchronize];
    }
}

- (void)bs_updateInteger:(NSInteger)object forKey:(NSString*)key
{
    if (!BSIsEmpty(key))
    {
        [[self bs_dataSource] setInteger:object forKey:key];
        [[self bs_dataSource] synchronize];
    }
}


#pragma mark - Retrive Objects

- (id)bs_objectForKey:(NSString*)key
{
    id object;
    if (!BSIsEmpty(key))
    {
        object = [[self bs_dataSource] objectForKey:key];
    }
    return object;
}

- (NSString*)bs_stringForKey:(NSString*)key
{
    NSString* string = [self bs_objectForKey:key];
    return [NSString stringWithFormat:@"%@", string ? : @""];
}

- (BOOL)bs_boolForKey:(NSString*)key
{
    BOOL value = NO;
    if (!BSIsEmpty(key))
    {
       value = [[self bs_dataSource] boolForKey:key];
    }
    return value;
}

- (NSInteger)bs_integerForKey:(NSString*)key
{
    NSInteger value = 0;
    if (!BSIsEmpty(key))
    {
        value = [[self bs_dataSource] integerForKey:key];
    }
    return value;
}


#pragma mark - Private

- (NSUserDefaults *)bs_dataSource
{
    return [NSUserDefaults standardUserDefaults];
}

@end
