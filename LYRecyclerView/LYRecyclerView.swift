//
//  LYRecyclerView.swift
//  LYRecyclerView
//
//  Created by joinhov on 2016/11/25.
//  Copyright © 2016年 tony. All rights reserved.
//

import UIKit

/** 信息流对象 */
public class DataItem {
    
    // 标题
    public var title: String!
    // 图片地址
    public var imageUrl: String!
    // 内容地址
    public var contentUrl: String!
    
    init(title: String, imageUrl: String, contentUrl: String) {
        self.title = title
        self.imageUrl = imageUrl
        self.contentUrl = contentUrl
    }
    
}

public protocol LYRecyclerViewDelegate: NSObjectProtocol {
    
    /// 外部自行处理图片的显示方式
    func recyclerViewDidDisplay(_ recyclerView: LYRecyclerView, imageView: UIImageView, title: String, imageUrl: String, contentUrl: String)
    
    /// 被点击的时候的处理
    func recyclerViewDidSelected(_ recyclerView: LYRecyclerView, indexPath: IndexPath, title: String, imageUrl: String, contentUrl: String)
    
}

/**
 * 无限循环轮播图
 */
public class LYRecyclerView: UIView {
    
    public weak var delegate: LYRecyclerViewDelegate?
    
    public var placeholderImage: UIImage?
    
    public var autoPlayEnabled: Bool = true
    
    fileprivate let cellIdentifier = "LYRecyclerViewCell"

    public var data: [DataItem]? {
        didSet {
            if data != nil {
                if mCollectionView != nil {
                    mCollectionView.reloadData()
                    mCollectionView.scrollToItem(at: IndexPath.init(row: data!.count, section: 0), at: UICollectionViewScrollPosition.left, animated: false)
                }
                self.pageControl?.numberOfPages = data!.count
                self.startTimer()
            } else {
                self.pageControl?.numberOfPages = 0
            }
        }
    }
    
    // 可以添加自定义动画
    public var recyclerAnimation: CATransition? {
        didSet {
            recyclerAnimation?.subtype = animationDirection
            recyclerAnimation?.duration = animationDuration
            recyclerAnimation?.type = animationType
        }
    }
    
    public var animationType: String = kCATransitionPush {
        didSet {
            if recyclerAnimation != nil {
                recyclerAnimation?.type = animationType
            }
        }
    }
    
    public var animationDirection: String = kCATransitionFromRight {
        didSet {
            if recyclerAnimation != nil {
                recyclerAnimation?.subtype = animationDirection
            }
        }
    }
    
    public var animationDuration: CFTimeInterval = 1.0 {
        didSet {
            if recyclerAnimation != nil {
                recyclerAnimation?.duration = animationDuration
            }
        }
    }
    
    // 默认3秒滚动一次
    public var timeInterval: DispatchTimeInterval = .seconds(3)
    
    fileprivate var mCollectionView: UICollectionView!
    
    private var coverView: UIView!
 
    fileprivate var titleLabel: UILabel!
    
    fileprivate var pageControl: UIPageControl!
    
    // timer 用于自动播放
    fileprivate var recyclerTimer: DispatchSourceTimer!
    
    fileprivate let animationKey: String = "LYRecyclerViewAnimation"
    // 标题的字体
    public var titleFont: UIFont = UIFont.systemFont(ofSize: 14) {
        didSet {
            if titleLabel != nil {
                titleLabel.font = titleFont
            }
        }
    }
    
    // 标题的字体颜色
    public var titleColor: UIColor = UIColor.white {
        didSet {
            if titleLabel != nil {
                titleLabel.textColor = titleColor
            }
        }
    }
    
