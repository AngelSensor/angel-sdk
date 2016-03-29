
@interface NSObject (BSUserDefaults)


#pragma mark - Update Objects

- (void)bs_updateObject:(id)object forKey:(NSString*)key;
- (void)bs_updateBool:(BOOL)object forKey:(NSString*)key;
- (void)bs_updateInteger:(NSInteger)object forKey:(NSString*)key;


#pragma mark - Retrive Objects

- (id)bs_objectForKey:(NSString*)key;
- (NSString*)bs_stringForKey:(NSString*)key;
- (BOOL)bs_boolForKey:(NSString*)key;
- (NSInteger)bs_integerForKey:(NSString*)key;

@end
