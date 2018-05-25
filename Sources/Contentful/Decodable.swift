//
//  Decodable.swift
//  Contentful
//
//  Created by JP Wright on 05.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation


/// Helper methods for decoding instances of the various types in your content model.
public extension Decoder {

    // The LinkResolver used by the SDK to cache and resolve links.
    public var linkResolver: LinkResolver {
        return userInfo[.linkResolverContextKey] as! LinkResolver
    }

    internal var contentTypes: [ContentTypeId: EntryDecodable.Type] {
        guard let contentTypes = userInfo[.contentTypesContextKey] as? [ContentTypeId: EntryDecodable.Type] else {
            fatalError(
                """
            Make sure to pass your content types into the `Client` intializer
            so the SDK can properly deserializer your own types if you are using the `fetchMappedEntries` methods
            """)
        }
        return contentTypes
    }

    public var localizationContext: LocalizationContext {
        return userInfo[.localizationContextKey] as! LocalizationContext
    }

    /// Helper method to extract the sys property of a Contentful resource.
    public func sys() throws -> Sys {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        let sys = try container.decode(Sys.self, forKey: .sys)
        return sys
    }

    /// Extract the nested JSON container for the "fields" dictionary present in Entry and Asset resources.
    public func contentfulFieldsContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> ContentfulFieldsContainer<NestedKey> {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        let fieldsContainer = try container.nestedContainer(keyedBy: keyType, forKey: .fields)
        let contentfulFieldsContainer = ContentfulFieldsContainer(keyedDecodingContainer: fieldsContainer, localizationContext: localizationContext)
        return contentfulFieldsContainer
    }
}

internal extension Decodable where Self: EntryDecodable {
    // This is a magic workaround for the fact that dynamic metatypes cannot be passed into
    // initializers such as UnkeyedDecodingContainer.decode(Decodable.Type), yet static methods CAN
    // be called on metatypes.
    static func popEntryDecodable(from container: inout UnkeyedDecodingContainer) throws -> Self {
        let entryDecodable = try container.decode(self)
        return entryDecodable
    }
}

internal extension Decodable where Self: AssetDecodable {
    static func popAssetDecodable(from container: inout UnkeyedDecodingContainer) throws -> Self {
        let assetDecodable = try container.decode(self)
        return assetDecodable
    }
}

public extension CodingUserInfoKey {
    public static let linkResolverContextKey = CodingUserInfoKey(rawValue: "linkResolverContext")!
    public static let contentTypesContextKey = CodingUserInfoKey(rawValue: "contentTypesContext")!
    public static let localizationContextKey = CodingUserInfoKey(rawValue: "localizationContext")!
}

extension JSONDecoder {

    /**
     Returns the JSONDecoder owned by the Client. Until the first request to the CDA is made, this
     decoder won't have the necessary localization content required to properly deserialize resources
     returned in the multi-locale format.
     */
    public static func withoutLocalizationContext() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom(Date.variableISO8601Strategy)
        return jsonDecoder
    }

    /**
     Updates the JSONDecoder provided by the client with the localization context necessary to deserialize
     resources returned in the multi-locale format with the locale information provided by the space.
     */
    public func update(with localizationContext: LocalizationContext) {
        userInfo[.localizationContextKey] = localizationContext
    }

    public func setContentTypes(_ types: [EntryDecodable.Type]) {
        userInfo[.contentTypesContextKey] = types
    }

    public var linkResolver: LinkResolver {
        return userInfo[.linkResolverContextKey] as! LinkResolver
    }
}

// Fields JSON container.
public extension KeyedDecodingContainer {

    /**
     Caches a link to be resolved once all resources in the response have been serialized.

     - Parameter key: The KeyedDecodingContainer.Key representing the JSON key were the related resource is found
     - Parameter localeCode: The locale of the link source to be used when caching the relationship for future resolving
     - Parameter decoder: The Decoder being used to deserialize the JSON to a user-defined class
     - Parameter callback: The callback used to assign the linked item at a later time.
     - Throws: Forwards the error if no link object is in the JSON at the specified key.
     */
    public func resolveLink(forKey key: KeyedDecodingContainer.Key,
                            decoder: Decoder,
                            callback: @escaping (Any) -> Void) throws {

        let linkResolver = decoder.linkResolver
        if let link = try decodeIfPresent(Link.self, forKey: key) {
            linkResolver.resolve(link, callback: callback)
        }
    }

