//
//  SupabaseClient.swift
//  CCZUHelper
//
//  Created by rayanceking on 2025/12/13.
//

import Supabase
import Foundation

/// 配置 JSON 解码器以正确处理 Supabase 的日期格式
private let supabaseJSONDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    // Supabase 返回 ISO 8601 格式的 timestamptz
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

/// 配置 JSON 编码器
private let supabaseJSONEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
}()

/// Supabase 客户端实例
// Read Supabase configuration from Info.plist keys `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
// Add them to your Xcode project (Info > Custom iOS Target Properties) for secure configuration.
let _supabaseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "https://udrykrwyvnvmavbrdnnm.supabase.co"
let _supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""

guard let _supabaseURL = URL(string: _supabaseURLString) else {
    fatalError("Invalid SUPABASE_URL in Info.plist: \(_supabaseURLString)")
}

let supabase = SupabaseClient(
    supabaseURL: _supabaseURL,
    supabaseKey: _supabaseAnonKey,
    options: SupabaseClientOptions(
        db: .init(schema: "public"),
        auth: .init(autoRefreshToken: true),
        global: .init(
            headers: [:],
            session: .shared
        )
    )
)
