//
//  ViewController.m
//  DRImageCropperDemo
//
//  Created by Xiaoqiang Zhang on 16/3/31.
//  Copyright © 2016年 Xiaoqiang Zhang. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

#import "DRImageCropperDemo-swift.h"
#define ORIGINAL_MAX_WIDTH 640.0f

@interface ViewController ()<DRImageCropperDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) UIImageView       *imageView;
@property (nonatomic, strong) UIImage           *image;
@property (nonatomic, strong) UIAlertController *alertVC;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view, typically from a nib.
  [self initSubViews];
}

- (void)viewDidAppear:(BOOL)animated {
  if (_image) {
    _imageView.image = _image;
  }
}

#pragma mark -
#pragma mark 初始
- (void)initSubViews {
  _imageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 100)/2.0, (self.view.frame.size.height - 100)/2.0, 100, 100)];
  _imageView.layer.cornerRadius = 50;
  _imageView.layer.masksToBounds = YES;
  _imageView.backgroundColor = [UIColor redColor];
  _imageView.userInteractionEnabled = YES;
  [self.view addSubview:_imageView];
  
  UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction)];
  [_imageView addGestureRecognizer:tap];
}

#pragma mark -
#pragma mark 手势响应
- (void)tapAction {
  _alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  
  UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if ([self isCameraAvailable] && [self doesCameraSupportTakingPhotos]) {
      UIImagePickerController *controller = [[UIImagePickerController alloc] init];
      controller.sourceType = UIImagePickerControllerSourceTypeCamera;
      if ([self isFrontCameraAvailable]) {
        controller.cameraDevice = UIImagePickerControllerCameraDeviceFront;
      }
      NSMutableArray *mediaTypes = [[NSMutableArray alloc] init];
      [mediaTypes addObject:(__bridge NSString *)kUTTypeImage];
      controller.mediaTypes = mediaTypes;
      controller.delegate = self;
      [self presentViewController:controller
                         animated:YES
                       completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                       }];
    }
  }];
  
  UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"从相册选择" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    if ([self isPhotoLibraryAvailable]) {
      UIImagePickerController *controller = [[UIImagePickerController alloc] init];
      controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
      controller.delegate = self;
      controller.allowsEditing = NO;
      [self presentViewController:controller
                         animated:YES
                       completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                       }];
    }
  }];
  
  UIAlertAction *action3 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    
  }];
  [_alertVC addAction:action1];
  [_alertVC addAction:action2];
  [_alertVC addAction:action3];
  //  }
  
  [self presentViewController:_alertVC animated:YES completion:^{
    
  }];

}

#pragma mark -
#pragma mark UIImagePicker delegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
  [picker dismissViewControllerAnimated:YES completion:^{
    UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    portraitImg = [self imageByScalingToMaxSize:portraitImg];
    
    DRImageCropperViewController *imgCropperVC = [[DRImageCropperViewController alloc] initWithOriginalImage:portraitImg cropFrame:CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width) limitScaleRatio:3.0];
    imgCropperVC.delegate = self;
    [self presentViewController:imgCropperVC animated:YES completion:^{
      
    }];
  }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  
}

#pragma mark -
#pragma mark DRImageCropper delegate
- (void)imageCropper:(DRImageCropperViewController *)cropperViewController didFinished:(UIImage *)didFinished {
  _image = didFinished;
  [cropperViewController dismissViewControllerAnimated:YES completion:^{
    
  }];
}

- (void)imageCropperDidCancel:(DRImageCropperViewController *)cropperViewController {
  [cropperViewController dismissViewControllerAnimated:YES completion:^{
    
  }];
}


#pragma mark image scale utility
- (UIImage *)imageByScalingToMaxSize:(UIImage *)sourceImage {
  if (sourceImage.size.width < ORIGINAL_MAX_WIDTH) return sourceImage;
  CGFloat btWidth = 0.0f;
  CGFloat btHeight = 0.0f;
  if (sourceImage.size.width > sourceImage.size.height) {
    btHeight = ORIGINAL_MAX_WIDTH;
    btWidth = sourceImage.size.width * (ORIGINAL_MAX_WIDTH / sourceImage.size.height);
  } else {
    btWidth = ORIGINAL_MAX_WIDTH;
    btHeight = sourceImage.size.height * (ORIGINAL_MAX_WIDTH / sourceImage.size.width);
  }
  CGSize targetSize = CGSizeMake(btWidth, btHeight);
  return [self imageByScalingAndCroppingForSourceImage:sourceImage targetSize:targetSize];
}

- (UIImage *)imageByScalingAndCroppingForSourceImage:(UIImage *)sourceImage targetSize:(CGSize)targetSize {
  UIImage *newImage = nil;
  CGSize imageSize = sourceImage.size;
  CGFloat width = imageSize.width;
  CGFloat height = imageSize.height;
  CGFloat targetWidth = targetSize.width;
  CGFloat targetHeight = targetSize.height;
  CGFloat scaleFactor = 0.0;
  CGFloat scaledWidth = targetWidth;
  CGFloat scaledHeight = targetHeight;
  CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
  if (CGSizeEqualToSize(imageSize, targetSize) == NO)
  {
    CGFloat widthFactor = targetWidth / width;
    CGFloat heightFactor = targetHeight / height;
    
    if (widthFactor > heightFactor)
      scaleFactor = widthFactor; // scale to fit height
    else
      scaleFactor = heightFactor; // scale to fit width
    scaledWidth  = width * scaleFactor;
    scaledHeight = height * scaleFactor;
    
    // center the image
    if (widthFactor > heightFactor)
    {
      thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
    }
    else
      if (widthFactor < heightFactor)
      {
        thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
      }
  }
  UIGraphicsBeginImageContext(targetSize); // this will crop
  CGRect thumbnailRect = CGRectZero;
  thumbnailRect.origin = thumbnailPoint;
  thumbnailRect.size.width  = scaledWidth;
  thumbnailRect.size.height = scaledHeight;
  
  [sourceImage drawInRect:thumbnailRect];
  
  newImage = UIGraphicsGetImageFromCurrentImageContext();
  if(newImage == nil) NSLog(@"could not scale image");
  
  //pop the context to get back to the default
  UIGraphicsEndImageContext();
  return newImage;
}


#pragma mark -
#pragma mark private
- (BOOL) isPhotoLibraryAvailable{
  return [UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypePhotoLibrary];
}

- (BOOL) isCameraAvailable{
  return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) isFrontCameraAvailable {
  return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL) doesCameraSupportTakingPhotos {
  return [self cameraSupportsMedia:(__bridge NSString *)kUTTypeImage sourceType:UIImagePickerControllerSourceTypeCamera];
}

- (BOOL) cameraSupportsMedia:(NSString *)paramMediaType sourceType:(UIImagePickerControllerSourceType)paramSourceType{
  __block BOOL result = NO;
  if ([paramMediaType length] == 0) {
    return NO;
  }
  NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:paramSourceType];
  [availableMediaTypes enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
    NSString *mediaType = (NSString *)obj;
    if ([mediaType isEqualToString:paramMediaType]){
      result = YES;
      *stop= YES;
    }
  }];
  return result;
}

@end
