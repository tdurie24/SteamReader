//
//  AppHeaderView.swift
//  SteamReader
//
//  Created by Kyle Roberts on 4/29/16.
//  Copyright © 2016 Kyle Roberts. All rights reserved.
//

import UIKit
import AlamofireImage
import Async

class AppHeaderView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var releaseLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    var app: App?
    var isObserving = false
    
    var gradientLayer = CAGradientLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        importView()
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        importView()
    }
    
    func importView() {
        for view in subviews {
            view.removeFromSuperview()
        }
        
        NSBundle.mainBundle().loadNibNamed("AppHeaderView", owner: self, options: nil)
        addSubview(view)
        view.snp_makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        
        gradientLayer.frame = self.imageView.bounds
        gradientLayer.colors = [self.view.backgroundColor!.CGColor as CGColorRef, UIColor.clearColor().CGColor as CGColorRef]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        imageView.layer.addSublayer(gradientLayer)
    }
    
    func configureWithApp(app: App?) {
        if isObserving {
            app!.removeObserver(self, forKeyPath: "details")
        }
        
        self.app = app
        nameLabel.text = app?.name
        
        app!.addObserver(self, forKeyPath: "details", options: NSKeyValueObservingOptions.New, context: nil)
        isObserving = true
        if app!.details != nil {
            configureWithDetails(app!.details!)
        }
    }
    
    func configureWithDetails(details: AppDetails) {
        let currencyFormatter = CurrencyFormatter()
        
        let score = details.metacriticScore == 0 ? "--" : details.metacriticScore!.stringValue
        var htmlAttributes: NSAttributedString? {
            guard
                let data = details.about!.dataUsingEncoding(NSUTF8StringEncoding)
                else { return nil }
            do {
                return try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType,NSCharacterEncodingDocumentAttribute:NSUTF8StringEncoding], documentAttributes: nil)
            } catch let error as NSError {
                print(error.localizedDescription)
                return  nil
            }
        }
        
        aboutLabel.text = htmlAttributes?.string ?? ""
        priceLabel.text = currencyFormatter.stringFromSteamPrice(details.currentPrice!)
        releaseLabel.text = details.releaseDate!
        scoreLabel.text = score + "/100"
        imageView.af_setImageWithURL(NSURL(string: details.headerImage!)!, placeholderImage: nil, filter: AspectScaledToFillSizeWithRoundedCornersFilter(size: imageView.frame.size, radius: 5), imageTransition: .CrossDissolve(0.2), completion: { response in
            Async.main {
                self.imageView.image = response.result.value
                self.gradientLayer.frame = self.imageView.bounds
            }
        })
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "details" && app!.details != nil {
            Async.main {
                self.configureWithDetails(self.app!.details!)
            }
        }
    }
    
    deinit {
        if isObserving {
            app?.removeObserver(self, forKeyPath: "details")
            isObserving = false
        }
    }

}

class AppHeaderCell: UITableViewCell {
    var appView: AppHeaderView?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        appView = AppHeaderView()
        contentView.addSubview(appView!)
        appView?.snp_makeConstraints(closure: { (make) in
            make.edges.equalTo(self)
        })
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        appView?.imageView.af_cancelImageRequest()
        appView?.imageView.layer.removeAllAnimations()
        appView?.imageView.image = nil
        if appView != nil && (appView!.isObserving) {
            appView!.app!.removeObserver(appView!, forKeyPath: "details")
            appView!.isObserving = false
        }
    }
    
}