    public var pageIndicatorTintColor: UIColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5) {
        didSet {
            if pageControl != nil {
                pageControl.pageIndicatorTintColor = pageIndicatorTintColor
            }
        }
    }
    
    public var currentPageIndicatorTintColor: UIColor = UIColor.orange {
        didSet {
            if pageControl != nil {
                pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    private func setup() {
        
        self.mCollectionView = UICollectionView(frame: self.bounds, collectionViewLayout: LYRecyclerViewLayout())
        
        mCollectionView.dataSource = self
        mCollectionView.delegate = self
        mCollectionView.backgroundColor = UIColor.clear
        mCollectionView.register(LYRecyclerViewCell.classForCoder(), forCellWithReuseIdentifier: cellIdentifier)
        
        self.addSubview(mCollectionView)
        
        // 全填充
        //mCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let coverHeight: CGFloat = 30
        // 添加透明视图
        coverView = UIView(frame: CGRect(x: 0, y: self.bounds.height - coverHeight, width: self.bounds.width, height: coverHeight))
        coverView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        self.addSubview(coverView)
        coverView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        
        //添加标题栏
        titleLabel = UILabel(frame: CGRect(x: 8, y: 0, width: coverView.bounds.width - 8 * 2, height: coverView.bounds.height))
        titleLabel.font = titleFont
        titleLabel.textColor = titleColor
        titleLabel.textAlignment = .left
        titleLabel.lineBreakMode = .byTruncatingTail
        
        coverView.addSubview(titleLabel)
        
        pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = pageIndicatorTintColor
        pageControl.currentPageIndicatorTintColor = currentPageIndicatorTintColor
        
        coverView.addSubview(pageControl)
        
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        let constraintCenter = NSLayoutConstraint(item: pageControl, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: coverView, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0)
        let constraintRight = NSLayoutConstraint(item: pageControl, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: coverView, attribute: NSLayoutAttribute.right, multiplier: 1.0, constant: -10)
        
        self.addConstraint(constraintCenter)
        self.addConstraint(constraintRight)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        self.mCollectionView.frame = self.bounds
    }

    fileprivate func startTimer() {
        
        if autoPlayEnabled == false {
            return
        }
        
        stopTimer()
        
        // 这里使用一个单独的线程
        recyclerTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        
        recyclerTimer.setEventHandler {[weak self] in
            
            DispatchQueue.main.async {
                self?.nextItem()
            }
        }
        
        recyclerTimer.scheduleRepeating(deadline: DispatchTime.now() + self.timeInterval, interval: self.timeInterval)
        recyclerTimer.resume()
    }
    
    fileprivate func stopTimer() {
        
        if recyclerTimer == nil {
            return
        }
        
        if !recyclerTimer.isCancelled {
            recyclerTimer.cancel()
        }
        
        recyclerTimer = nil
    }
    
    private func nextItem() {

        let page = Int(self.mCollectionView.contentOffset.x / self.mCollectionView.bounds.width)
        let offsetX = Int(self.mCollectionView.frame.width) * (page + 1)
        
        print("===> \(page + 1)   \(offsetX)")
        self.mCollectionView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
        
        // 可添加自定义动画
        if let animation = self.recyclerAnimation {
            self.mCollectionView.layer.add(animation, forKey: "LYRecyclerViewAnimation")
        }
        
    }
    
    // 创建默认动画
    public func createDefaultAnimation() ->CAAnimation {
        
        let animation = CATransition()
        animation.duration = animationDuration
        animation.fillMode = kCAFillModeForwards
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.type = animationType
        animation.subtype = animationDirection
        
        return animation
    }

}

extension LYRecyclerView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    // MARK DataSource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        guard let data = self.data else {
            return 0
        }
        
        let rate = data.count <= 5 ? data.count : 5
        
        return data.count * rate
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! LYRecyclerViewCell
 
        print("cellForItem:    \(indexPath.row)")
        
        let item = positionItem(indexPath)!
        
        self.titleLabel.text = item.title

        self.delegate?.recyclerViewDidDisplay(self, imageView: cell.imageView, title: item.title, imageUrl: item.imageUrl, contentUrl: item.contentUrl)
        
        return cell
    }
    
    public func positionItem(_ indexPath: IndexPath) -> DataItem? {
        
        guard let data = self.data else {
            return nil
        }
        
        return data[indexPath.row % data.count]
    }
    
    // MARK delegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let item = positionItem(indexPath)!
        
        self.delegate?.recyclerViewDidSelected(self, indexPath: indexPath, title: item.title, imageUrl: item.imageUrl, contentUrl: item.contentUrl)
    }
    
    // MARK UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let width = scrollView.frame.width
        let page = Int((scrollView.contentOffset.x + width * 0.5) / width)
        
        if let data = self.data {
            
            self.pageControl.currentPage = page % data.count
            self.titleLabel.text = data[self.pageControl.currentPage].title
        }
        
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        self.stopTimer()
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        self.startTimer()
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        
        self.scrollViewDidStop(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        self.scrollViewDidStop(scrollView)
    }
    
    // 停止滚动
    fileprivate func scrollViewDidStop(_ scrollView: UIScrollView) {
        
        guard let data = self.data else {
            return
        }
        // 计算页面偏移量
        var page_offset = Int(scrollView.contentOffset.x / scrollView.bounds.width)

        // 重新从第一页开始显示
        if page_offset == 0 || page_offset == (self.mCollectionView.numberOfItems(inSection: 0) - 1) {
            page_offset = data.count - (page_offset == 0 ? 0 : 1)
            scrollView.contentOffset = CGPoint(x: CGFloat(page_offset) * scrollView.bounds.width, y: 0)
        }
    }
    
}

class LYRecyclerViewCell: UICollectionViewCell {
    
    // 显示图片组件
    var imageView: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.imageView = UIImageView(frame: self.bounds)
        self.imageView.contentMode = .scaleToFill
        self.imageView.clipsToBounds = true
        self.imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

// 布局规则
class LYRecyclerViewLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView = self.collectionView else {
            return;
        }
        
        if __CGSizeEqualToSize(collectionView.bounds.size, CGSize.zero) {
            return;
        }
        
        collectionView.bounces = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        
        self.minimumLineSpacing = 0
        self.minimumInteritemSpacing = 0
        
        self.itemSize = collectionView.bounds.size
        self.scrollDirection = .horizontal

    }
    
}
