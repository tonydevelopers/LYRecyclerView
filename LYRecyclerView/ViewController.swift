//
//  ViewController.swift
//  LYRecyclerView
//
//  Created by joinhov on 2016/11/25.
//  Copyright © 2016年 tony. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var recyclerView: LYRecyclerView!
    var data: [DataItem] = [DataItem]()
    
    var placeholderImage = UIImage(named: "img_ad")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recyclerView = LYRecyclerView(frame: CGRect(x: 0, y: 80, width: self.view.bounds.width, height: self.view.bounds.height / 4))

        recyclerView.delegate = self
        recyclerView.timeInterval = DispatchTimeInterval.seconds(5)
        recyclerView.placeholderImage = placeholderImage
        self.view.addSubview(recyclerView)
        
        self.view.backgroundColor = UIColor.blue
        
        self.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setup() {
        
        for i in 0...4 {
            
            var url = ""
            var contentUrl = ""
            switch i {
            case 0:
                url = "http://desk.fd.zol-img.com.cn/t_s1280x1024c5/g5/M00/06/0F/ChMkJ1eB42-IXICZAC-b2z1kN5IAATZEAGIpKQAL5vz687.jpg"
                contentUrl = "http://www.baidu.com"
                break
            case 1:
                url = "http://desk.fd.zol-img.com.cn/t_s1280x1024c5/g5/M00/0F/0A/ChMkJ1eZ8OOITLc2AAQWEZjZFAgAAT71gKtNRQABBYp187.jpg"
                contentUrl = "http://www.qq.com"
                break
            case 2:
                url = "http://desk.fd.zol-img.com.cn/t_s1280x1024c5/g5/M00/06/0F/ChMkJleB422IXV93ACmx9ykNKG8AATZEAFaBoMAKbIP392.jpg"
                contentUrl = "http://www.taobao.com"
                break
            case 3:
                url = "http://desk.fd.zol-img.com.cn/t_s1280x1024c5/g5/M00/00/04/ChMkJ1ebRfuIfC-3AAQNjkmPpFYAAT-PwLA1wYABA2m812.jpg"
                contentUrl = "http://www.jd.com"
                break
            case 4:
                url = "http://desk.fd.zol-img.com.cn/t_s1280x1024c5/g5/M00/0F/01/ChMkJleYmTCID1AzAAau5xfqy0UAAT5igN01VIABq7_951.jpg"
                contentUrl = "http://www.tmall.com"
                break
            default:
                break
            }
            
            let item = DataItem(title: "测试图片: \(i) ", imageUrl: url, contentUrl: contentUrl)
            
            data.append(item)
        }
        
        recyclerView.data = data
    }

}

extension ViewController: LYRecyclerViewDelegate {
    
    func recyclerViewDidDisplay(_ recyclerView: LYRecyclerView, imageView: UIImageView, title: String, imageUrl: String, contentUrl: String) {

        
        imageView.kf.setImage(with: URL(string: imageUrl), placeholder: placeholderImage, options: nil, progressBlock: nil, completionHandler: nil)
        
    }
    
    func recyclerViewDidSelected(_ recyclerView: LYRecyclerView, indexPath: IndexPath, title: String, imageUrl: String, contentUrl: String){
        
        let url = URL(string: contentUrl)!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}

