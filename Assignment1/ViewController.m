//
//  ViewController.m
//  c8051intro3
//
//  Created by Borna Noureddin on 2017-12-20.
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "ViewController.h"

@interface ViewController() {
    Renderer *glesRenderer; // ###
    __weak IBOutlet UILabel *displacement;
    __weak IBOutlet UILabel *rotation;
}
@end


@implementation ViewController
- (IBAction)resetCube:(id)sender {
    [glesRenderer resetCube];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    // ### <<<
    glesRenderer = [[Renderer alloc] init];
    GLKView *view = (GLKView *)self.view;
    [glesRenderer setup:view];
    [glesRenderer loadModels];
    // ### >>>
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)update
{
    [glesRenderer update]; // ###
    displacement.text = [NSString stringWithFormat: @"Xd:%2.1f Yd:%2.1f Zd:%2.1f", [glesRenderer getXDisplacement], [glesRenderer getYDisplacement], [glesRenderer getZDisplacement]];
    rotation.text = [NSString stringWithFormat: @"Xr:%2.1f Yr:%2.1f Zd:%2.1f", [glesRenderer getXRotationAngle], [glesRenderer getYRotationAngle], 0.0f];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [glesRenderer draw:rect]; // ###
}


@end
