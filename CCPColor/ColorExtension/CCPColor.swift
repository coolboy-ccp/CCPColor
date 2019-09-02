//
//  CCPColor.swift
//  CCPColor
//
//  Created by clobotics_ccp on 2019/9/2.
//  Copyright © 2019 cool-ccp. All rights reserved.
//

import UIKit


public struct RGBA {
    let r: CGFloat // 0~255.0
    let g: CGFloat // 0~255.0
    let b: CGFloat // 0~255.0
    let a: CGFloat // 0~1.0
    
    //keep表示以原值初始化
    init(_ r: CGFloat = 0, _ g: CGFloat = 0, _ b: CGFloat = 0, _ a: CGFloat = 0, keep: Bool = false) {
        self.r = keep ? r : r / 255.0
        self.g = keep ? g : g / 255.0
        self.b = keep ? b : b / 255.0
        self.a = a
    }
    
    
    /// 用数组的形式初始化
    ///
    /// - Parameters:
    ///   - values: 包含rgba数值的数组, 该数组元素必须为四个
    ///   - keep: 表示以原值初始化
    init(_ values: [CGFloat], keep: Bool = false) throws {
        guard values.count == 4 else {
            throw CCPColorError.invalidValues(values)
        }
        assert(values.count == 4, "创建RGBA的数组元素必须为4")
        self.r = keep ? values[0] : values[0] / 255.0
        self.g = keep ? values[1] : values[1] / 255.0
        self.b = keep ? values[2] : values[2] / 255.0
        self.a = values[3]
    }
    
    init(_ hex: String) throws {
        var str = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hex.count == 3 || hex.count == 6 else {
            throw CCPColorError.invalidHex(hex)
        }
        if str.count == 3 {
            for (index,char) in hex.enumerated() {
                str.insert(char, at: hex.index(hex.startIndex, offsetBy: index * 2))
            }
        }
        self.r = CGFloat((Int(hex, radix: 16)! >> 16) & 0xFF)
        self.g = CGFloat((Int(hex, radix: 16)! >> 8) & 0xFF)
        self.b = CGFloat((Int(hex, radix: 16)!) & 0xFF)
        self.a = 1.0
     }
}


public extension UIColor {
    static func rgba(_ value: RGBA) -> UIColor {
        return UIColor(red: value.r, green: value.b, blue: value.g, alpha: value.a)
    }
    
    static func rgba(_ values: [CGFloat], keep: Bool = false) -> UIColor {
        do {
            return rgba(try RGBA(values, keep: keep))
        }
        catch {
            print(error)
            return .white
        }
    }
    
    static func rgba(_ r: CGFloat = 0, _ g: CGFloat = 0, _ b: CGFloat = 0, _ a: CGFloat = 0, keep: Bool = false) -> UIColor{
        return rgba(RGBA(r,g,b,a, keep: keep))
    }
    
    static func hex(_ str: String) -> UIColor {
        do {
            return rgba(try RGBA(str))
        }
        catch {
            print(error)
            return .white
        }
    }
    
    var rgba: RGBA {
        get {
            guard let cpts = self.cgColor.components else { return RGBA() }
            do {
                return try RGBA(cpts, keep: true)
            }
            catch {
                print(error)
                return RGBA()
            }
        }
    }
    
    var alpha: CGFloat {
        set {
            self.withAlphaComponent(newValue)
        }
        get {
            return rgba.a
        }
    }
    
    /// 颜色转图片
    func image(in size: CGSize) -> UIImage? {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContext(size)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return nil
        }
        ctx.setFillColor(self.cgColor)
        ctx.fill(rect)
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    
    /// 获取图片上某点的颜色
    static func color(_ image: UIImage, at point: CGPoint) throws -> UIColor {
        let size = image.size
        guard let cgImg = image.cgImage else {
            throw CCPColorError.emptyCGImage(image)
        }
        guard CGRect(origin: .zero, size: size).contains(point) else {
            throw CCPColorError.invalidPoint(point)
        }
        guard let provider = cgImg.dataProvider else {
            throw CCPColorError.emptyDataProvider(image)
        }
        guard let data = CFDataGetBytePtr(provider.data) else {
            throw CCPColorError.emptyData(image)
        }
        let pixelInfo = Int(trunc(size.width) * trunc(point.y) + trunc(point.x) * 4)
        let values: [CGFloat] = (pixelInfo ... pixelInfo + 3).map {
            return CGFloat(data[$0])
        }
        return UIColor.rgba(try RGBA(values))
    }
}

enum CCPColorError: Error {
    case invalidPoint(CGPoint)
    case invalidHex(String)
    case invalidValues([CGFloat])
    case emptyCGImage(UIImage)
    case emptyDataProvider(UIImage)
    case emptyData(UIImage)
}

extension CCPColorError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidPoint(let point):
            return "[CCPColorError] 取颜色的点超出了图片的范围, point: \(point)"
        case .invalidValues(let values):
            return "[CCPColorError] 颜色值数组元素必须为4, value: \(values)"
        case .invalidHex(let hex):
            return "[CCPColorError] 错误的hex, hex: \(hex)"
        case .emptyCGImage(let img):
            return "[CCPColorError] .cgImage为空， image: \(img)"
        case .emptyDataProvider(let img):
            return "[CCPColorError] dataProvider为空, image: \(img)"
        case .emptyData(let img):
            return "[CCPColorError] data为空, image: \(img)"
        }
    }
}

public typealias GradientSetting = (inout CAGradientLayer) -> ()

public extension Array where Element == UIColor {
    
    /// 创建根据当前颜色组, 创建一个渐变layer
    ///
    /// - Parameter transform: layer的其他属性设置
    /// - Returns: 一个渐变layer
    func gradient(_ setting: GradientSetting? = nil) -> CAGradientLayer {
        var g = CAGradientLayer()
        g.colors = self.map { $0.cgColor }
        setting?(&g)
        return g
    }
}

public extension Array where Element == RGBA {
    
    /// 创建根据当前颜色值组, 创建一个渐变layer
    ///
    /// - Parameter transform: layer的其他属性设置
    /// - Returns: 一个渐变layer
    func gradient(_ setting: GradientSetting? = nil) -> CAGradientLayer {
        var g = CAGradientLayer()
        g.colors = self.map { UIColor.rgba($0).cgColor }
        setting?(&g)
        return g
    }
}