    /**
     Caches an array of linked entries to be resolved once all resources in the response have been serialized.

     - Parameter key: The KeyedDecodingContainer.Key representing the JSON key were the related resources arem found
     - Parameter localeCode: The locale of the link source to be used when caching the relationship for future resolving
     - Parameter decoder: The Decoder being used to deserialize the JSON to a user-defined class
     - Parameter callback: The callback used to assign the linked item at a later time.
     - Throws: Forwards the error if no link object is in the JSON at the specified key.
     */
    public func resolveLinksArray(forKey key: KeyedDecodingContainer.Key,
                                  decoder: Decoder,
                                  callback: @escaping (Any) -> Void) throws {

        let linkResolver = decoder.linkResolver
        if let links = try decodeIfPresent(Array<Link>.self, forKey: key) {
            linkResolver.resolve(links, callback: callback)
        }
    }
}

public struct ContentfulFieldsContainer<K>: KeyedDecodingContainerProtocol where K: CodingKey {


    /**
     Caches a link to be resolved once all resources in the response have been serialized.

     - Parameter key: The KeyedDecodingContainer.Key representing the JSON key were the related resource is found
     - Parameter localeCode: The locale of the link source to be used when caching the relationship for future resolving
     - Parameter decoder: The Decoder being used to deserialize the JSON to a user-defined class
     - Parameter callback: The callback used to assign the linked item at a later time.
     - Throws: Forwards the error if no link object is in the JSON at the specified key.
     */
    public func resolveLink(forKey key: ContentfulFieldsContainer.Key,
                            decoder: Decoder,
                            callback: @escaping (Any) -> Void) throws {

        let linkResolver = decoder.linkResolver
        if let link = try decodeIfPresent(Link.self, forKey: key) {
            linkResolver.resolve(link, callback: callback)
        }
    }

    /**
     Caches an array of linked entries to be resolved once all resources in the response have been serialized.

     - Parameter key: The KeyedDecodingContainer.Key representing the JSON key were the related resources arem found
     - Parameter localeCode: The locale of the link source to be used when caching the relationship for future resolving
     - Parameter decoder: The Decoder being used to deserialize the JSON to a user-defined class
     - Parameter callback: The callback used to assign the linked item at a later time.
     - Throws: Forwards the error if no link object is in the JSON at the specified key.
     */
    public func resolveLinksArray(forKey key: ContentfulFieldsContainer.Key,
                                  decoder: Decoder,
                                  callback: @escaping (Any) -> Void) throws {

        let linkResolver = decoder.linkResolver
        if let links = try decodeIfPresent(Array<Link>.self, forKey: key) {
            linkResolver.resolve(links, callback: callback)
        }
    }

    public typealias Key = K

    private let keyedDecodingContainer: KeyedDecodingContainer<K>

    private let localizationContext: LocalizationContext

    internal init(keyedDecodingContainer: KeyedDecodingContainer<K>, localizationContext: LocalizationContext) {
        self.keyedDecodingContainer = keyedDecodingContainer
        self.localizationContext = localizationContext
    }

    public var codingPath: [CodingKey] {
        return keyedDecodingContainer.codingPath
    }

    public var allKeys: [K] {
        return keyedDecodingContainer.allKeys
    }

    public func contains(_ key: K) -> Bool {
        return keyedDecodingContainer.contains(key)
    }

    public func decodeNil(forKey key: K) throws -> Bool {
        return try keyedDecodingContainer.decodeNil(forKey: key)
    }

    public func decode(_ type: Bool.Type, forKey key: K) throws -> Bool {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Int.Type, forKey key: K) throws -> Int {
       return try _decode(type, forKey: key)
    }

    public func decode(_ type: Int8.Type, forKey key: K) throws -> Int8 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Int16.Type, forKey key: K) throws -> Int16 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Int32.Type, forKey key: K) throws -> Int32 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Int64.Type, forKey key: K) throws -> Int64 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: UInt.Type, forKey key: K) throws -> UInt {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: UInt8.Type, forKey key: K) throws -> UInt8 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: UInt16.Type, forKey key: K) throws -> UInt16 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: UInt32.Type, forKey key: K) throws -> UInt32 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: UInt64.Type, forKey key: K) throws -> UInt64 {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Float.Type, forKey key: K) throws -> Float {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: Double.Type, forKey key: K) throws -> Double {
        return try _decode(type, forKey: key)
    }

    public func decode(_ type: String.Type, forKey key: K) throws -> String {
        return try _decode(type, forKey: key)
    }

    // Walks the fallback chain if the
    private func _decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        if let value = try? keyedDecodingContainer.decode(type, forKey: key) {
            return value
        } else {
            var currentLocale = localizationContext.currentLocale
            let localesContainer = try keyedDecodingContainer.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
            while !localesContainer.contains(JSONCodingKeys(stringValue: currentLocale.code)!) {
                // Break loops if we've walked through all of the locales.
                guard let fallbackLocaleCode = currentLocale.fallbackLocaleCode else { break }

                // Go to the next locale.
                if let fallbackLocale = localizationContext.locales[fallbackLocaleCode] {
                    currentLocale = fallbackLocale
                }
            }
            if let value = try? localesContainer.decode(type, forKey: JSONCodingKeys(stringValue: currentLocale.code)!) {
                return value
            }
            throw SDKError.noValuePresent(fieldKey: key)
        }
    }
    public func decode<T>(_ type: T.Type, forKey key: K) throws -> T where T: Decodable {
        return try _decode(type, forKey: key)
    }

    public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type,
                                           forKey key: K) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        return try keyedDecodingContainer.nestedContainer(keyedBy: type, forKey: key)
    }

    public func nestedUnkeyedContainer(forKey key: K) throws -> UnkeyedDecodingContainer {
        return try keyedDecodingContainer.nestedUnkeyedContainer(forKey: key)
    }

    public func superDecoder() throws -> Decoder {
        return try keyedDecodingContainer.superDecoder()
    }

    public func superDecoder(forKey key: K) throws -> Decoder {
        return try keyedDecodingContainer.superDecoder(forKey: key)
    }
}

