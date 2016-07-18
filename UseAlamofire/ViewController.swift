//
//  ViewController.swift
//  UseAlamofire
//
//  Created by 刘浩浩 on 16/7/15.
//  Copyright © 2016年 CodingFire. All rights reserved.
//

import UIKit
import Alamofire.Swift
class ViewController: UIViewController , UIImagePickerControllerDelegate,
UINavigationControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        self.loadData()
    }
    
    func loadData() {
        Alamofire.request(.GET, "https://api.108tian.com/mobile/v3/SceneDetail?id=528b91c9baf6773975578c5c", parameters: nil).responseJSON() { response in
           
            if let dic = response.result.value {
                print("dic: \(dic)")
            }
            else
            {
                print("dic: \(response)")
            }
        }
        
        
        
        var headers:Dictionary = [String:String]()
        headers["Content-Type"] = "application/json"
        headers["Set-Cookie"] = "xxxxxxxxxxxxxxxxx"
        
        
        var dic = [String:AnyObject]()
        dic["id"] = "CodingFire"
        dic["passWord"] = "1234567890"
        
        
        Alamofire.request(.POST, "https://api.108tian.com/mobile/v3/SceneDetail?id=", parameters:dic , encoding: ParameterEncoding.JSON, headers: headers).responseJSON{ (response)  in
            
            


            if let dic = response.result.value {
                print("dic: \(dic)")
            }
            else
            {
                print("dic: \(response)")
            }
        }
        
        

        
        
        Alamofire.upload(.POST, "https://api.108tian.", multipartFormData: { multipartFormData in
            let data = NSData()
            let data1 = NSData()
            multipartFormData.appendBodyPart(data: data, name: "image")
            multipartFormData.appendBodyPart(data: data1, name: "image1")
            }, encodingCompletion: { response in
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
    //点击屏幕触发方法
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        let actionSheet = UIAlertController(title: "上传头像", message: nil, preferredStyle: .ActionSheet)
        let cancelBtn = UIAlertAction(title: "取消", style: .Cancel, handler: nil)

        
        let takePhotos = UIAlertAction(title: "拍照", style: .Destructive, handler: {
            (action: UIAlertAction) -> Void in

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
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
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
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

