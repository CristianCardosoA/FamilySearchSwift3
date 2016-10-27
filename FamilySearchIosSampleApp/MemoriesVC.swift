//
//  MemoriesVC.swift
//  FamilySearchIosSampleApp
//
//  Created by Eduardo Flores on 6/11/16.
//  Copyright © 2016 FamilySearch. All rights reserved.
//

import Foundation
import UIKit

class MemoriesVC : UICollectionViewController
{
    var user : User?
    
    let arrayOfImageThumbnailHrefs = NSMutableArray()
    
    var accessToken : String?
    
    override func viewDidLoad() {
        
        // display waiting activity indicator
        Utilities.displayWaitingView(self.view)
        
        // get the access token from NSUserDefaults
        let preferences = UserDefaults.standard
        accessToken = preferences.string(forKey: Utilities.KEY_ACCESS_TOKEN)
        
        // get an array of the links of images
        getMemoriesLinksForUser(accessToken!,
                                 completionLinks: {(completionLinks, errorLinks) -> Void in
                                    if (errorLinks == nil)
                                    {
                                        // update collection view to display images
                                        DispatchQueue.main.async(execute: {
                                                // remove waiting activity indicator
                                                Utilities.removeWaitingView(self.view)
                                                
                                                // update collectionView
                                                self.collectionView?.reloadData()
                                            })
                                    }
        })
    }
    
    func getMemoriesLinksForUser(_ accessToken:String,
                                  completionLinks:@escaping (_ responseLinks:NSMutableArray?, _ errorLinks:NSError?) -> ())
    {
        let configuration = URLSessionConfiguration.default;
        let headers: [AnyHashable: Any] = ["Accept":"application/json", "Authorization":"Bearer " + accessToken];
        configuration.httpAdditionalHeaders = headers;
        let session = URLSession(configuration: configuration)
        
        guard let memoriesHref = URL(string: user!.artifactsHref!) else {
            return
        }
        
        let memoriesTask = session.dataTask(with: memoriesHref, completionHandler: { [weak self] (memoriesData, response, memoriesError) in
            do
            {
                let memoriesDataJson = try JSONSerialization.jsonObject(with: memoriesData!, options: .allowFragments) as! [String:AnyObject];
                
                let sourceDescriptions = memoriesDataJson["sourceDescriptions"] as? [NSDictionary]
                for sourceDescription in sourceDescriptions!
                {
                    // for this demo we're only downloading images, so we need to check if the sourceDescription contains an image
                    let mediaType = sourceDescription["mediaType"] as? String
                    if (mediaType == "image/jpeg")
                    {
                        let links = sourceDescription["links"] as? NSDictionary
                        let linkImageThumbnail = links?["image-thumbnail"] as? NSDictionary
                        let linkImageThumbnailHref = linkImageThumbnail!["href"] as? String
                        self?.arrayOfImageThumbnailHrefs.add(linkImageThumbnailHref!)
                    }
                    else
                    {
                        continue
                    }
                }
                completionLinks(self?.arrayOfImageThumbnailHrefs, nil)
            }
            catch
            {
                completionLinks(nil, memoriesError as NSError?)
            }
        }) 
        memoriesTask.resume()
    }
    
    // MARK: - UI Collection View Controller methods
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayOfImageThumbnailHrefs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemoryCell", for: indexPath) as! MemoryCell
        
        let linkHref = arrayOfImageThumbnailHrefs.object(at: (indexPath as NSIndexPath).row) as? String
        
        // make sure the link and token variables are not nil
        if let link = linkHref, let token = accessToken
        {
            Utilities.getImageFromUrl(link, accessToken: token) { (data, response, error)  in
                DispatchQueue.main.async { () -> Void in
                    guard let imageData = data else {
                        // no image data
                        return
                    }
                    cell.memoryImageView.image = UIImage(data: imageData)
                }
            }
        }
        else
        {
            // TODO: handle case for when linkHref or accessToken are nil
        }
        
        return cell
    }
}










































