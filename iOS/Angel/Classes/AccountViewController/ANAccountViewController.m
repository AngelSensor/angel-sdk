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


#import "ANAccountViewController.h"
#import "DejalActivityView.h"
#import "ANRootNavigationController.h"
#import "TPKeyboardAvoidingTableView.h"
#import "ANTitleValueCell.h"
#import "ANAccountDateCell.h"
#import "ANAccountWristbandCell.h"
#import "ANAccount.h"
#import "ANPeripheral.h"

typedef enum {
    TableViewUserRowName,
    TableViewUserRowBirthday,
    TableViewUserRowGender,
    TableViewUserRowHeight,
    TableViewUserRowWeight,
    TableViewUserRowEmail,
    tableViewUserRowCount
} TableViewUserRow;

typedef enum {
    TableViewSectionUser,
    TableViewSectionWristband,
    tableViewSectionCount
} TableViewSection;

typedef enum {
    AlertViewTagNone,
    AlertViewTagForget
} AlertViewTag;

@interface ANAccountViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *photoButton;

@property (nonatomic, weak) IBOutlet TPKeyboardAvoidingTableView *tableView;

@property (nonatomic, strong) NSArray *braceletsContainer;

@property (nonatomic, strong) NSIndexPath *selectedDateIndexPath;
@property (nonatomic, strong) NSIndexPath *selectedForgetIndexPath;

@end

@implementation ANAccountViewController

#pragma mark Initialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

#pragma mark Interface Actions

- (IBAction)photoButtonPressed:(UIButton *)sender {
    UIActionSheet *selectSource = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select Source", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Camera", nil), NSLocalizedString(@"Gallery", nil), nil];
    [selectSource showInView:self.view];
}

#pragma mark Birthdate Picker handling

- (IBAction)dateValueChanged:(UIDatePicker *)sender {
    if (self.selectedDateIndexPath) {
        
        ANAccount *account = [ANAccount currentAccount];
        account.accountBirthdate = sender.date;
        
        [account save];
        
        [self.tableView reloadRowsAtIndexPaths:@[self.selectedDateIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView reloadData];
    }
}

#pragma mark Forget Bracelet handling

- (IBAction)forgetDeviceButtonPressed:(UIButton *)sender {
    self.selectedForgetIndexPath = [self.tableView indexPathForCell:[self cellFromButton:sender]];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to forget this device?", nil) delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [alert setTag:AlertViewTagForget];
    [alert show];
}

- (void)forgetSelectedWristband {
    self.selectedForgetIndexPath = nil;
    [[ANDataManager sharedManager] forgetDevice];
    [(ANRootNavigationController *)self.navigationController moveToWelcomeScreen];
}

#pragma mark Connecting bracelets handling

- (IBAction)connectDeviceButtonPressed:(UIButton *)sender {
    
}

- (IBAction)searchBraceletsButtonPressed:(UIButton *)sender {
    [self forgetSelectedWristband];
}

#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        switch (alertView.tag) {
            case AlertViewTagForget: {
                [self forgetSelectedWristband];
            } break;
            default: {
                
            } break;
        }
    }
}

#pragma mark UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    switch (buttonIndex) {
        case 0: {
            [self choosePhotoIsFromCamera:YES];
        }
            break;
        case 1: {
            [self choosePhotoIsFromCamera:NO];
        }
            break;
    }
}

- (void)choosePhotoIsFromCamera:(BOOL)isFromCamera {
	UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
	if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) || ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && isFromCamera)) {
		[imagePicker setSourceType:(([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] && isFromCamera)?UIImagePickerControllerSourceTypeCamera:UIImagePickerControllerSourceTypePhotoLibrary)];
        [imagePicker setDelegate:self];
        imagePicker.allowsEditing = YES;
        [self presentViewController:imagePicker animated:YES completion:nil];
	}
}

