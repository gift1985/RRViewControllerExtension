//
//  UINavigationController+RRSet.m
//  Pods-RRUIViewControllerExtention_Example
//
//  Created by 罗亮富(Roen) on.
//

#import "UINavigationController+RRSet.h"
#import <objc/runtime.h>

#define kNavigationCompletionBlockKey @"completionBlk"
static UIImage *sNavigationBarTransparentImage;

@implementation UINavigationController (RRSet)

+(void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL originalSelector = @selector(navigationTransitionView:didEndTransition:fromView:toView:);
        SEL swizzledSelector = @selector(mob_navigationTransitionView:didEndTransition:fromView:toView:);
        method_exchangeImplementations(class_getInstanceMethod(class, originalSelector), class_getInstanceMethod(class, swizzledSelector));
#pragma clang diagnostic pop
        
        // for debug useage, to get the system selector message signature
        //   NSMethodSignature *sig = [class instanceMethodSignatureForSelector:originalSelector];
        //   NSLog(@"NSMethodSignature for originalSelector is %@",sig);

    });
}

#pragma mark- appearance

-(NSMutableDictionary *)navigationBarAppearanceDic
{
    NSMutableDictionary *mDic = objc_getAssociatedObject(self, @"appearanceDic");
    if(!mDic)
    {
        mDic = [NSMutableDictionary dictionaryWithCapacity:6];
        objc_setAssociatedObject(self, @"appearanceDic", mDic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return mDic;
}

-(BOOL)defaultNavigationBarHidden
{
    return [[self.navigationBarAppearanceDic objectForKey:@"barHidden"] boolValue];
}

-(void)setDefaultNavigationBarHidden:(BOOL)hidden
{
    [self.navigationBarAppearanceDic setObject:[NSNumber numberWithBool:hidden] forKey:@"barHidden"];
}

-(BOOL)defaultNavigationBarTransparent
{
    return [[self.navigationBarAppearanceDic objectForKey:@"transparent"] boolValue];
}

-(void)setDefaultNavigationBarTransparent:(BOOL)transparent
{
    [self.navigationBarAppearanceDic setObject:[NSNumber numberWithBool:transparent] forKey:@"transparent"];
}

-(UIColor *)defaultNavatationBarColor
{
    return  [[self.navigationBarAppearanceDic objectForKey:@"barColor"] copy];
}

-(void)setDefaultNavatationBarColor:(UIColor *)c
{
    if(c)
        [self.navigationBarAppearanceDic setObject:[c copy] forKey:@"barColor"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"barColor"];
}

-(UIColor *)defaultNavigationItemColor
{
    return  [[self.navigationBarAppearanceDic objectForKey:@"ItmColor"] copy];
}

-(void)setDefaultNavigationItemColor:(UIColor *)c
{
    if(c)
        [self.navigationBarAppearanceDic setObject:[c copy] forKey:@"ItmColor"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"ItmColor"];
}

-(UIImage *)defaultNavigationBarBackgroundImage
{
    return [self.navigationBarAppearanceDic objectForKey:@"barImage"];
}

-(void)setDefaultNavigationBarBackgroundImage:(UIImage *)img
{
    if(img)
        [self.navigationBarAppearanceDic setObject:img forKey:@"barImage"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"barImage"];
}

-(NSDictionary *)defaultNavigationTitleTextAttributes
{
    return [[self.navigationBarAppearanceDic objectForKey:@"TitleAttr"] copy];
}

-(void)setDefaultNavigationTitleTextAttributes:(NSDictionary *)attrDic
{
    if(attrDic)
        [self.navigationBarAppearanceDic setObject:[attrDic copy] forKey:@"TitleAttr"];
    else
        [self.navigationBarAppearanceDic removeObjectForKey:@"TitleAttr"];
}


#pragma mark- transparent
-(void)setNavigationBarTransparent:(BOOL)transparent
{
    if(transparent == self.navigationBarTransparent)
        return;
    
    UIImage *img = nil;
    
    if(transparent)
    {
        if(!sNavigationBarTransparentImage)
        {
            CGRect rect = CGRectMake(0, 0, 1, 1);
            
            UIGraphicsBeginImageContext(rect.size);
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context,[UIColor clearColor].CGColor);
            CGContextFillRect(context, rect);
            sNavigationBarTransparentImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
        img = sNavigationBarTransparentImage;
    }
    
    [self.navigationBar setBackgroundImage:img forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setShadowImage:img];
    
}

-(BOOL)isNavigationBarTransparent
{
    UIImage *bgImage = [self.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault];
    return [bgImage isEqual:sNavigationBarTransparentImage];
}


#pragma mark- push/pop completion block

-(void)setCompletionBlock:(void (^ __nullable)(void))completion
{
    objc_setAssociatedObject(self, kNavigationCompletionBlockKey, completion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
-(void)mob_navigationTransitionView:(id)obj1 didEndTransition:(long)b fromView:(id)v1 toView:(id)v2
{
    [self mob_navigationTransitionView:obj1 didEndTransition:b fromView:v1 toView:v2];

    void (^ cmpltBlock)(void) = objc_getAssociatedObject(self, kNavigationCompletionBlockKey);
    if(cmpltBlock)
        cmpltBlock();

    [self setCompletionBlock:nil];
}

//-(void)setApplyGlobalConfig:(BOOL)applyGlobalConfig
//{
//    objc_setAssociatedObject(self, kNavigationControllerApplyGlobalConfigKey, [NSNumber numberWithBool:applyGlobalConfig], OBJC_ASSOCIATION_COPY_NONATOMIC);
//}
//
//-(BOOL)applyGlobalConfig
//{
//    NSNumber *boolNum = objc_getAssociatedObject(self, kNavigationControllerApplyGlobalConfigKey);
//    return boolNum.boolValue;
//}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    [self pushViewController:viewController animated:animated];
}

- (nullable UIViewController *)popViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popViewControllerAnimated:animated];
}

- (nullable NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popToViewController:viewController animated:animated];
}

