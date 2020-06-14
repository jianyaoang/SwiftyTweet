#!/usr/bin/swift sh

//  Created by Jay Ang on 28/03/2020.
//  Copyright © 2020 JayAng. All rights reserved.

import Foundation
import AppKit

import Swifter // @mattdonnelly ~> 2.3.0
import SwiftScriptRunner // @mgrebenets ~> 1.0.1

struct Credentials {
        
    /// TODO: Add these keys. Details can be found on your Twitter dev account
    static let consumerKey: String = ""
    static let consumerSecret: String = ""
    static let oauthToken: String = ""
    static let oauthTokenSecret: String = ""
}

struct Constants {
    
    /// Max char limit allowed by Twitter
    static let maxCharLength: Int = 280
    
    /// TODO: Add these path. The path below is an example
    static let imageDirectoryPath: String = "A/B/C/SwiftyTweet/SwiftyTweet/Image"
    static let jsonDirectoryPath: String = "A/B/C/SwiftyTweet/SwiftyTweet/tweetInfo.json"
}

/// Details of the JSON that would be used to generate the tweet
struct TweetInfo: Codable {
    let caption: String
    let imageName: String
    var image: Data?
    let postDate: String
    let hashtags: String
    
    enum CodingKeys: String, CodingKey {
        case caption = "caption"
        case hashtags = "hashtags"
        case imageName = "image_name"
        case postDate = "post_date"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        caption = try values.decode(String.self, forKey: .caption)
        imageName = try values.decode(String.self, forKey: .imageName)
        postDate = try values.decode(String.self, forKey: .postDate)
        hashtags = try values.decode(String.self, forKey: .hashtags)
    }
}

struct ImageMediaDataManager {
    
    static func convertImageIntoData(tweetInfo: inout TweetInfo) -> TweetInfo {
        let fileManager = FileManager.default
        
        let path = Constants.imageDirectoryPath

        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)

            guard !items.isEmpty else {
                print("No image found in directory\n")
                return tweetInfo
            }
            
            let image = items.first { $0 == tweetInfo.imageName }
            guard let matchedImage = image else {
                print("Unable to find image with matching the imageName specified\n")
                return tweetInfo
            }
    
            let matchedImagePath = path + "/\(matchedImage)"
            let loadedImage = NSImage(contentsOfFile: matchedImagePath)
            let compressedImageData = compress(image: loadedImage, under: 4.0)
                        
            tweetInfo.image = compressedImageData
            return tweetInfo
        
        } catch {
            print("Error converting TweetInfo image into data: \(error.localizedDescription)\n")
            return tweetInfo
        }
    }
    
    /// To ensure we don't exceed Twitter max image size
    private static func compress(image: NSImage?, under megabytes: CGFloat) -> Data? {
        guard
            let image = image,
            let tiffRepresentation = image.tiffRepresentation else {
                return nil
        }
        
        let imageRep = NSBitmapImageRep(data: tiffRepresentation)
            
        let compressionRatio = NSNumber(value: 1.0)
        var properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: compressionRatio]
        let compressedData = imageRep?.representation(
            using: .jpeg,
            properties: properties
        )
        
        guard let imageData = compressedData else { return nil }
        var compressedImageData = imageData
        
        var imageCompressionRatio = 0.8
        let megabytesGoal = megabytes * 1024 * 1024
        
        while CGFloat(compressedImageData.count) > megabytesGoal {
            imageCompressionRatio = imageCompressionRatio * 0.7
       
            var properties: [NSBitmapImageRep.PropertyKey: Any] = [
                .compressionFactor: imageCompressionRatio
            ]
            
            let data = imageRep?.representation(
                using: .jpeg,
                properties: properties
            )
            
            if let imgData = data {
                compressedImageData = imgData
            } else {
                break
            }
        
            if imageCompressionRatio <= 0.5 {
                break
            }
        }
        
        return compressedImageData
    }
}

final class TweetManager {
    
    private var semaphore = DispatchSemaphore(value: 0)
    private let runner = SwiftScriptRunner()

    private let swifter: Swifter
    
    init() {
        swifter = Swifter(
            consumerKey: Credentials.consumerKey,
            consumerSecret: Credentials.consumerSecret,
            oauthToken: Credentials.oauthToken,
            oauthTokenSecret: Credentials.oauthTokenSecret
        )
    }
    
    func parseJSON() -> [TweetInfo] {
        let fileManager = FileManager.default
        
        /// change to your desired JSON file path
        let path = Constants.jsonDirectoryPath
        
        var tweetInfos: [TweetInfo] = []
        
        do {
            let urlFilePath = URL(fileURLWithPath: path)
            let jsonData = try Data(contentsOf: urlFilePath, options: .mappedIfSafe)
            tweetInfos = try JSONDecoder().decode([TweetInfo].self, from: jsonData)
            
            print("Decode TweetInfos \n \(tweetInfos)\n")
            
            return tweetInfos
            
        } catch {
            print("Failed to map tweetInfo.json with error: \(error.localizedDescription)")
        }
        
        return tweetInfos
    }
    
    func tweetImage(tweetInfo: TweetInfo) {
        guard let imageData = tweetInfo.image else {
            print("Failed to tweet image. No image data found.\n")
            return
        }
        
        runner.lock()
        
        let tweetStatus = tweetInfo.caption + "\n\n" + tweetInfo.hashtags
        
        guard tweetStatus.count <= Constants.maxCharLength else {
            print("Tweet status exceeds max char length, need to reduce characters count")
            return
        }
        
        swifter.postTweet(status: tweetStatus, media: imageData, success: { [weak self] status in
            self?.runner.unlock()
            print("Posted tweet\n \(status)\n")
            
        }, failure: { [weak self] error in
            self?.runner.unlock()
            print("Yikes! Failed to tweet image \(error.localizedDescription)\n")
        })
        
        runner.wait()
    }
}

extension DateFormatter {
    
    static func postTweetDate(date: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        return dateFormatter.date(from: date)
    }
    
    static func shouldPostOn(date: Date) -> Bool {
        let today = Date()

        let currentCalendar = Calendar.current
        
        let todayComponents = currentCalendar.dateComponents([.year, .month, .day], from: today)
        
        guard
            let todayYear = todayComponents.year,
            let todayMonth = todayComponents.month,
            let todayDay = todayComponents.day
            else {
            return false
        }
        
        let postingComponents = currentCalendar.dateComponents([.year, .month, .day], from: date)
        
        guard
            let postingYear = postingComponents.year,
            let postingMonth = postingComponents.month,
            let postingDay = postingComponents.day
            else {
            return false
        }
        
        return (todayYear == postingYear) &&
            (todayMonth == postingMonth) &&
            (todayDay == postingDay)
    }
}

let tweetManager = TweetManager()
let tweetInfos = tweetManager.parseJSON()

for tweetInfo in tweetInfos {
    guard let postTweetdate = DateFormatter.postTweetDate(date: tweetInfo.postDate) else {
        print("Unable to format post tweet date\n")
        continue
    }

    guard DateFormatter.shouldPostOn(date: postTweetdate) else {
        print("We shouldn't be posting this tweet today\n")
        continue
    }

    var copyTweetInfo = tweetInfo
    let updatedTweetInfo = ImageMediaDataManager.convertImageIntoData(tweetInfo: &copyTweetInfo)
    tweetManager.tweetImage(tweetInfo: updatedTweetInfo)
}
