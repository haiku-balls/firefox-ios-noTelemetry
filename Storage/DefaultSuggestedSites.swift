// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation

open class DefaultSuggestedSites {
    public static let urlMap = [
        "https://www.amazon.com/": [
            "as": "https://www.amazon.in",
            "cy": "https://www.amazon.co.uk",
            "da": "https://www.amazon.co.uk",
            "de": "https://www.amazon.de",
            "dsb": "https://www.amazon.de",
            "en_GB": "https://www.amazon.co.uk",
            "et": "https://www.amazon.co.uk",
            "ff": "https://www.amazon.fr",
            "ga_IE": "https://www.amazon.co.uk",
            "gu_IN": "https://www.amazon.in",
            "hi_IN": "https://www.amazon.in",
            "hr": "https://www.amazon.co.uk",
            "hsb": "https://www.amazon.de",
            "ja": "https://www.amazon.co.jp",
            "kn": "https://www.amazon.in",
            "mr": "https://www.amazon.in",
            "or": "https://www.amazon.in",
            "sq": "https://www.amazon.co.uk",
            "ta": "https://www.amazon.in",
            "te": "https://www.amazon.in",
            "ur": "https://www.amazon.in",
            "en_CA": "https://www.amazon.ca",
            "fr_CA": "https://www.amazon.ca"
        ]
    ]

    public static let sites = [
        "default": [
            
        ],
        "zh_CN": [
            SuggestedSiteData(
                url: "http://mozilla.com.cn",
                bgColor: "0xbc3326",
                imageUrl: "asset://suggestedsites_mozchina",
                faviconUrl: "asset://mozChinaLogo",
                trackingId: 700,
                title: "火狐社区"
            ),
            SuggestedSiteData(
                url: "https://m.baidu.com/?from=1000969c",
                bgColor: "0x00479d",
                imageUrl: "asset://suggestedsites_baidu",
                faviconUrl: "asset://baiduLogo",
                trackingId: 701,
                title: "百度"
            ),
            SuggestedSiteData(
                url: "http://sina.cn",
                bgColor: "0xe60012",
                imageUrl: "asset://suggestedsites_sina",
                faviconUrl: "asset://sinaLogo",
                trackingId: 702,
                title: "新浪"
            ),
            SuggestedSiteData(
                url: "http://info.3g.qq.com/g/s?aid=index&g_f=23946&g_ut=3",
                bgColor: "0x028cca",
                imageUrl: "asset://suggestedsites_qq",
                faviconUrl: "asset://qqLogo",
                trackingId: 703,
                title: "腾讯"
            ),
            SuggestedSiteData(
                url: "http://m.taobao.com",
                bgColor: "0xee5900",
                imageUrl: "asset://suggestedsites_taobao",
                faviconUrl: "asset://taobaoLogo",
                trackingId: 704,
                title: "淘宝"
            ),
            SuggestedSiteData(
                url: """
                https://union-click.jd.com/jdc?e=618%7Cpc%7C&p=JF8BAKgJK1olXDYDZBoCUBV\
                IMzZNXhpXVhgcCEEGXVRFXTMWFQtAM1hXWFttFkhAaihBfRN1XE5ZMipYVQ1uYwxAa1cZb\
                QIHUV9bCUkQAF8LGFoRXgcAXVttOEsSMyRmGmsXXAcAXFdaAEwVM28PH10TVAMHVVpbDE8\
                nBG8BKydLFl5fCQ5eCUsSM184GGsSXQ8WUiwcWl8RcV84G1slXTZdEAMAOEkWAmsBK2s
                """,
                bgColor: "0xc71622",
                imageUrl: "asset://suggestedsites_jd",
                faviconUrl: "asset://jdLogo",
                trackingId: 705,
                title: "京东"
            )
        ]
    ]
}