public class LinkResolver {

    private var dataCache: DataCache = DataCache()

    private var callbacks: [String: [(Any) -> Void]] = [:]

    private static let linksArrayPrefix = "linksArrayPrefix"

    public func cache(assets: [Asset]) {
        for asset in assets {
            dataCache.add(asset: asset)
        }
    }

    public func cache(entryDecodables: [EntryDecodable]) {
        for entryDecodable in entryDecodables {
            dataCache.add(entry: entryDecodable)
        }
    }

    public func cache(resources: [ResourceProtocol & Decodable]) {
        for resource in resources {
            if let asset = resource as? Asset {
                dataCache.add(asset: asset)
            } else if let entryDecodable = resource as? EntryDecodable {
                dataCache.add(entry: entryDecodable)
            }
        }
    }

    // Caches the callback to resolve the relationship represented by a Link at a later time.
    internal func resolve(_ link: Link, callback: @escaping (Any) -> Void) {
        let key = DataCache.cacheKey(for: link)
        // New swift 4 API!
        callbacks[key, default: []] += [callback]
    }

    internal func resolve(_ links: [Link], callback: @escaping (Any) -> Void) {
        let linksIdentifier: String = links.reduce(into: LinkResolver.linksArrayPrefix) { (id, link) in
            id += "," + DataCache.cacheKey(for: link)
        }
        callbacks[linksIdentifier, default: []] += [callback]
    }

    // Executes all cached callbacks to resolve links and then clears the callback cache and the data cache
    // where resources are cached before being resolved.
    public func churnLinks() {
        for (linkKey, callbacksList) in callbacks {
            if linkKey.hasPrefix(LinkResolver.linksArrayPrefix) {
                let firstKeyIndex = linkKey.index(linkKey.startIndex, offsetBy: LinkResolver.linksArrayPrefix.count)
                let onlyKeysString = linkKey[firstKeyIndex ..< linkKey.endIndex]
                // Split creates a [Substring] array, but we need [String] to index the cache
                let keys = onlyKeysString.split(separator: ",").map { String($0) }
                let items: [Any] = keys.compactMap { dataCache.item(for: $0) }
                for callback in callbacksList {
                    callback(items as Any)
                }
            } else {
                let item = dataCache.item(for: linkKey)
                for callback in callbacksList {
                    callback(item as Any)
                }
            }
        }
        self.callbacks = [:]
        self.dataCache = DataCache()
    }
}


// Inspired by https://gist.github.com/mbuchetics/c9bc6c22033014aa0c550d3b4324411a
internal struct JSONCodingKeys: CodingKey {
    internal var stringValue: String

    internal init?(stringValue: String) {
        self.stringValue = stringValue
    }

    internal var intValue: Int?

    internal init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

internal extension KeyedDecodingContainer {

    internal func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }

    internal func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

    internal func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    internal func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

    internal func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            }
            // Custom contentful types.
            else if let fileMetaData = try? decode(Asset.FileMetadata.self, forKey: key) {
                dictionary[key.stringValue] = fileMetaData
            } else if let link = try? decode(Link.self, forKey: key) {
                dictionary[key.stringValue] = link
            } else if let location = try? decode(Location.self, forKey: key) {
                dictionary[key.stringValue] = location
            }

            // These must be called after attempting to decode all other custom types.
            else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

internal extension UnkeyedDecodingContainer {

    internal mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            }
            // Custom contentful types.
            else if let fileMetaData = try? decode(Asset.FileMetadata.self) {
                array.append(fileMetaData) // Custom contentful type.
            } else if let link = try? decode(Link.self) {
                array.append(link) // Custom contentful type.
            }
            // These must be called after attempting to decode all other custom types.
            else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            } else if let location = try? decode(Location.self) {
                array.append(location)
            }

        }
        return array
    }

    internal mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {

        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
