//
//  PQLoginViewController.m
//  WeeiOSClient
//
//  Created by Le Thai Phuc Quang on 5/26/15.
//  Copyright (c) 2015 QuangLTP. All rights reserved.
//

#import "PQLoginViewController.h"
#import <Parse/Parse.h>

@interface PQLoginViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *tosLabel;

@end

@implementation PQLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //[self setupTapToDismissKeyboard];
    [self setupTOSLabel];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupTapToDismissKeyboard {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)setupTOSLabel {
    NSString *text = @"By clicking Sign up, you agree with our Term of Service and Privacy Policy";
    [_tosLabel setTextColor:[UIColor colorWithRed:120.0/255.0 green:100.0/255.0 blue:15.0/255.0 alpha:1.0]];
    
    NSRange tosRange = [text rangeOfString:@"Term of Service" options:NSCaseInsensitiveSearch];
    NSRange ppRange = [text rangeOfString:@"Privacy Policy" options:NSCaseInsensitiveSearch];
    
    _tosLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    _tosLabel.delegate = self;
    
    [_tosLabel setText:text];
    
    [_tosLabel setLinkAttributes:@{(id)kCTForegroundColorAttributeName: [UIColor whiteColor]}];
    
    [_tosLabel addLinkToURL:[NSURL URLWithString:@"http://quangltp.com/wee/tos.html"] withRange:tosRange];
    [_tosLabel addLinkToURL:[NSURL URLWithString:@"http://quangltp.com/wee/pp.html"] withRange:ppRange];
    
//    
//    [_tosLabel setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:
//     ^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
//         
//         UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:11];
//         CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
//         if (font) {
//             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(font) range:tosRange];
//             [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(id)CFBridgingRelease(font) range:ppRange];
//             CFRelease(font);
//         }
//         
//         
//         
//         [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:tosRange];
//         [mutableAttributedString addAttribute:(NSString *)kCTForegroundColorAttributeName value:(id)[UIColor whiteColor].CGColor range:ppRange];
//     
//         return mutableAttributedString;
//     }];
}

- (BOOL)checkEmail:(NSString *)email {
    NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    return [emailTest evaluateWithObject:email];
}


- (BOOL)validateEmail {
    NSString *email = _emailTextField.text;
    if (![self checkEmail:email]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"Please enter a valid email"
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        
        [alert show];
        return NO;
    }
    return YES;
}

- (BOOL)validateFields {
    NSString *email = _emailTextField.text;
    NSString *password = _passwordTextField.text;
    if (email.length == 0 || password.length == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Oops"
                                                        message:@"Please enter into both fields"
                                                       delegate:nil
                                              cancelButtonTitle:@"Okay"
                                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)beforeStartingLongProcess {
    [_activityIndicator startAnimating];
    [_signInButton setEnabled:NO];
    [_signUpButton setEnabled:NO];
}

- (void)afterEndingLongProcess {
    [_activityIndicator stopAnimating];
    [_signUpButton setEnabled:YES];
    [_signInButton setEnabled:YES];
}

- (void)signIn {
    [self beforeStartingLongProcess];
    [PFUser logInWithUsernameInBackground:_emailTextField.text
                                 password:_passwordTextField.text
                                    block:^(PFUser *PF_NULLABLE_S user, NSError *PF_NULLABLE_S error) {
                                        [self afterEndingLongProcess];
                                        if (!error) {
                                            [self dismissViewControllerAnimated:YES completion:nil];
                                        }
                                        else {
                                            NSLog(@"%@", error);
                                        }
                                    }];
}

- (IBAction)signInButton_TUI:(id)sender {
    
    if ([self validateEmail] && [self validateFields]) {
        [self signIn];
    }
    
}

- (IBAction)signUpButton_TUI:(id)sender {
    if ([self validateEmail] && [self validateFields]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"One more step"
                                                        message:@"Please enter your password again to confirm"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Okay", nil];
        [alert setAlertViewStyle:UIAlertViewStyleSecureTextInput];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        PFUser *user = [PFUser user];
        user.username = _emailTextField.text;
        user.password = _passwordTextField.text;
        //check password match
        [self beforeStartingLongProcess];
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *PF_NULLABLE_S error) {
            [self afterEndingLongProcess];
            if (succeeded) {
                [self signIn];
            }
            else {
                NSLog(@"%@", error);
            }
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

#pragma mark - AttributedString delegates
- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
    NSLog(@"%@", url);
}

- (void)attributedLabel:(TTTAttributedLabel *)label didLongPressLinkWithURL:(NSURL *)url atPoint:(CGPoint)point {
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

@end
