# SwiftyTweet
I like Swift as a programming language, am trying to use it as much as possible. This is my take on on using Swift as a script to allow photographers to share their work on Twitter

## Problem Statement
While Instagram is the current defacto social network for photographers to share our work, I decided to also share my work on Twitter! As most tweets are generally in text format, having graphic visuals might give an extra edge to stand out in that social media platform. However, the common issue that I normally face is scheduling the tweets, we may spend hours editing the photos but we may not share them daily. 

I created this tool for 2 reasons:
1. Trying to solve my own problem where I have to manually tweet my work
2. I want to make more things with Swift!

## How to use SwiftyTweet
Steps:
1. Edit your photos like you normally would
2. Store your image into the image folder of SwiftyTweet
3. Open up `tweetInfo.json` and file up the details of your tweet. Normal Twitter rules (char length and etc) applies. I like posting my tweets daily
4. Run script in terminal `swift sh main.swift`
5. Open up Twitter, if all goes well, smile!

## About tweetInfo.json
I decided to use a JSON format as it's quite easy to understand, and also easy to parse the information for SwiftyTweet.
It is crucial for `image_name` to be exact with the image filename you stored in the Image folder. The tweet generated would combine `caption` and `hashtags` together, I splitted it up just for visibility sake. When the script is run, it will check against the `post_date`, if it matches, the tweet will be generated accordingly.

## Things that can be improved
1. It currently doesn't support specific times, only dates. So if when this script is run, and it mathces any date, it will post all of them in separate tweets. As I am the kind that only post daily, not exactly sure how strong the usecase for this.

2. Not much luck is separating the `main.swift` file into smaller files of its own. It could be better organized instead of lumping all of it into the `main.swift` file. If you have any ideas on how to separate out into smaller files and get it to be referred in `main.swift` file, let me know, will be happy to do so. 

## Automate
I setup a local cron job on my machine to ensure the script is run daily. This is not a necessary step, but it does make life a lot easier by us focusing just on the photography aspect, and let the script take care of the sharing of your work. 
Here are some materials that can help you setup:
1. [Apple]( https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
2. [Medium](https://medium.com/better-programming/https-medium-com-ratik96-scheduling-jobs-with-crontab-on-macos-add5a8b26c30)

3. [Samwize Blog](https://samwize.com/2018/07/07/schedule-cron-jobs-on-mac-with-crontab/)