- (nullable NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated completionBlock:(void (^ __nullable)(void))completion
{
    [self setCompletionBlock:completion];
    return [self popToRootViewControllerAnimated:animated];
}





@end

const char naviagionItemStackKey = 'a';

@implementation UINavigationItem (StatusStack)

-(NSMutableArray *)statusStack
{
    NSMutableArray *stack = objc_getAssociatedObject(self, &naviagionItemStackKey);
    if(!stack)
    {
        stack = [NSMutableArray arrayWithCapacity:3];
        objc_setAssociatedObject(self, &naviagionItemStackKey, stack, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return stack;
}

-(void)popStatus
{
    NSMutableDictionary *mdic = [[self statusStack] lastObject];
    if(mdic)
    {
        self.rightBarButtonItems = [mdic objectForKey:@"rightBarButtonItems"];
        self.leftBarButtonItems = [mdic objectForKey:@"leftBarButtonItems"];
        self.backBarButtonItem = [mdic objectForKey:@"backBarButtonItem"];
        self.titleView = [mdic objectForKey:@"titleView"];
        self.title = [mdic objectForKey:@"title"];
        
        [[self statusStack] removeObject:mdic];
    }
}

-(void)pushStatus
{
    NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithCapacity:5];
    
    if(self.rightBarButtonItems)
        [mdic setObject:self.rightBarButtonItems forKey:@"rightBarButtonItems"];
    if(self.leftBarButtonItems)
        [mdic setObject:self.leftBarButtonItems forKey:@"leftBarButtonItems"];
    if(self.backBarButtonItem)
        [mdic setObject:self.backBarButtonItem forKey:@"backBarButtonItem"];
    if(self.titleView)
        [mdic setObject:self.titleView forKey:@"titleView"];
    if(self.title)
        [mdic setObject:self.title forKey:@"title"];
    
    [[self statusStack] addObject:mdic];
}

@end
