#import <QuartzCore/QuartzCore.h>

static NSUInteger totalColors = 2;


static NSMutableDictionary *settings;
BOOL enabled = YES;
NSString *style = @"Wave";
UIColor *firstColor = [UIColor blueColor];
UIColor *secondColor = [UIColor redColor];

CGFloat waveSpeed = 0.02;
CGFloat waveOpacity = 1;
CGFloat homeBarOpacity = 1;
NSString *waveDirection = @"l2r";

@interface MTLumaDodgePillView : UIView
@end

@interface MTStaticColorPillView : UIView {
    UIColor * _pillColor;
}

@property (nonatomic, retain) UIColor *pillColor;

@end

/////////////////////////////

@interface ColorPillView : UIView <CAAnimationDelegate>

@property (nonatomic, assign) NSUInteger colorNum;
@property (nonatomic, assign) NSUInteger currentHueNum;
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSTimer *timer;

- (void)waveView;

@end

@implementation ColorPillView

- (instancetype)initWithFrame:(CGRect)frame {
    self  = [super initWithFrame:frame];
    if (self) {
        _colorNum = 0;
        _currentHueNum = 0;
        self.layer.backgroundColor = staticColor.CGColor;
        self.layer.backgroundColor = [[UIColor alloc] initWithHue:_currentHueNum/360.0f saturation:1 brightness:1 alpha:1].CGColor;
        CAGradientLayer *layer = (id)[self layer];
        [layer setStartPoint:CGPointMake(0.0, 0.5)];
        [layer setEndPoint:CGPointMake(1.0, 0.5)];

        // Create colors using hues in +5 increments
        self.colors = [NSMutableArray array];
        for (CGFloat hue = 0; hue <= 360; hue += 1) {
            UIColor *color;
            color = [UIColor colorWithHue:1.0 * hue / 360.0
                               saturation:1.0
                               brightness:1.0
                                    alpha:1.0];
            [self.colors addObject:(id)[color CGColor]];
        }
    }

    return self;
}

- (void)animateView {
    self.colorNum++;
    self.colorNum = self.colorNum % totalColors;
    UIColor *newColor = firstColor;
    if (self.colorNum == 1) {
        newColor = secondColor;
    }

    __weak ColorPillView *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.0
                         animations:^{
                             weakSelf.layer.backgroundColor = newColor.CGColor;
                         }
                         completion:^(BOOL finished) {
                             [weakSelf animateView];
                         }];
    });
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (void)waveView {
  /*
    // Move the last color in the array to the front
    // shifting all the other colors.
    CAGradientLayer *layer = (id)[self layer];
    NSMutableArray *mutableArray = self.colors;
    NSArray *itemsForView = [mutableArray subarrayWithRange: NSMakeRange( 0, mutableArray.count / 6 )];

    // Update the colors on the model layer
    [layer setColors:itemsForView];
    [layer setDrawsAsynchronously:YES];

    // Create an animation to slowly move the gradient left to right.
    CABasicAnimation *animation;
    animation = [CABasicAnimation animationWithKeyPath:@"colors"];
    [animation setToValue:itemsForView];
    [animation setDuration:0.01];
    [animation setRemovedOnCompletion:YES];
    [animation setFillMode:kCAFillModeForwards];
    [animation setDelegate:self];
    [layer removeAllAnimations];
    [layer addAnimation:animation forKey:@"animateGradient"];
    */

    self.timer = [NSTimer timerWithTimeInterval:waveSpeed repeats:YES block:^(NSTimer * _Nonnull timer) {
        //__weak UIView *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            CAGradientLayer *layer = (id)[self layer];
            NSMutableArray *mutableArray = self.colors;
              id lastColor = [mutableArray lastObject];
              [mutableArray removeLastObject];
              [mutableArray insertObject:lastColor atIndex:0];

            NSArray *itemsForView = [mutableArray subarrayWithRange: NSMakeRange( 0, mutableArray.count / 6 )];

            // Update the colors on the model layer
            [layer setColors:itemsForView];
            [layer setDrawsAsynchronously:YES];
        });
    }];

    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    [self.timer fire];
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag {
    [self waveView];
}

@end

////////////////////////////

/*%hook SpringBoard
 -(void) applicationDidFinishLaunching:(id)arg {
 %orig(arg);
 UIAlertView *lookWhatWorks = [[UIAlertView alloc] initWithTitle:@"HomeBar Color Tweak"
 message:[@"Loaded!!\nFucking Awesome: " stringByAppendingString:style]
 delegate:self
 cancelButtonTitle:@"OK"
 otherButtonTitles:nil];
 [lookWhatWorks show];
 }
 %end*/


%hook MTLumaDodgePillView
-(void)initWithFrame:(CGRect)arg1{
    %orig(arg1);
    //self.alpha = 1;
}

-(void)layoutSubviews{
    %orig;

    if (enabled) {

        int tag = 115;

        UIView *colorView = [self viewWithTag:tag];
        if (!colorView) {
            refreshPrefs();
            [self setClipsToBounds:YES];

            ColorPillView *colorView = [[ColorPillView alloc] initWithFrame:self.bounds];
            colorView.tag = 115;
            //colorView.backgroundColor = [UIColor redColor];
            colorView.colorNum = 0;
            [self addSubview:colorView];
            [colorView waveView];
            self.alpha = homeBarOpacity;

            [colorView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|-0-[colorView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(colorView)]];
            [self addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|-0-[colorView]-0-|"
                                   options:NSLayoutFormatDirectionLeadingToTrailing
                                   metrics:nil
                                   views:NSDictionaryOfVariableBindings(colorView)]];
        }

        colorView.layer.cornerRadius = self.frame.size.height / 2
    }

}

%new
-(void)animateView{
    int tag = 115;

    ColorPillView *colorView = [self viewWithTag:tag];

    UIColor *newColor = [UIColor blueColor];
    if (colorView.colorNum == 1) {
        newColor = [UIColor redColor];
        colorView.colorNum = 0;
    } else {
        newColor = [UIColor blueColor];
        colorView.colorNum = 1;
    }

    __weak UIView *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:10.0
                         animations:^{
                             colorView.backgroundColor = newColor;
                         }
                         completion:^(BOOL finished) {
                             colorView.backgroundColor = newColor;
                             [weakSelf performSelector:@selector(animateView)];
                         }];
    });
}

%end


%hook MTStaticColorPillView
-(void)initWithFrame:(CGRect)arg1{
    %orig(arg1);
    //self.alpha = 1;
}

-(void)layoutSubviews{
    %orig;

    if (enabled) {

        int tag = 115;

        UIView *colorView = [self viewWithTag:tag];
        if (!colorView) {
            refreshPrefs();
            ColorPillView *colorView = [[ColorPillView alloc] initWithFrame:self.bounds];
            colorView.tag = 115;
            colorView.layer.cornerRadius = self.bounds.size.height / 2;
            colorView.backgroundColor = [UIColor redColor];
            colorView.colorNum = 0;
            [self addSubview:colorView];
                [colorView waveView];

            self.alpha = homeBarOpacity;

        CGRect frame = colorView.frame;
        frame.size.height = self.frame.size.height;
        frame.size.width = self.frame.size.width;
        colorView.layer.cornerRadius = self.frame.size.height / 2;
        colorView.frame = frame;
    }
}

%end
