//
//  AppTheme.swift
//  ChatExample
//
//  App 統一顏色主題系統
//

import SwiftUI

// MARK: - App Color Theme
internal struct AppTheme {
    
    // MARK: - 主要顏色
    static let primaryGreen = Color(red: 0x32/255, green: 0xCD/255, blue: 0x32/255) // #32CD32 亮綠色
    static let backgroundGreen = Color(red: 0xCC/255, green: 0xE8/255, blue: 0xCF/255) // #CCE8CF 護眼綠背景
    static let cardGreen = Color(red: 0xD8/255, green: 0xF0/255, blue: 0xDB/255) // #D8F0DB 淺護眼綠卡片
    static let lightCardGreen = Color(red: 0xE5/255, green: 0xF5/255, blue: 0xE7/255) // #E5F5E7 極淺護眼綠
    
    // MARK: - 文字顏色
    static let primaryText = Color(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255) // #1A1A1A 深黑色主要文字
    static let secondaryText = Color(red: 0x2F/255, green: 0x4F/255, blue: 0x4F/255) // #2F4F4F 深灰綠色次要文字
    static let hintText = Color(red: 0x4A/255, green: 0x4A/255, blue: 0x4A/255) // #4A4A4A 中等灰色提示文字
    
    // MARK: - UIKit 顏色 (用於外觀設定)
    static let uiPrimaryGreen = UIColor(red: 0x32/255, green: 0xCD/255, blue: 0x32/255, alpha: 1.0)
    static let uiBackgroundGreen = UIColor(red: 0xCC/255, green: 0xE8/255, blue: 0xCF/255, alpha: 1.0)
    static let uiPrimaryText = UIColor(red: 0x1A/255, green: 0x1A/255, blue: 0x1A/255, alpha: 1.0)
    static let uiHintText = UIColor(red: 0x4A/255, green: 0x4A/255, blue: 0x4A/255, alpha: 1.0)
    
    // MARK: - 特殊顏色
    static let white = Color.white
    static let red = Color.red
    static let gray = Color.gray
}

// MARK: - Color Extension for Easy Access
extension Color {
    
    // 主要顏色
    static let appPrimaryGreen = AppTheme.primaryGreen
    static let appBackgroundGreen = AppTheme.backgroundGreen
    static let appCardGreen = AppTheme.cardGreen
    static let appLightCardGreen = AppTheme.lightCardGreen
    
    // 文字顏色
    static let appPrimaryText = AppTheme.primaryText
    static let appSecondaryText = AppTheme.secondaryText
    static let appHintText = AppTheme.hintText
}