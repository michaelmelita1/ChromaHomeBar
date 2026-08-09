#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

static const CGFloat waveSpeed = 0.05;
static NSString * const waveDirection = @"l2r";


@interface MTLumaDodgePillView : UIView
@end

@interface MTStaticColorPillView : UIView {
    UIColor * _pillColor;
}
@property (nonatomic, retain) UIColor *pillColor;
@end

@interface ColorPillView : UIView <CAAnimationDelegate>
@property (nonatomic, strong) NSMutableArray *colors;
@property (nonatomic, strong) NSTimer *timer;
- (void)waveView;
@end

@implementation ColorPillView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.backgroundColor = [[UIColor alloc] initWithHue:0 saturation:1 brightness:1 alpha:1].CGColor;

        CAGradientLayer *layer = (id)[self layer];
        [layer setStartPoint:CGPointMake(0.0, 0.5)];
        [layer setEndPoint:CGPointMake(1.0, 0.5)];

        self.colors = [NSMutableArray array];
        for (CGFloat hue = 0; hue <= 360; hue += 1) {
            UIColor *color = [UIColor colorWithHue:1.0 * hue / 360.0
                                         saturation:1.0
                                         brightness:1.0
                                              alpha:1.0];
            [self.colors addObject:(id)[color CGColor]];
        }
    }
    return self;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (void)waveView {
    self.timer = [NSTimer timerWithTimeInterval:waveSpeed repeats:YES block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CAGradientLayer *layer = (id)[self layer];
            NSMutableArray *mutableArray = self.colors;
            if ([waveDirection isEqualToString:@"l2r"]) {
                id lastColor = [mutableArray lastObject];
                [mutableArray removeLastObject];
                [mutableArray insertObject:lastColor atIndex:0];
            } else if ([waveDirection isEqualToString:@"r2l"]) {
                id firstColor = [mutableArray firstObject];
                [mutableArray removeObjectAtIndex:0];
                [mutableArray addObject:firstColor];
            }
            NSArray *itemsForView = [mutableArray subarrayWithRange:NSMakeRange(0, mutableArray.count / 6)];
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

%hook MTLumaDodgePillView
- (void)layoutSubviews {
    %orig;
    int tag = 115;
    UIView *colorView = [self viewWithTag:tag];
    if (!colorView) {
        [self setClipsToBounds:YES];
        ColorPillView *newColorView = [[ColorPillView alloc] initWithFrame:self.bounds];
        newColorView.tag = tag;
        [self addSubview:newColorView];
        [newColorView waveView];

        [newColorView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"H:|-0-[newColorView]-0-|"
                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                 metrics:nil
                                   views:NSDictionaryOfVariableBindings(newColorView)]];
        [self addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:|-0-[newColorView]-0-|"
                                 options:NSLayoutFormatDirectionLeadingToTrailing
                                 metrics:nil
                                   views:NSDictionaryOfVariableBindings(newColorView)]];
        colorView = newColorView;
    }
    colorView.layer.cornerRadius = self.frame.size.height / 2;
}
%end

%hook MTStaticColorPillView
- (void)layoutSubviews {
    %orig;
    int tag = 115;
    UIView *colorView = [self viewWithTag:tag];
    if (!colorView) {
        ColorPillView *newColorView = [[ColorPillView alloc] initWithFrame:self.bounds];
        newColorView.tag = tag;
        newColorView.layer.cornerRadius = self.bounds.size.height / 2;
        [self addSubview:newColorView];
        [newColorView waveView];
        colorView = newColorView;
    }
    CGRect frame = colorView.frame;
    frame.size.height = self.frame.size.height;
    frame.size.width = self.frame.size.width;
    colorView.layer.cornerRadius = self.frame.size.height / 2;
    colorView.frame = frame;
}
%end
