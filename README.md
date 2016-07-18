# Swift_upload_headerImage
Swift上传头像，拍照上传

博客地址：http://blog.csdn.net/CodingFire/article/details/51943286

图片效果如下：

![image](https://github.com/codeliu6572/Swift_upload_headerImage/blob/master/UseAlamofire/1.gif)

这里来介绍如何用Alamofire以表单形式来上传头像。

前面写过一篇Object－C的上传头像，这里代码是一样的，只是语言不一样，想看的请点击这里：http://blog.csdn.net/codingfire/article/details/51781194 

1.可拍照，可选择相册中图片：

AlertController前面单独说过，我们不陌生，需要看的就是UIImagePickerController了.

        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
                let actionSheet = UIAlertController(title: "上传头像", message: nil, preferredStyle: .ActionSheet)
                let cancelBtn = UIAlertAction(title: "取消", style: .Cancel, handler: nil)
        
        
                let takePhotos = UIAlertAction(title: "拍照", style: .Destructive, handler: {
                    (action: UIAlertAction) -> Void in
        //判断是否能进行拍照，可以的话打开相机
                    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
                        let picker = UIImagePickerController()
                        picker.sourceType = .Camera
                        picker.delegate = self
                        picker.allowsEditing = true
                        self.presentViewController(picker, animated: true, completion: nil)
        
                    }
                    else
                    {
                        print("模拟其中无法打开照相机,请在真机中使用");
                    }
        
                })
                let selectPhotos = UIAlertAction(title: "相册选取", style: .Default, handler: {
                    (action:UIAlertAction)
                    -> Void in
                    //调用相册功能，打开相册
                    let picker = UIImagePickerController()
                    picker.sourceType = .PhotoLibrary
                    picker.delegate = self
                    picker.allowsEditing = true
                    self.presentViewController(picker, animated: true, completion: nil)
        
                })
                actionSheet.addAction(cancelBtn)
                actionSheet.addAction(takePhotos)
                actionSheet.addAction(selectPhotos)
                self.presentViewController(actionSheet, animated: true, completion: nil)
        
        
            }
            
2.选择一张照片后进入代理方法

          func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
          相册中还可能是视频，所以这里需要判断选择的是不是图片
                  let type: String = (info[UIImagePickerControllerMediaType] as! String)
          
                  //当选择的类型是图片
                  if type == "public.image"
                  {
          
                      //修正图片的位置
                      let image = self.fixOrientation((info[UIImagePickerControllerOriginalImage] as! UIImage))
                      //先把图片转成NSData
                      let data = UIImageJPEGRepresentation(image, 0.5)
          
          
                      //图片保存的路径
                      //这里将图片放在沙盒的documents文件夹中
                      let DocumentsPath:String = NSHomeDirectory().stringByAppendingString("Documents")
          
                      //文件管理器
                      let fileManager = NSFileManager.defaultManager()
          
                      //把刚刚图片转换的data对象拷贝至沙盒中 并保存为image.png
                      try! fileManager.createDirectoryAtPath(DocumentsPath, withIntermediateDirectories: true, attributes: nil)
                      fileManager.createFileAtPath(DocumentsPath + "/image.png", contents: data, attributes: nil)
          
                      //得到选择后沙盒中图片的完整路径
                      let filePath = DocumentsPath + "/image.png"
                      //利用Alamofire的表单提交来上传图片
                      Alamofire.upload(.POST, "http://192.168.3.16:9060/client/updateHeadUrl", multipartFormData: { multipartFormData in
          
                          multipartFormData.appendBodyPart(data: data!, name: "image")
                          }, encodingCompletion: { response in
                              picker.dismissViewControllerAnimated(true, completion: nil)
                              switch response {
                              case .Success(let upload, _, _):
                                  upload.responseJSON(completionHandler: { (response) in
                                      print(response)
                                  })
                              case .Failure(let encodingError):
                                  print(encodingError)
                              }
          
                      })
          
          
                  }
              }

3.你会发现有时候上传的图片是旋转了90度的，下面来修正照片位置：

            func fixOrientation(aImage: UIImage) -> UIImage {
                    // No-op if the orientation is already correct
                    if aImage.imageOrientation == .Up {
                        return aImage
                    }
                    // We need to calculate the proper transformation to make the image upright.
                    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
                    var transform: CGAffineTransform = CGAffineTransformIdentity
                    switch aImage.imageOrientation {
                    case .Down, .DownMirrored:
                        transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height)
                        transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
                    case .Left, .LeftMirrored:
                        transform = CGAffineTransformTranslate(transform, aImage.size.width, 0)
                        transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
                    case .Right, .RightMirrored:
                        transform = CGAffineTransformTranslate(transform, 0, aImage.size.height)
                        transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
                    default:
                        break
                    }
            
                    switch aImage.imageOrientation {
                    case .UpMirrored, .DownMirrored:
                        transform = CGAffineTransformTranslate(transform, aImage.size.width, 0)
                        transform = CGAffineTransformScale(transform, -1, 1)
                    case .LeftMirrored, .RightMirrored:
                        transform = CGAffineTransformTranslate(transform, aImage.size.height, 0)
                        transform = CGAffineTransformScale(transform, -1, 1)
                    default:
                        break
                    }
            
                    // Now we draw the underlying CGImage into a new context, applying the transform
                    // calculated above.
            
            
                    //这里需要注意下CGImageGetBitmapInfo，它的类型是Int32的，CGImageGetBitmapInfo(aImage.CGImage).rawValue，这样写才不会报错
                    let ctx: CGContextRef = CGBitmapContextCreate(nil, Int(aImage.size.width), Int(aImage.size.height), CGImageGetBitsPerComponent(aImage.CGImage), 0, CGImageGetColorSpace(aImage.CGImage), CGImageGetBitmapInfo(aImage.CGImage).rawValue)!
                    CGContextConcatCTM(ctx, transform)
                    switch aImage.imageOrientation {
                    case .Left, .LeftMirrored, .Right, .RightMirrored:
                        // Grr...
                        CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.height, aImage.size.width), aImage.CGImage)
                    default:
                        CGContextDrawImage(ctx, CGRectMake(0, 0, aImage.size.width, aImage.size.height), aImage.CGImage)
                    }
            
                    // And now we just create a new UIImage from the drawing context
                    let cgimg: CGImageRef = CGBitmapContextCreateImage(ctx)!
                    let img: UIImage = UIImage(CGImage: cgimg)
                    return img
                }
