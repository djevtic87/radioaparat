//
//  MainTabBarControllerViewController.m
//  RadioAparat
//
//  Created by Dejan Jevtic on 11/12/17.
//  Copyright © 2017 Dejan Jevtic. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MainTabBarControllerViewController.h"
#import "InfoPlayView.h"
#import "AppDelegate.h"

//model
#import "YALTabBarItem.h"

//controller
#import "MainTabBarControllerViewController.h"

//helpers
#import "YALAnimatingTabBarConstants.h"

#define handle_tap(view, delegate, selector) do {\
    view.userInteractionEnabled = YES;\
    [view addGestureRecognizer: [[UITapGestureRecognizer alloc] initWithTarget:delegate action:selector]];\
} while(0)

@interface MainTabBarControllerViewController () {
    InfoPlayView *infoPlayView;
    AVPlayer* player;
}

@end

@implementation MainTabBarControllerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Add info view.
    CGRect rect = self.view.frame;
    rect.size.height = self.tabBar.frame.size.height;
    rect.origin.y = self.view.frame.size.height - self.tabBar.frame.size.height - rect.size.height;
    
    infoPlayView = [[[NSBundle mainBundle] loadNibNamed:@"InfoPlayView" owner:nil options:nil] lastObject];
    infoPlayView.frame = rect;
    
    infoPlayView.bottomImageViewConstraint.constant = IMAGE_VIEW_CONSTANT;
    infoPlayView.topImageViewConstraint.constant = IMAGE_VIEW_CONSTANT;
    infoPlayView.rightImageViewConstraint.constant = IMAGE_VIEW_CONSTANT;
    infoPlayView.leftImageViewConstraint.constant = infoPlayView.frame.size.width - infoPlayView.frame.size.height - IMAGE_VIEW_CONSTANT;
    infoPlayView.leftImageViewConstraintConstant = infoPlayView.leftImageViewConstraint.constant;
    
    [self.view addSubview:infoPlayView];
    
    // By default info view is hidden.
    [infoPlayView setHidden:true];
    
    [infoPlayView.downButton addTarget:self action:@selector(hidePlayInfoView:) forControlEvents:UIControlEventTouchUpInside];

    [infoPlayView.shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // Added guestures to hide and show music view info.
    UISwipeGestureRecognizer *swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hidePlayInfoView:)];
    [swipeGestureDown setNumberOfTouchesRequired:1];
    [swipeGestureDown setDirection:UISwipeGestureRecognizerDirectionDown];
    [infoPlayView addGestureRecognizer:swipeGestureDown];
    
    UISwipeGestureRecognizer *swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPlayInfoView:)];
    [swipeGestureUp setNumberOfTouchesRequired:1];
    [swipeGestureUp setDirection:UISwipeGestureRecognizerDirectionUp];
    [infoPlayView addGestureRecognizer:swipeGestureUp];
    
    // Added handler when user tap on infoPlayView
    handle_tap(infoPlayView, self, @selector(showPlayInfoView:));
    
    // Alloc radio player.
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithURL:[[NSURL alloc] initWithString:@"http://ca3.rcast.net:8060/"]];
    [playerItem addObserver:self forKeyPath:@"timedMetadata" options:NSKeyValueObservingOptionNew context:nil];
    player = [AVPlayer playerWithPlayerItem:playerItem];
    
    [self setupNowPlayingInfoCenter];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupNowPlayingInfoCenter {
    [UIApplication.sharedApplication beginReceivingRemoteControlEvents];

    MPRemoteCommandCenter *remoteCommandCenter = [MPRemoteCommandCenter sharedCommandCenter];
    [[remoteCommandCenter togglePlayPauseCommand] addTarget:self action:@selector(playPause)];
    [[remoteCommandCenter pauseCommand] addTarget:self action:@selector(playPause)];
    [[remoteCommandCenter playCommand] addTarget:self action:@selector(playPause)];
    [[remoteCommandCenter stopCommand] addTarget:self action:@selector(playPause)];
    
    [[remoteCommandCenter likeCommand] addTarget:self action:@selector(likeCurrentSong)];
//    [[remoteCommandCenter dislikeCommand] addTarget:self action:@selector(dislike)];
//    [[remoteCommandCenter bookmarkCommand] addTarget:self action:@selector(bookmark)];
//    [[remoteCommandCenter ratingCommand] addTarget:self action:@selector(ratingCommand)];
}

