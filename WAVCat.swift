//
//  WavTester.swift
//  SpeechToTextTester
//
//  Created by Christian Schraga on 6/5/17.
//  Copyright © 2017 Straight Edge Digital. All rights reserved.
//

import UIKit
import Darwin

struct WavHeader {
    var channels:Int
    var samplesPerSecond:Int
    var bytesPerSecond:Int
    var dataSize:Int
}

class WavTester: NSObject {

    private var contentData: Data
    private var initialData: Data?
    private var headerBytes: [UInt8]
    private var headerInfo:  WavHeader?

    
    override init(){
        self.contentData = Data()
        self.headerBytes = []
        super.init()
    }
    
    /**
     Initialized WAVCat instance with the NSData of the first wav file, its headers will
     be modified and used for the final data.
     :param: initialData NSData with contents of wav file
     */
    convenience init(data: Data) {
        self.init()
        self.initialData = data
        if let header = self.validate(data){
            self.headerBytes = header
            let other = extractData(data)
            self.contentData.append(other)
        }
    }
    
    private final func extractHeaders(_ data:Data) -> [UInt8] {
        return [UInt8](data)
    }

    
    private func extractData(_ data: Data) -> Data {
        //return data.subdataWithRange(NSMakeRange(44, data.length - 44))
        var result = Data()
        let len = data.count
        if len >= 44 {
            result = data.subdata(in: 44 ..< len)
        }
        return result
    }

    private func validate(_ data: Data) -> [UInt8]? {
        // extract values for validation
        let header            = extractHeaders(data)
        let fileDescription   = header[0...3]
        let fileSize          = header[4...7]
        let wavDescription    = header[8...11]
        let formatDescription = header[12...14]
        let headerDataSize    = header[40...43]
        var dataSize:UInt32   = 0
        
        for (index, byte) in headerDataSize.enumerated() {
            dataSize |= UInt32(byte) << UInt32(8 * index)
        }
        
        let expectedDataSize = data.count - 44 // 44 is the size of the header
        if let str = String(bytes: fileDescription+wavDescription+formatDescription, encoding: String.Encoding.utf8){
            
            // very simple way to validate
            if str == "RIFFWAVEfmt" && expectedDataSize == Int(dataSize) {
                
                // currently only data size is being used
                //                self.headerInfo = Header(channels: 0, samplesPerSecond: 0, bytesPerSecond: 0, dataSize: dataSize)
                return header
            }
        }
        return nil
    }
    
    func append(data: Data){
        if let header = validate(data){
            let dataSizeBytes    = header[40...43]
            let currentSizeBytes = headerBytes[40...43]
            
            var currentSize:UInt32 = 0
            var dataSize:UInt32    = 0
            
            for (index, byte) in dataSizeBytes.enumerated() {
                currentSize |= UInt32(byte) << UInt32(8 * index)
            }
            
            for (index, byte) in currentSizeBytes.enumerated() {
                dataSize |= UInt32(byte) << UInt32(8 * index)
            }
            
            let newSize = currentSize + dataSize
            let fileSize = newSize + 44 - 8
            
            headerBytes[7] = UInt8(truncatingBitPattern: fileSize >> 24)
            headerBytes[6] = UInt8(truncatingBitPattern: fileSize >> 16)
            headerBytes[5] = UInt8(truncatingBitPattern: fileSize >> 8)
            headerBytes[4] = UInt8(truncatingBitPattern: fileSize)
            
            headerBytes[43] = UInt8(truncatingBitPattern: newSize >> 24)
            headerBytes[42] = UInt8(truncatingBitPattern: newSize >> 16)
            headerBytes[41] = UInt8(truncatingBitPattern: newSize >> 8)
            headerBytes[40] = UInt8(truncatingBitPattern: newSize)
            
            let other = extractData(data)
            contentData.append(other)
            
        } else {
            // throw error
        }
        
    }
    
    func getAllData() -> Data{
        var temp = Data()
        let head = Data(bytes: &headerBytes, count: headerBytes.count)
        temp.append(head)
        temp.append(contentData)
        return temp
    }
}
