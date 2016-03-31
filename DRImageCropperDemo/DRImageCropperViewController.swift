//
//  DRImageCropperViewController.swift
//  LoveTrail
//
//  Created by Xiaoqiang Zhang on 16/3/16.
//  Copyright © 2016年 Xiaoqiang Zhang. All rights reserved.
//

import UIKit

let SCALE_FRAME_Y    = 100.0
let BOUNDCE_DURATION = 0.3

@objc protocol DRImageCropperDelegate : NSObjectProtocol {
  func imageCropper(cropperViewController:DRImageCropperViewController, didFinished editImg:UIImage)
  
  func imageCropperDidCancel(cropperViewController:DRImageCropperViewController)
}

class DRImageCropperViewController: UIViewController {

  var originalImage:UIImage?
  var editedImage:UIImage?
  
  var showImgView:UIImageView?
  var overlayView:UIView?
  var ratioView:UIView?
  
  var oldFrame:CGRect?
  var largeFrame:CGRect?
  var limitRatio:CGFloat?
  
  var latestFrame:CGRect?
  var cropFrame:CGRect?
  
  var tag:NSInteger?
  
  var delegate:DRImageCropperDelegate?
  
  deinit {
    self.originalImage = nil
    self.showImgView   = nil
    self.editedImage   = nil
    self.overlayView   = nil
    self.ratioView     = nil
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  convenience init(originalImage:UIImage, cropFrame:CGRect, limitScaleRatio:CGFloat) {
    self.init(nibName: nil, bundle: nil)
    
    self.cropFrame = cropFrame
    self.limitRatio  = limitScaleRatio
    self.originalImage = self.fixOrientation(originalImage)
  }
  
  override func viewDidLoad() {
      super.viewDidLoad()
    self.initView()
    self.initControlBtn()
  }

  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  override func shouldAutorotate() -> Bool {
    return false
  }
  
//  override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
//    return UIInterfaceOrientation.Unknown
//  }
//  
//  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//    return UIInterfaceOrientationMask.All
//  }
  
  // initView
  func initView() {
    self.view.backgroundColor = UIColor.blackColor()
    
    self.showImgView = UIImageView(frame: CGRectMake(0, 0, 320, 480))
    self.showImgView?.multipleTouchEnabled   = true
    self.showImgView?.userInteractionEnabled = true
    self.showImgView?.image                  = self.originalImage
    self.showImgView?.userInteractionEnabled = true
    self.showImgView?.multipleTouchEnabled   = true
    
    // scale to fit the screen
    let oriWidth = self.cropFrame!.size.width
    let oriHeight = (self.originalImage?.size.height)! * (oriWidth / (self.originalImage?.size.width)!)
    let oriX = (self.cropFrame?.origin.x)! + ((self.cropFrame?.size.width)! - oriWidth) / 2
    let oriY = (self.cropFrame?.origin.y)! + ((self.cropFrame?.size.height)! - oriHeight) / 2
    
    self.oldFrame = CGRectMake(oriX, oriY, oriWidth, oriHeight)
    self.latestFrame = self.oldFrame
    self.showImgView?.frame = self.oldFrame!
    
    self.largeFrame = CGRectMake(0, 0, self.limitRatio! * self.oldFrame!.size.width, self.limitRatio! * self.oldFrame!.size.height)
    
    self.addGestureRecognizers()
    self.view.addSubview(self.showImgView!)
    
    self.overlayView = UIView(frame: self.view.bounds)
    self.overlayView?.alpha = 0.5
    self.overlayView?.backgroundColor = UIColor.blackColor()
    self.overlayView?.userInteractionEnabled = false
    self.overlayView?.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
    
    self.view.addSubview(self.overlayView!)
    
    self.ratioView = UIView(frame: self.cropFrame!)
    self.ratioView?.layer.borderColor = UIColor.yellowColor().CGColor
    self.ratioView?.layer.borderWidth = 1.0
    self.ratioView?.autoresizingMask = UIViewAutoresizing.None
    self.view.addSubview(self.ratioView!)
    
    self.overlayClipping()
  }
  
  func initControlBtn() {
    let cancelBtn = UIButton(frame: CGRectMake(0, self.view.frame.size.height - 50.0, 100, 50))
    cancelBtn.backgroundColor = UIColor.blackColor()
    cancelBtn.titleLabel?.textColor = UIColor.whiteColor()
    cancelBtn.setTitle("Cancel", forState: UIControlState.Normal)
    cancelBtn.titleLabel?.font = UIFont.systemFontOfSize(18.0)
    cancelBtn.titleLabel?.textAlignment = NSTextAlignment.Center
    cancelBtn.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
    cancelBtn.titleLabel?.numberOfLines = 0
    cancelBtn.titleEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
    cancelBtn.addTarget(self, action: "cancel:", forControlEvents: UIControlEvents.TouchUpInside)
    self.view.addSubview(cancelBtn)
    
    let confirmBtn:UIButton = UIButton(frame: CGRectMake(self.view.frame.size.width - 100.0, self.view.frame.size.height - 50.0, 100, 50))
    confirmBtn.backgroundColor = UIColor.blackColor()
    confirmBtn.titleLabel?.textColor = UIColor.whiteColor()
    confirmBtn.setTitle("OK", forState: UIControlState.Normal)
    confirmBtn.titleLabel?.font = UIFont.systemFontOfSize(18.0)
    confirmBtn.titleLabel?.textAlignment = NSTextAlignment.Center
    confirmBtn.titleLabel?.lineBreakMode = NSLineBreakMode.ByWordWrapping
    confirmBtn.titleLabel?.numberOfLines = 0
    confirmBtn.titleEdgeInsets = UIEdgeInsetsMake(5.0, 5.0, 5.0, 5.0)
    confirmBtn.addTarget(self, action: "confirm:", forControlEvents: UIControlEvents.TouchUpInside)
    self.view.addSubview(confirmBtn)
  }
  
  // private func
  
  func cancel(sender:AnyObject) {
    if self.delegate != nil {
      if self.delegate!.respondsToSelector("imageCropperDidCancel:") {
        self.delegate!.imageCropperDidCancel(self)
      }
    }
  }
  
  func confirm(sender:AnyObject) {
    if self.delegate != nil {
      if self.delegate!.respondsToSelector("imageCropper:didFinished:") {
//        self.delegate!.imageCropper(self, didFinished: self.getSubImage())
        self.delegate!.imageCropper(self, didFinished: self.getSubImage())
      }
    }
  }
  
  func overlayClipping() {
    let maskLayer = CAShapeLayer()
    let path = CGPathCreateMutable()
    
    // Left side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0, self.ratioView!.frame.origin.x, self.overlayView!.frame.size.height))
    
    // Right side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(
      self.ratioView!.frame.origin.x + self.ratioView!.frame.size.width, 0, self.overlayView!.frame.size.width - self.ratioView!.frame.origin.x - self.ratioView!.frame.size.width, self.overlayView!.frame.size.height))
    
