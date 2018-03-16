//
//  Protocols.swift
//  Contentful
//
//  Created by JP Wright on 07.03.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Protocol for resources inside Contentful
public protocol Resource {

    /// System fields
    var sys: Sys { get }
}


public protocol ResourceProtocol {
    /// The unique identifier of the Resource.
    var id: String { get }

    /// The date representing the last time the Contentful Resource was updated.
    var updatedAt: Date? { get }

    /// The date that the Contentful Resource was first created.
    var createdAt: Date? { get }

    /// The code which represents which locale the Resource of interest contains data for.
    var localeCode: String { get }
}

public extension ResourceProtocol where Self: Resource {
    public var id: String {
        return sys.id
    }

    public var type: String {
        return sys.type
    }

    public var updatedAt: Date? {
        return sys.updatedAt
    }

    public var createdAt: Date? {
        return sys.createdAt
    }

    public var localeCode: String {
        return sys.locale!
    }
}

/// A protocol enabling strongly typed queries to the Contentful Delivery API via the SDK.
public protocol EntryQueryable {

    /// The CodingKey representing the names of each of the fields for the corresponding content type.
    /// These coding keys should be the same as those used when implementing Decodable.
    associatedtype Fields: CodingKey
}

internal protocol EndpointAccessible {
    static var endpoint: Endpoint { get }
}

/// Entities conforming to this protocol have a QueryType that the SDK can use to make generic fetch requests.
public protocol ResourceQueryable {

    associatedtype QueryType: AbstractQuery
}

public typealias ContentTypeId = String


/**
 Classes conforming to this protocol can be passed into your Client instance so that fetch methods
 asynchronously returning MappedCollection can be used and classes of your own definition can be returned.

 It's important to note that there is no special handling of locales so if using the locale=* query parameter,
 you will need to implement the special handing in your `init(from decoder: Decoder) throws` initializer for your class.

 Example:

 ```
 func fetchMappedEntries(with query: Query<Cat>,
 then completion: @escaping ResultsHandler<MappedArrayResponse<Cat>>) -> URLSessionDataTask?
 ```
 */
public protocol EntryDecodable: ResourceProtocol, Decodable {
    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }
}

// TODO: USE THIS
public protocol AssetDecodable: ResourceProtocol, Decodable {}

public class DeletedResource: Resource, ResourceProtocol, Decodable {

    public let sys: Sys

    init(sys: Sys) {
        self.sys = sys
    }
}


// MARK: Internal

extension LocalizableResource: Hashable {

    public var hashValue: Int {
        return id.hashValue
    }
}

extension LocalizableResource: Equatable {}
/// Equatable implementation for `LocalizableResource`
public func == (lhs: LocalizableResource, rhs: LocalizableResource) -> Bool {
    return lhs.id == rhs.id && lhs.sys.updatedAt == rhs.sys.updatedAt
}
