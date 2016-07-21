//
//  ViewController.m
//  MixDemo
//
//  Created by William on 16/7/21.
//  Copyright © 2016年 William. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic,strong) NSURL *fileURL;

@property (nonatomic,strong) UISlider *slider;

@end

@implementation ViewController
{
    AVAudioEngine           *_engine;
    AVAudioUnitReverb       *_reverb;
    AVAudioPlayerNode       *_player;
    AVAudioPCMBuffer        *_playerLoopBuffer;
}
//https://developer.apple.com/library/ios/samplecode/AVAEMixerSample/Introduction/Intro.html#//apple_ref/doc/uid/TP40015134
- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"林俊杰 - 她说" ofType:@"mp3"];
    self.fileURL = [NSURL fileURLWithPath:filePath];
    
    [self setup];
    
    [self creatUI];
}

- (void)initSession
{
    AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
    NSError *error;
    // set the session category
    bool success = [sessionInstance setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (!success) NSLog(@"Error setting AVAudioSession category! %@\n", [error localizedDescription]);
    double hwSampleRate = 44100.0;
    success = [sessionInstance setPreferredSampleRate:hwSampleRate error:&error];
    if (!success) NSLog(@"Error setting preferred sample rate! %@\n", [error localizedDescription]);
    
    NSTimeInterval ioBufferDuration = 0.0029;
    success = [sessionInstance setPreferredIOBufferDuration:ioBufferDuration error:&error];
    if (!success) NSLog(@"Error setting preferred io buffer duration! %@\n", [error localizedDescription]);
     [sessionInstance setActive:YES error:&error];
}

- (void)creatUI
{
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    [btn setBackgroundColor:[UIColor orangeColor]];
    [btn addTarget:self action:@selector(togglePlayer) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.slider = [[UISlider alloc] initWithFrame:CGRectMake(0, 100, 150, 15)];
    [self.view addSubview:self.slider];
    self.slider.minimumValue = 0.0;
    self.slider.maximumValue = 100.0;
    [self.slider addTarget:self action:@selector(changeReverb:) forControlEvents:UIControlEventValueChanged];
    
    NSArray *nameAry = @[@"小房间",
                         @"中等房间",
                         @"大房间",
                         @"中厅",
                         @"大厅",
                         @"板",
                         @"介质室",
                         @"大室",
                         @"教堂"];
    for (int i = 0; i < nameAry.count; i++)
    {
        UIButton *btn = [[UIButton alloc]init];
        [btn addTarget:self action:@selector(changeReverbType:) forControlEvents:UIControlEventTouchUpInside];
        btn.tag = i;
        [btn setBackgroundColor:[UIColor blueColor]];
        [btn setTitle:nameAry[i] forState:UIControlStateNormal];
        btn.titleLabel.adjustsFontSizeToFitWidth = YES;
        if (i < 3)
        {
            btn.frame = CGRectMake(150+85*i, 100, 80, 80);
        }
        else if(i<6)
        {
            btn.frame = CGRectMake(150+85*(i-3), 200, 80, 80);
        }
        else
        {
            btn.frame = CGRectMake(150+85*(i-6), 300, 80, 80);
        }
        [self.view addSubview:btn];
    }
}

- (void)startEngine
{
    if (!_engine.isRunning) {
        NSError *error;
        BOOL success;
        success = [_engine startAndReturnError:&error];
        NSAssert(success, @"couldn't start engine, %@", [error localizedDescription]);
    }
}

- (void)setup
{
    [self initSession];
    _player = [[AVAudioPlayerNode alloc]init];
    _reverb = [[AVAudioUnitReverb alloc] init];
    NSError *error;
    AVAudioFile *file = [[AVAudioFile alloc]initForReading:self.fileURL error:&error];
    _playerLoopBuffer = [[AVAudioPCMBuffer alloc]initWithPCMFormat:[file processingFormat] frameCapacity:(AVAudioFrameCount)[file length]];
    [file readIntoBuffer:_playerLoopBuffer error:&error];
    
    [self createEngineAndAttachNodes];
    
    [self makeEngineConnections];

    [_reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumHall];
    _reverb.wetDryMix = 0;
    [self startEngine];
}

- (void)createEngineAndAttachNodes
{
    _engine = [[AVAudioEngine alloc] init];
    [_engine attachNode:_reverb];
    [_engine attachNode:_player];

}

- (void)makeEngineConnections
{

    AVAudioMixerNode *mainMixer = [_engine mainMixerNode];
    
    AVAudioFormat *stereoFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:44100 channels:2];
    
    // establish a connection between nodes
    
    // connect the player to the reverb
    [_engine connect:_player to:_reverb format:stereoFormat];
    
    // connect the reverb effect to mixer input bus 0
    [_engine connect:_reverb to:mainMixer fromBus:0 toBus:0 format:stereoFormat];
}

#pragma mark - buttonSelecter
- (void)togglePlayer
{
    if (![_player isPlaying])
    {
        [self startEngine];
        [_player scheduleBuffer:_playerLoopBuffer atTime:nil options:AVAudioPlayerNodeBufferLoops completionHandler:nil];
        [_player play];
    }
    else
    {
        [_player pause];
    }
}

- (void)changeReverbType:(UIButton *)button
{
    [_reverb loadFactoryPreset:button.tag];
}

- (void)changeReverb:(UISlider *)slider
{
    _reverb.wetDryMix = slider.value;
    
}
@end