    // Top side of the ratio view
    CGPathAddRect(path, nil, CGRectMake(0, 0, self.overlayView!.frame.size.width, self.ratioView!.frame.origin.y))
    
    // Bottom side of the ratio view
    CGPathAddRect(path, nil,  CGRectMake(0, self.ratioView!.frame.origin.y + self.ratioView!.frame.size.height, self.overlayView!.frame.size.width, self.overlayView!.frame.size.height - self.ratioView!.frame.origin.y + self.ratioView!.frame.size.height))
    
    maskLayer.path = path
    self.overlayView?.layer.mask = maskLayer
    CGPathCloseSubpath(path)
  }
  
  // register all gestures
  func addGestureRecognizers() {
    // pinch
    let pinchGestureRecognizer:UIPinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "pinchView:")
    self.view.addGestureRecognizer(pinchGestureRecognizer)
    
    // pan
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "panView:")
    self.view.addGestureRecognizer(panGestureRecognizer)
  }
  
  // pinch gesture handler
  func pinchView(pinchGestureRecognizer:UIPinchGestureRecognizer) {
    let view = self.showImgView!
    if pinchGestureRecognizer.state == UIGestureRecognizerState.Began || pinchGestureRecognizer.state == UIGestureRecognizerState.Changed {
      view.transform = CGAffineTransformScale(view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale)
      pinchGestureRecognizer.scale = 1
    }
    else if pinchGestureRecognizer.state == UIGestureRecognizerState.Ended {
      var newFrame = self.showImgView!.frame
      newFrame = self.handleScaleOverflow(newFrame)
      newFrame = self.handleBorderOverflow(newFrame)
      
      UIView.animateWithDuration(BOUNDCE_DURATION, animations: { () -> Void in
        self.showImgView!.frame = newFrame
        self.latestFrame = newFrame
      })
    }
  }
  
  //pan gesture handler
  func panView(panGestureRecognizer:UIPanGestureRecognizer) {
    let view = self.showImgView!
    if panGestureRecognizer.state == UIGestureRecognizerState.Began || panGestureRecognizer.state == UIGestureRecognizerState.Changed {
      let absCenterX = self.cropFrame!.origin.x + self.cropFrame!.size.width / 2
      let absCenterY = self.cropFrame!.origin.y + self.cropFrame!.size.height / 2
      let scaleRatio = self.showImgView!.frame.size.width / self.cropFrame!.size.width
      let acceleratorX = 1 - abs(absCenterX - view.center.x) / (scaleRatio * absCenterX)
      let acceleratorY = 1 - abs(absCenterY - view.center.y) / (scaleRatio * absCenterY)
      let translation = panGestureRecognizer.translationInView(view.superview)
      view.center = CGPointMake(view.center.x + translation.x * acceleratorX, view.center.y + translation.y * acceleratorY)
      panGestureRecognizer.setTranslation(CGPoint.zero, inView: view.superview)
    }
    else if panGestureRecognizer.state == UIGestureRecognizerState.Ended {
      var newFrame = self.showImgView!.frame
      newFrame = self.handleBorderOverflow(newFrame)
      UIView.animateWithDuration(BOUNDCE_DURATION, animations: { () -> Void in
        self.showImgView!.frame = newFrame
        self.latestFrame = newFrame
      })
    }
  }
  
  func handleScaleOverflow(var newFrame:CGRect) -> CGRect {
    let oriCenter = CGPointMake(newFrame.origin.x + newFrame.size.width / 2, newFrame.origin.y + newFrame.size
    .height / 2)
    if newFrame.size.width < self.oldFrame!.size.width {
      newFrame = self.oldFrame!
    }
    if newFrame.size.width > self.largeFrame!.size.width {
      newFrame = self.largeFrame!
    }
    newFrame.origin.x = oriCenter.x - newFrame.size.width / 2
    newFrame.origin.y = oriCenter.y - newFrame.size.height / 2
    return newFrame
  }
  
  func handleBorderOverflow(var newFrame:CGRect) -> CGRect {
    if newFrame.origin.x > self.cropFrame!.origin.x {
      newFrame.origin.x = self.cropFrame!.origin.x
    }
    if CGRectGetMaxX(newFrame) < self.cropFrame!.size.width {
      newFrame.origin.x = self.cropFrame!.size.width - newFrame.size.width
    }
    
    if newFrame.origin.y > self.cropFrame!.origin.y {
      newFrame.origin.y = self.cropFrame!.origin.y
    }
    if CGRectGetMaxY(newFrame) < self.cropFrame!.origin.y + self.cropFrame!.size.height {
      newFrame.origin.y = self.cropFrame!.origin.y + self.cropFrame!.size.height - newFrame.size.height
    }
    
    if self.showImgView!.frame.size.width > self.showImgView!.frame.size.height && newFrame.size.height <= self.cropFrame!.size.height {
      newFrame.origin.y = self.cropFrame!.origin.y + (self.cropFrame!.size.height - newFrame.size.height) / 2
    }
    return newFrame
  }
  
  func getSubImage() -> UIImage {
    let squareFrame = self.cropFrame!
    let scaleRatio = self.latestFrame!.size.width / self.originalImage!.size.width
    var x = (squareFrame.origin.x - self.latestFrame!.origin.x) / scaleRatio
    var y = (squareFrame.origin.y - self.latestFrame!.origin.y) / scaleRatio
    var w = squareFrame.size.width / scaleRatio
    var h = squareFrame.size.height / scaleRatio
    if self.latestFrame!.size.width < self.cropFrame!.size.width {
      let newW = self.originalImage!.size.width
      let newH = newW * (self.cropFrame!.size.height / self.cropFrame!.size.width)
      x = 0;
      y = y + (h - newH) / 2
      w = newH
      h = newH
    }
    if self.latestFrame!.size.height < self.cropFrame!.size.height {
      let newH = self.originalImage!.size.height
      let newW = newH * (self.cropFrame!.size.width / self.cropFrame!.size.height)
      x = x + (w - newW) / 2
      y = 0
      w = newH
      h = newH
    }
    
    let myImageRect = CGRectMake(x, y, w, h)
    let imageRef = self.originalImage!.CGImage
    let subImageRef = CGImageCreateWithImageInRect(imageRef, myImageRect)
    let size:CGSize = CGSizeMake(myImageRect.size.width, myImageRect.size.height)
    UIGraphicsBeginImageContext(size)
    let context:CGContextRef = UIGraphicsGetCurrentContext()!
    CGContextDrawImage(context, myImageRect, subImageRef)
    let smallImage = UIImage(CGImage: subImageRef!)
    UIGraphicsEndImageContext()
    return smallImage
  }
  
  // orientation
  func fixOrientation(srcImg:UIImage) -> UIImage {
    if srcImg.imageOrientation == UIImageOrientation.Up {
      return srcImg
    }
    var transform = CGAffineTransformIdentity
    switch srcImg.imageOrientation {
    case UIImageOrientation.Down, UIImageOrientation.DownMirrored:
      transform = CGAffineTransformTranslate(transform, srcImg.size.width, srcImg.size.height)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
    case UIImageOrientation.Left, UIImageOrientation.LeftMirrored:
      transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0)
      transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
    case UIImageOrientation.Right, UIImageOrientation.RightMirrored:
      transform = CGAffineTransformTranslate(transform, 0, srcImg.size.height)
      transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
    case UIImageOrientation.Up, UIImageOrientation.UpMirrored: break
    }
    switch srcImg.imageOrientation {
    case UIImageOrientation.UpMirrored, UIImageOrientation.DownMirrored:
      transform = CGAffineTransformTranslate(transform, srcImg.size.width, 0)
      transform = CGAffineTransformScale(transform, -1, 1)
    case UIImageOrientation.LeftMirrored, UIImageOrientation.RightMirrored:
      transform = CGAffineTransformTranslate(transform, srcImg.size.height, 0)
      transform = CGAffineTransformScale(transform, -1, 1)
    case UIImageOrientation.Up, UIImageOrientation.Down, UIImageOrientation.Left, UIImageOrientation.Right:break
    }
    
    // 上下文
    let ctx:CGContextRef = CGBitmapContextCreate(nil, Int(srcImg.size.width), Int(srcImg.size.height), CGImageGetBitsPerComponent(srcImg.CGImage), 0, CGImageGetColorSpace(srcImg.CGImage), CGImageGetBitmapInfo(srcImg.CGImage).rawValue)!
    
    CGContextConcatCTM(ctx, transform)
    switch srcImg.imageOrientation {
    case UIImageOrientation.Left, UIImageOrientation.LeftMirrored, UIImageOrientation.Right, UIImageOrientation.RightMirrored:
      CGContextDrawImage(ctx, CGRectMake(0, 0, srcImg.size.height, srcImg.size.width), srcImg.CGImage)
    default:
      CGContextDrawImage(ctx, CGRectMake(0, 0, srcImg.size.width, srcImg.size.height), srcImg.CGImage)
    }
    
    let cgImg:CGImageRef = CGBitmapContextCreateImage(ctx)!
    let img:UIImage = UIImage(CGImage: cgImg)
    
    CGContextClosePath(ctx)
    return img
  }
  
}
