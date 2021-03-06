//
//  Song.m
//  RadioAparat
//
//  Created by Dejan Jevtic on 11/28/17.
//  Copyright © 2017 Dejan Jevtic. All rights reserved.
//

#import "Song.h"
#import "LastFm.h"
#import "UIImageView+AFNetworking.h"

#define kApiKey @"ce9a96e3f484167e5bd81c663610a568"
#define kApiSecret @"e967e63c5ced2da3be1e939ddd1a49b9"


@implementation Song
@synthesize title;
@synthesize artist;
@synthesize album;
@synthesize metadataStringValue;
@synthesize songImage;

- (instancetype)initWithMetadata:(NSString*) metadata
{
    self = [super init];
    if (self) {
        [LastFm sharedInstance].apiKey = kApiKey;
        [LastFm sharedInstance].apiSecret = kApiSecret;
        //[LastFm sharedInstance].session = session;
        //[LastFm sharedInstance].username = username;

        self.metadataStringValue = metadata;
        NSLog(@"metadataStringValue: %@", metadataStringValue);
        
        NSUInteger index = [metadataStringValue rangeOfString:@"-"].location;
        if (index != NSNotFound) {
            self.artist = [metadataStringValue substringToIndex:index];
            self.title = [metadataStringValue substringFromIndex:index + 1];
            self.artist = [artist stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
            self.title = [self.title stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
        } else {
            self.title = @"";
            self.artist = @"";
            self.album = @"";
        }
        
    }
    return self;
}

-(void) setSongImageInImageView:(UIImageView* )imageView {
    // Check if the image is already downloaded.
    if (self.songImage) {
        [imageView setImage:self.songImage];
        return;
    }
    
    [imageView setImage:[UIImage imageNamed:@"RadioAparat.png"]];
    
    [[LastFm sharedInstance] getInfoForTrack:self.title artist:self.artist successHandler:^(NSDictionary *result) {
        NSLog(@"result: %@", result);
        self.title = [result objectForKey:@"name"];
        self.artist = [result objectForKey:@"artist"];
        self.album = [result objectForKey:@"album"];
        self.imageURL = [result objectForKey:@"image"];
    
        if (self.imageURL != nil) {
            __weak UIImageView *weakImageView = imageView;
            [imageView setImageWithURLRequest:[NSURLRequest requestWithURL:self.imageURL]
                                  placeholderImage:[UIImage imageNamed:@"RadioAparat.png"]
                                           success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                               UIImageView *strongImageView = weakImageView; // make local strong reference to protect against race conditions
                                               if (!strongImageView) return;
                                               
                                               [UIView transitionWithView:strongImageView
                                                                 duration:0.3
                                                                  options:UIViewAnimationOptionTransitionCrossDissolve
                                                               animations:^{
                                                                   strongImageView.image = image;
                                                                   self.songImage = image;
                                                                   [self updateNowPlayingInfoCenter:self.title
                                                                                          forArtist:self.artist
                                                                                      forAlbumTitle:self.album
                                                                                           forImage:self.songImage];
                                                               }
                                                               completion:NULL];
                                           }
                                           failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                               NSLog(@"Error: %@", error.description);
                                               [self updateNowPlayingInfoCenter:self.title
                                                                      forArtist:self.artist
                                                                  forAlbumTitle:self.album
                                                                       forImage:[UIImage imageNamed:@"RadioAparat.png"]];
                                           }];
        } else {
            NSLog(@"No image URL found!");
            [self updateNowPlayingInfoCenter:self.title
                                   forArtist:self.artist
                               forAlbumTitle:self.album
                                    forImage:self.songImage];
        }
    } failureHandler:^(NSError *error) {
        [imageView setImage:[UIImage imageNamed:@"RadioAparat.png"]];
        [self updateNowPlayingInfoCenter:self.title
                               forArtist:self.artist
                           forAlbumTitle:self.album
                                forImage:[UIImage imageNamed:@"RadioAparat.png"]];
        NSLog(@"Error getting track info: %@", error.description);
    }];
}

-(void)updateNowPlayingInfoCenter:(NSString*)title forArtist:(NSString*)artist forAlbumTitle:(NSString*)albumTitle forImage:(UIImage*)artwork {
    NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];
    MPMediaItemArtwork *albumArt = [[MPMediaItemArtwork alloc] initWithBoundsSize:CGSizeMake(100, 100) requestHandler:^(CGSize size) { return artwork; }];
    NSLog(@"updateNowPlayingInfoCenter title: %@, artist: %@, albumTitle: %@", title, artist, albumTitle);
    
    if (self.title != nil) {
        [songInfo setObject:title forKey:MPMediaItemPropertyTitle];
    } else {
        self.title = self.metadataStringValue;
    }
    
    if (self.artist != nil) {
        [songInfo setObject:artist forKey:MPMediaItemPropertyArtist];
    }
    
    if (self.album != nil) {
        [songInfo setObject:albumTitle forKey:MPMediaItemPropertyAlbumTitle];
    }

    [songInfo setObject:albumArt forKey:MPMediaItemPropertyArtwork];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
}

@end
