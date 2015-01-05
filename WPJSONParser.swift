//
//  WPJSONParser.swift
//  Spi0n
//
//  Created by Vavelin Kevin on 08/08/14.
//  Copyright (c) 2014 Vavelin Kevin. All rights reserved.
//

import UIKit

class WPJSONParser: NSObject {
    
    //MARK: Variables
    private var page : Int
    private var categoryPage: Int
    private var urlSite : String
    private var categoryID: String!
    var categoryDic : NSDictionary? = nil
    let queryQ : dispatch_queue_t
    
    //MARK: Function
    
    //Init required because of singleton
    required init(url:NSString) {
        urlSite = url
        page = 1
        categoryPage = 1
        queryQ = dispatch_queue_create("QueryQ", DISPATCH_QUEUE_SERIAL)
        super.init()
        self.getCategory { (response) -> () in
            self.categoryDic = response
        }
    }
    
    //Singleton pattern
    class func sharedInstance(url:NSString)->WPJSONParser {
        struct Static {
            static var instance : WPJSONParser? = nil
            static var onceToken : dispatch_once_t = 0
        }
        
        dispatch_once(&Static.onceToken) {
            Static.instance = self(url: url)
        }
        return Static.instance!
    }
    
    func getRecentPost(recentPost:(post:[AnyObject])->()) {
        var url : NSURL = NSURL(string: "http://\(urlSite)/api/get_recent_posts/?count=20")!
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url)
            if data != nil {
                var responseJson: AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if responseJson != nil {
                    var response : [AnyObject] = responseJson.objectForKey("posts") as [AnyObject]
                    dispatch_async(dispatch_get_main_queue(), {
                        recentPost(post:response)
                    })
                    
                }
            }
        })
    }
    
    func getLastPost(recentPost:(post:[AnyObject])->()) {
        var url : NSURL = NSURL(string: "http://\(urlSite)/api/get_recent_posts/?count=1")!
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url)
            if data != nil {
                var responseJson: AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if responseJson != nil {
                    var response : [AnyObject] = responseJson.objectForKey("posts") as [AnyObject]
                    dispatch_async(dispatch_get_main_queue(), {
                        recentPost(post:response)
                    })
                    
                }
            }
        })
    }
    
    func getCategory(category:(response:NSDictionary)->()) {
        var url : NSURL = NSURL(string: "http://\(urlSite)/api/get_category_index")!
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url)
            if data != nil {
                var responseJson : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if responseJson != nil {
                    var categoryInfos = responseJson.objectForKey("categories") as NSArray
                    var categoryName = NSMutableArray()
                    var categoryIdArray = NSMutableArray()
                    for var i = 0; i < categoryInfos.count; i++ {
                        var titleDictionary : NSDictionary = categoryInfos.objectAtIndex(i) as NSDictionary
                        var idCategory = categoryInfos.objectAtIndex(i) as NSDictionary
                        var categoryId : AnyObject! = idCategory.objectForKey("id")
                        var categoryIdString : String = "\(categoryId)"
                        var title : NSString = titleDictionary.objectForKey("title") as NSString
                        categoryName.addObject(title.stringByReplacingOccurrencesOfString("&amp;", withString: "&"))
                        categoryIdArray.addObject(categoryIdString)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        category(response:NSDictionary(objects: categoryIdArray, forKeys: categoryName))
                    })
                } else {
                    category(response:NSDictionary(object: "Erreur lors de la connexion à la base de donnée", forKey: "Erreur"))
                }
                
            }
        })
    }
    
    func search(text:String, searchResult:(result:NSArray)->()) {
        var url : NSURL = NSURL(string: "http://\(urlSite)/api/get_search_results?search=\(text)")!
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url)
            if data != nil {
                var jsonData : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if jsonData != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        searchResult(result:jsonData.objectForKey("posts") as NSArray)
                    })
                }
            }
        })
    }
    
    func getPostOfCategory(categoryId:String, post:(post:NSArray)->()) {
        var url : NSURL = NSURL(string: "http://\(urlSite)/api/get_category_posts/?id=\(categoryId)!")!
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url)
            if data != nil {
                var jsonData : NSDictionary! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as NSDictionary
                if jsonData != nil {
                    dispatch_async(dispatch_get_main_queue(), {
                        post(post:jsonData.objectForKey("posts") as NSArray)
                    })
                }
            }
        })
    }
    
    func getPostWithId(postsId:NSArray, postFromId:(post:NSArray)->()) {
        var posts = NSMutableArray()
        dispatch_async(queryQ, {
            for var i = 0; i < postsId.count; i++ {
                var url = NSURL(string: "http://\(self.urlSite)/api/get_post/?id=\(postsId.objectAtIndex(i))")
                var data : NSData? = NSData(contentsOfURL: url!)
                if data != nil {
                    var jsonData : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                    if jsonData != nil {
                        posts.addObject(jsonData.objectForKey("post")!)
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), {
                postFromId(post:posts)
            })
        })
    }
    
    func getCountOfPost(post: NSArray, count:(count:NSArray)->()) {
        var url = NSURL(string: "http://\(urlSite)/api/get_category_index")
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url!)
            if data != nil {
                var jsonData : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if jsonData != nil {
                    var categoryInfos : NSArray = jsonData.objectForKey("categories")! as NSArray
                    var countArray = NSMutableArray()
                    for var i = 0; i < categoryInfos.count; i++ {
                        var categoryId: AnyObject! = categoryInfos.objectAtIndex(i)
                        countArray.addObject(categoryId.objectForKey("post_count")!)
                    }
                    dispatch_async(dispatch_get_main_queue(), {
                        count(count:countArray)
                    })
                }
            }
            
        })
    }
    
    func loadMorePost(newPost:(post:NSArray)->()) {
        page++;
        var url = NSURL(string: "http://\(urlSite)/api/get_recent_posts/?page=\(page)")
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url!)
            if data != nil {
                var jsonData : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if jsonData != nil {
                    var newPostArray : NSArray = jsonData.objectForKey("posts") as NSArray
                    dispatch_async(dispatch_get_main_queue(), {
                        newPost(post:newPostArray)
                    })
                }
            }
        })
    }
    
    func loadMorePostInCategory(categoryId:String, newPost:(post:NSArray)->()) {
        if categoryId != categoryID {
            categoryID = categoryId
            categoryPage = 1
        }
        categoryPage++;
        var url = NSURL(string: "http://\(urlSite)/api/get_category_posts/?id=\(categoryId)&page=\(categoryPage)")
        dispatch_async(queryQ, {
            var data : NSData? = NSData(contentsOfURL: url!)
            if data != nil {
                var jsonData : AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil)
                if jsonData != nil {
                    var newPostArray : NSArray = jsonData.objectForKey("posts") as NSArray
                    dispatch_async(dispatch_get_main_queue(), {
                        newPost(post:newPostArray)
                    })
                }
            }
        })
        
    }
    
    func thumbnailOfPost(post:NSArray, images:(thumbnail:[AnyObject])->()) {
        var imageUrlArray : [AnyObject] = []
        for postArticle in post {
            var thumbnail : String = postArticle.objectForKey("thumbnail") as String
            imageUrlArray.append(thumbnail)
        }
        images(thumbnail: imageUrlArray)
    }
    
    func getImagesOnPost(post:AnyObject, images:(images:[AnyObject])->()) {
        var imageUrlArray : [AnyObject] = []
            var attachments : NSArray = post.objectForKey("attachments")! as NSArray
            if attachments.count > 0 {
                for imagesPost in attachments {
                    var imagesDictionary : NSDictionary = imagesPost.objectForKey("images") as NSDictionary
                    var imagesInfos : NSDictionary = imagesDictionary.objectForKey("full") as NSDictionary
                    var imageUrl : String = imagesInfos.objectForKey("url") as String
                    imageUrlArray.append(imageUrl)
                }
            } else {
                imageUrlArray.append("")
            }
        images(images: imageUrlArray)
    }
    
    func getAttachmentsOfPost(post:NSArray, images:(images:[AnyObject])->()) {
        var imageUrlArray : [AnyObject] = []
        for postArticle in post {
            var attachments : NSArray = postArticle.objectForKey("attachments")! as NSArray
            if attachments.count > 0 {
                var contentOfAttachments : NSDictionary = attachments.firstObject as NSDictionary
                var imagesDictionary : NSDictionary = contentOfAttachments.objectForKey("images") as NSDictionary
                var imagesInfos : NSDictionary = imagesDictionary.objectForKey("full") as NSDictionary
                var imageUrl : String = imagesInfos.objectForKey("url") as String
                imageUrlArray.append(imageUrl)
            } else {
                imageUrlArray.append("")
            }
        }
        if imageUrlArray.count == post.count {
            images(images: imageUrlArray)
        }
    }
    
}