-(void)playPause {
    if ([self isAudioPlaying]) {
        [player pause];
        [self showInfoView:false];
        
        for (YALTabBarItem *item in self.leftBarItems) {
            item.leftImage = nil;
            item.rightImage = [UIImage imageNamed:@"play_icon"];
        }
        for (YALTabBarItem *item in self.rightBarItems) {
            item.leftImage = nil;
            item.rightImage = [UIImage imageNamed:@"play_icon"];
        }
    } else {
        [player play];
        [self showInfoView:true];
        
        for (YALTabBarItem *item in self.leftBarItems) {
            item.rightImage = [UIImage imageNamed:@"pause_icon"];
        }
        for (YALTabBarItem *item in self.rightBarItems) {
            item.rightImage = [UIImage imageNamed:@"pause_icon"];
        }
    }
    // Refresh the view.
    [self setSelectedIndex:self.selectedIndex];
}


-(BOOL) likeCurrentSong {
    AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    return [appDelegate.userDatabase storeSongForMetadata:infoPlayView.titleLabel.text];
}

-(BOOL)isAudioPlaying {
    if ((player.rate != 0) && (player.error == nil)) {
        return true;
    } else {
        return false;
    }
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
                         change:(NSDictionary*)change context:(void*)context {
    // Get track info data.
    if ([keyPath isEqualToString:@"timedMetadata"])
    {
        AVPlayerItem* playerItem = object;
        [infoPlayView updateViewWith:playerItem];
        [self showInfoView:true];
    }
}

- (void)shareButtonPressed:(id)sender {
    NSArray* sharedObjects=[NSArray arrayWithObjects:@"http://www.radioaparat.com/",  nil];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc]                                                                initWithActivityItems:sharedObjects applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:activityViewController animated:YES completion:nil];
}

-(void) showInfoView:(BOOL)show {
    if (!infoPlayView.expanded && ![infoPlayView.titleLabel.text isEqualToString:@""]) {
        [UIView transitionWithView:infoPlayView
                          duration:VIEW_ANIMATION_TIME
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [infoPlayView setHidden:!show];
                            if (show) {
                                for (YALTabBarItem *item in self.leftBarItems) {
                                    item.leftImage = [UIImage imageNamed:@"fav_icon"];
                                }
                                for (YALTabBarItem *item in self.rightBarItems) {
                                    item.leftImage = [UIImage imageNamed:@"fav_icon"];
                                }
                                // Refresh the view.
                                [self setSelectedIndex:self.selectedIndex];
                            }
                        }
                        completion:NULL];
        
    }
}

#pragma mark - InfoPlayView tap handler
- (void)hidePlayInfoView:(id)sender {
    [UIView animateWithDuration:VIEW_ANIMATION_TIME
                     animations:^{
                         [infoPlayView.titleLableLarge setHidden:true];
                         CGRect rect = self.view.frame;
                         rect.size.height = self.tabBar.frame.size.height;
                         rect.origin.y = self.view.frame.size.height - self.tabBar.frame.size.height - rect.size.height;
                         infoPlayView.frame = rect;
                         infoPlayView.expanded = false;
                     }
                     completion:^(BOOL finished) {
                         // whatever you need to do when animations are complete
                         if ([self isAudioPlaying]) {
                             [self showInfoView:true];
                         } else {
                             [self showInfoView:false];
                         }
                     }];
}

- (void)showPlayInfoView:(id)sender {
    if (!infoPlayView.expanded) {
        // Expand view.
        [UIView animateWithDuration:VIEW_ANIMATION_TIME
                         animations:^{
                             CGRect frame = infoPlayView.frame;
                             frame.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
                             frame.size.height = self.view.frame.size.height - frame.origin.y - self.tabBar.frame.size.height;
                             infoPlayView.frame = frame;
                             infoPlayView.expanded = true;
                         }
                         completion:^(BOOL finished){
                             [infoPlayView.titleLableLarge setHidden:false];
                             // whatever you need to do when animations are complete
                         }];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
