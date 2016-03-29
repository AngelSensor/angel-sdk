/*
 * Copyright (c) 2016, Seraphim Sense Ltd.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions
 *    and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other materials provided
 *    with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to
 *    endorse or promote products derived from this software without specific prior written
 *    permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ANPlaygroundViewController.h"
#import "ANPlaygroundEditViewController.h"
#import "ANRootNavigationController.h"
#import "ANPlaygroundCell.h"
#import "ANPlayground.h"
#import "DejalActivityView.h"

typedef enum {
    AlertViewTagNone,
    AlertViewTagRemove
} AlertViewTag;

@interface ANPlaygroundViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *dataContainer;

@property (nonatomic, strong) NSIndexPath *selectedRemoveIndexPath;

@end

@implementation ANPlaygroundViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark Interface Actions

- (IBAction)addButtonPressed:(id)sender {
    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"playgroundEditViewController" animated:YES];
}

#pragma mark Playground actions

- (IBAction)removePlaygroundButtonPressed:(UIButton *)sender {
    self.selectedRemoveIndexPath = [self.tableView indexPathForCell:[self cellFromControl:sender]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to remove this playground?", nil) delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert setTag:AlertViewTagRemove];
    [alert show];
    
}


- (void)removeSelectedPlayground {
    ANPlayground *playground = [self.dataContainer objectAtIndex:self.selectedRemoveIndexPath.row];
    [self.tableView beginUpdates];
    [DejalBezelActivityView activityViewForView:self.view];
    [[ANDataManager sharedManager] removePlayground:playground completionHandler:^(BOOL success, NSError *error) {
        if (success && !error) {
            [self.tableView deleteRowsAtIndexPaths:@[self.selectedRemoveIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            //show alert
        }
        [self.tableView endUpdates];
        self.selectedRemoveIndexPath = nil;
        [DejalBezelActivityView removeViewAnimated:NO];
    }];
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        switch (alertView.tag) {
            case AlertViewTagRemove: {
                [self removeSelectedPlayground];
            } break;
            default: {
                
            } break;
        }
    }
}

#pragma mark UITableView dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataContainer.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANPlaygroundCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    ANPlayground *playground = [self.dataContainer objectAtIndex:indexPath.row];
    
    cell.typeLabel.text = playground.playgroundCompareValue ? [NSString stringWithFormat:@"%@ %@%@", [ANEnumManager stringFromPlaygroundCompareType:playground.playgroundCompareType], playground.playgroundCompareValue, [ANEnumManager unitFromPlaygroundType:playground.playgroundType]] : nil;
    cell.vibrateLabel.text = [ANEnumManager stringFromVibrateMode:playground.playgroundVibrateMode];
    cell.ledLabel.text = [ANEnumManager stringFromLedMode:playground.playgroundLedMode];
    cell.soundLabel.text = playground.playgroundSoundID ? [NSString stringWithFormat:@"Sound %@", playground.playgroundSoundID] : nil;
    
    //cell.typeImageView.image = image for type
    
    return cell;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    ANPlaygroundEditViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"playgroundEditViewController"];
    controller.playground = [self.dataContainer objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:controller animated:YES];
}

- (ANPlaygroundCell *)cellFromControl:(UIControl *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[ANPlaygroundCell class]])) {
        view = view.superview;
    }
    ANPlaygroundCell *cell = (ANPlaygroundCell *)view;
    NSAssert([cell isKindOfClass:[ANPlaygroundCell class]], @"");
    return cell;
}

#pragma mark Data reloading

- (void)reloadData {
    [DejalBezelActivityView activityViewForView:self.view];
    [[ANDataManager sharedManager] playgroundListWithCompletionHandler:^(NSArray *result, NSError *error) {
        self.dataContainer = result;
        [self.tableView reloadData];
        [DejalBezelActivityView removeViewAnimated:NO];
    }];
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
