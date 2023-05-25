//
//  StoreItem.swift
//  MusicPlayerAPI
//
//  Created by mike liu on 2023/5/24.
//

import Foundation


class SearchResponse: Codable {
    let resultCount: Int
    let results: [StoreItem]
}

class StoreItem: Codable {
    let artistName:String
    let trackName: String
    let collectionName: String?
    let previewUrl: URL
    let artworkUrl100: URL
    let trackPrice: Double?
    let isStreamable: Bool?
    
    var artworkUrl500: URL {
            artworkUrl100.deletingLastPathComponent().appending(path: "500x500bb.jpg")
        }
}