#pragma mark UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *editedImage = (UIImage *) [info objectForKey:UIImagePickerControllerEditedImage];
    UIImage *originalImage = (UIImage *) [info objectForKey:UIImagePickerControllerOriginalImage];
    
    UIImage *imageToAdd;
    
    if (editedImage) {
        imageToAdd = editedImage;
    } else {
        imageToAdd = originalImage;
    }
    
    [[ANAccount currentAccount] setAccountImage:imageToAdd];
    
    [self dismissViewControllerAnimated:YES completion:^{
        [self.photoButton setBackgroundImage:imageToAdd forState:UIControlStateNormal];
    }];
}

#pragma mark Keyboard closing

- (void)closeKeyboard {
    [self.view endEditing:YES];
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    ANTitleValueCell *cell = [self cellFromTextField:textField];
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    switch (indexPath.section) {
        case TableViewSectionUser: {
            ANAccount *account = [ANAccount currentAccount];
            NSString *value = cell.valueField.text;
            switch (indexPath.row) {
                case TableViewUserRowName: {
                    account.accountName = value;
                } break;
                case TableViewUserRowEmail: {
                    account.accountEmail = value;
                } break;
            }
            [account save];
        } break;
        case TableViewSectionWristband: {
            
        } break;
    }
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark Data reloading 

- (void)reloadData {
    ANAccount *account = [ANAccount currentAccount];
    
    if (account.accountImage) {
        [self.photoButton setImage:account.accountImage forState:UIControlStateNormal];
    } else {
        [self.photoButton setImage:[UIImage imageNamed:account.accountGender == GenderMale ? @"icon_photo_male" : @"icon_photo_female"] forState:UIControlStateNormal];
    }
    
    if ([[ANDataManager sharedManager] currentWristband]) {
        self.braceletsContainer = @[[[ANDataManager sharedManager] currentWristband]];
    }
    else {
        self.braceletsContainer = nil;
    }
    [self.tableView reloadData];
}

#pragma mark UITableView dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return tableViewSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case TableViewSectionUser: {
            return tableViewUserRowCount;
        } break;
        case TableViewSectionWristband: {
            if (self.braceletsContainer.count) {
                return self.braceletsContainer.count;
            } else {
                return 1;
            }
        } break;
    }
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.selectedDateIndexPath isEqual:indexPath]) {
        return 212.0f;
    } else {
        return 50.0f;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TableViewSectionUser: {
            UITableViewCell *rowCell;
            ANAccount *account = [ANAccount currentAccount];
            switch (indexPath.row) {
                case TableViewUserRowName: {
                    ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Name", nil);
                    cell.valueField.text = account.accountName;
                    cell.valueField.userInteractionEnabled = YES;
                    rowCell = cell;
                } break;
                case TableViewUserRowBirthday: {
                    ANAccountDateCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountDateCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Birthday", nil);
                    cell.valueField.text = account.accountBirthdate ? [[[ANDataManager sharedManager] birthdayFormatter] stringFromDate:account.accountBirthdate] : @"";
                    cell.valueField.userInteractionEnabled = NO;
                    [cell.datePicker setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US"]];
                    [cell.datePicker setDate: account.accountBirthdate ? account.accountBirthdate : [NSDate date] animated:NO];
                    rowCell = cell;
                } break;
                case TableViewUserRowGender: {
                    ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Gender", nil);
                    cell.valueField.text = account.accountGender == GenderMale ? NSLocalizedString(@"Male", nil) : NSLocalizedString(@"Female", nil);
                    cell.valueField.userInteractionEnabled = NO;
                    rowCell = cell;
                } break;
                case TableViewUserRowHeight: {
                    ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Height", nil);
                    if (account.accountHeightMetrics == HeightMetricsCm) {
                        cell.valueField.text = account.accountHeight ? [NSString stringWithFormat:@"%d %@", account.accountHeight.intValue, NSLocalizedString(@"cm", nil)] : @"";
                    } else {
                        cell.valueField.text = account.accountHeight ? [NSString stringWithFormat:@"%d'%d\"", account.accountHeight.intValue / 12, account.accountHeight.intValue % 12] : @"";
                    }
                    cell.valueField.userInteractionEnabled = NO;
                    rowCell = cell;
                } break;
                case TableViewUserRowWeight: {
                    ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Weight", nil);
                    cell.valueField.text = account.accountWeight ? [NSString stringWithFormat:@"%d %@", account.accountWeight.intValue, account.accountWeightMetrics == WeightMetricsKg ? NSLocalizedString(@"kg", nil) : NSLocalizedString(@"lb", nil)] : @"";
                    cell.valueField.userInteractionEnabled = NO;
                    rowCell = cell;
                } break;
                case TableViewUserRowEmail: {
                    ANTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountCell"];
                    cell.titleLabel.text = NSLocalizedString(@"Email", nil);
                    cell.valueField.text = account.accountEmail;
                    cell.valueField.keyboardType = UIKeyboardTypeEmailAddress;
                    cell.valueField.userInteractionEnabled = YES;
                    rowCell = cell;
                } break;
            }
            return rowCell;
        } break;
        case TableViewSectionWristband: {
            if (self.braceletsContainer.count) {
                ANAccountWristbandCell *cell = [tableView dequeueReusableCellWithIdentifier:@"accountBraceletCell"];
                ANPeripheral *bracelet = [self.braceletsContainer objectAtIndex:indexPath.row];
                cell.valueField.text = bracelet.identifier;
                cell.valueField.userInteractionEnabled = NO;
                cell.wristbandImageView.image = [UIImage imageNamed:bracelet.connected ? @"icn_braclate" : @"icn_sensor"];
                return cell;
            } else {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"noBraceletsCell"];
                return cell;
            }
        } break;
    }
    return nil;
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case TableViewSectionUser: {
            switch (indexPath.row) {
                case TableViewUserRowBirthday: {
                    NSArray *reload;
                    if (self.selectedDateIndexPath) {
                        if ([self.selectedDateIndexPath isEqual:indexPath]) {
                            reload = @[self.selectedDateIndexPath];
                            self.selectedDateIndexPath = nil;
                        } else {
                            reload = @[self.selectedDateIndexPath, indexPath];
                            self.selectedDateIndexPath = indexPath;
                        }
                    } else {
                        reload = @[indexPath];
                        self.selectedDateIndexPath = indexPath;
                    }
                    [tableView reloadRowsAtIndexPaths:reload withRowAnimation:UITableViewRowAnimationAutomatic];
                } break;
                case TableViewUserRowGender: {
                    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"accountGenderViewController" animated:YES];
                } break;
                case TableViewUserRowHeight: {
                    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"accountHeightViewController" animated:YES];
                } break;
                case TableViewUserRowWeight: {
                    [(ANRootNavigationController *)self.navigationController pushViewControllerWithIdentifier:@"accountWeightViewController" animated:YES];
                } break;
            }
        } break;
        case TableViewSectionWristband: {
            
        } break;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (ANTitleValueCell *)cellFromTextField:(UITextField *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[ANTitleValueCell class]])) {
        view = view.superview;
    }
    ANTitleValueCell *cell = (ANTitleValueCell *)view;
    NSAssert([cell isKindOfClass:[ANTitleValueCell class]], @"");
    return cell;
}

- (ANAccountWristbandCell *)cellFromButton:(UIButton *)sender {
    UIView *view = sender;
    while (view && (![view isKindOfClass:[ANAccountWristbandCell class]])) {
        view = view.superview;
    }
    ANAccountWristbandCell *cell = (ANAccountWristbandCell *)view;
    NSAssert([cell isKindOfClass:[ANAccountWristbandCell class]], @"");
    return cell;
}

#pragma mark View lifeCycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard)];
    [tap setCancelsTouchesInView:NO];
    
    [self.view addGestureRecognizer:tap];
    
    self.photoButton.layer.masksToBounds = YES;
    self.photoButton.layer.cornerRadius = self.photoButton.frame.size.width / 2;
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
