//
//  ViewController.m
//  RAC_Demo
//
//  Created by 董徐维 on 2018/3/1.
//  Copyright © 2018年 董徐维. All rights reserved.
//

#import "ViewController.h"

#import <ReactiveCocoa/ReactiveCocoa.h>


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (weak, nonatomic) IBOutlet UITextField *textfield;

@end

@implementation ViewController


//    /* 创建信号 */
//    RACSignal *signal = [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
//
//        /* 发送信号 */
//        [subscriber sendNext:@"发送信号"];
//
//        return nil;
//    }];
//
//    /* 订阅信号 */
//    RACDisposable *disposable = [signal subscribeNext:^(id  _Nullable x) {
//
//        NSLog(@"信号内容：%@", x);
//    }];
//
//    /* 取消订阅 */
//    [disposable dispose];

- (void)viewDidLoad {
    [super viewDidLoad];
    
    /* 创建信号 */
    RACSubject *subject = [RACSubject subject];
    
    /* 订阅信号（通常在别的视图控制器中订阅，与代理的用法类似） */
    [subject subscribeNext:^(id  _Nullable x) {
        
        NSLog(@"信号内容：%@", x);
        
        [self showalert];
    }];
    
    [[_button rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        NSLog(@"%@ 按钮被点击了", x); // x 是 button 按钮对象
        
        /* 发送信号 */
        [subject sendNext:@[@1,@3]];
        
    }];
    
    
    /* 创建元祖 */
    RACTuple *tuple = [RACTuple tupleWithObjects:@"1", @"2", @"3", @"4", @"5", nil];
    
    /* 从别的数组中获取内容 */
//    RACTuple *tuple = [RACTuple tupleWithObjectsFromArray:@[@"1", @"2", @"3", @"4", @"5"]];
    
    /* 利用 RAC 宏快速封装 */
//    RACTuple *tuple = RACTuplePack(@"1", @"2", @"3", @"4", @"5");
    
    NSLog(@"取元祖内容：%@", tuple[0]);
    NSLog(@"第一个元素：%@", [tuple first]);
    NSLog(@"最后一个元素：%@", [tuple last]);
    
    
    [[self.textfield rac_signalForControlEvents:UIControlEventEditingDidEnd] subscribeNext:^(id x){
        //x是textField对象
        NSLog(@"%@",x);
    }];
    
    [[self.textfield rac_textSignal]subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]init];
    
    [[tap rac_gestureSignal]subscribeNext:^(id x) {
        
        NSLog(@"%@",x);
        
    }];
    
    [self.view addGestureRecognizer:tap];
    
    
}


-(void)showalert{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"RAC" message:@"RAC TEST" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"other", nil];
    [[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *tuple) {
        NSLog(@"%@",tuple.first);
        NSLog(@"%@",tuple.second);
        NSLog(@"%@",tuple.third);
    }];
    [alertView show];
    
    //简化版
//    [[alertView rac_buttonClickedSignal] subscribeNext:^(id x) {
//        NSLog(@"%@",x);
//    }];
}

-(void)notification{
    NSMutableArray *dataArray = [[NSMutableArray alloc] initWithObjects:@"1", @"2", @"3", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"postData" object:dataArray];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"postData" object:nil] subscribeNext:^(NSNotification *notification) {
        NSLog(@"%@", notification.name);
        NSLog(@"%@", notification.object);
    }];
}

-(void)kvo{
    UIScrollView *scrolView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 200, 400)];
    scrolView.contentSize = CGSizeMake(200, 800);
    scrolView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:scrolView];
    [RACObserve(scrolView, contentOffset) subscribeNext:^(id x) {
        NSLog(@"success");
    }];
}

#pragma mark - 常见用法
- (void)RACMethod
{
    // ********************** 1、代替代理      **************************
    
    /**
     需求： 自定义redView，监听redView中按钮点击
     之前都是需要通过代理监听，给红色view添加一个代理属性，点击按钮的时候，通知代理做事情
     rac_signalForSelector:把调用某个对象的方法的信息转换成信号，只要调用这个方法，就会发送信号
     这里表示只要redView调用btnClick，就会发出信号，只需要订阅就可以了
     
     */
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 200, 375, 200)];
    [self.view addSubview:view];
    
    [[view rac_signalForSelector:@selector(btnClick:)] subscribeNext:^(id x) {
        NSLog(@"点击红色按钮---%@",x);
        
        //        怎么传值？？？？
        
    }];
    
    
    
    // ********************** 2、KVO      **************************
    [[view rac_valuesAndChangesForKeyPath:@"center" options:NSKeyValueObservingOptionNew observer:nil] subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    view.center = CGPointMake(100, 100);
    
    
    
    // ********************** 3、监听事件      **************************
    UIButton *btn           = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor     = [UIColor purpleColor];
    btn.frame               = CGRectMake(300, 300, 200, 30);
    [btn setTitle:@"RAC" forState:UIControlStateNormal];
    [self.view addSubview:btn];
    
    [[btn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(id x) {
        NSLog(@"按钮被点击了");
    }];
    
    
    // ********************** 4、代替通知      **************************
    //    把监听到的通知，转换成信号
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIKeyboardWillShowNotification object:nil] subscribeNext:^(id x) {
        NSLog(@"键盘弹出");
    }];
    
    
    // ********************** 5、监听文本框文字改变      **************************
    
    [self.textfield.rac_textSignal subscribeNext:^(id x) {
        NSLog(@"文字改变了---%@",x);
    }];
    
    
    // ********************** 6、处理多个请求，都返回结果的时候，统一做处理      **************************
    
    RACSignal *request1 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        [subscriber sendNext:@"发送请求1"];
        
        
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    RACSignal *request2 = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"发送请求2"];
        });
        
        return [RACDisposable disposableWithBlock:^{
            
        }];
    }];
    
    //    使用注意：几个信号，参数一的方法就必须有几个参数，每个参数对应信号发出的数据
    [self rac_liftSelector:@selector(wtkUpdateWithDic1:withDic2:) withSignalsFromArray:@[request1,request2]];
}

- (void)wtkUpdateWithDic1:(id )dic1 withDic2:(id )dic2
{
    NSLog(@"1--%@\n 2---%@",dic1,dic2);
}


#pragma mark - RAC常见宏

- (void)RACHong
{
    //    RAC(TARGET, [KEYPATH, [NIL_VALUE]]):用于给某个对象的某个属性绑定。
    RAC(self.button.titleLabel,text) = _textfield.rac_textSignal;
    
    
    
    //  RACObserve(self, name):监听某个对象的某个属性,返回的是信号
    
    [RACObserve(self.button.titleLabel, text) subscribeNext:^(id x) {
        NSLog(@"%@",x);
    }];
    
    
    //    @weakify(Obj)和@strongify(Obj),一般两个都是配套使用,在主头文件(ReactiveCocoa.h)中并没有导入，需要自己手动导入，RACEXTScope.h才可以使用。但是每次导入都非常麻烦，只需要在主头文件自己导入就好了。
    //    最新版库名 已换成  EXTScope
    //    两个配套使用，先weak再strong
    @weakify(self);
    //    @strongify(self);
    [RACObserve(self, self.button.titleLabel.text) subscribeNext:^(id x) {
        @strongify(self);
    }];
    
    
    //    RACTuplePack：把数据包装成RACTuple（元组类）
    //    把参数中的数据包装成元祖
    RACTuple *tuple = RACTuplePack(@10,@20);
    
    
    //    RACTupleUnpack：把RACTuple（元组类）解包成对应的数据。
    //    把参数再用的数据包装成元祖
    
}

@end
