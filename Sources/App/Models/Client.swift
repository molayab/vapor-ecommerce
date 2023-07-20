//
//  File.swift
//  
//
//  Created by Mateo Olaya on 30/06/23.
//

import Vapor
import Fluent

final class Client: Model, Content {
    static let schema = "clients"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "telephone")
    var telephone: String
    
    @Field(key: "address")
    var address: String
    
    @Field(key: "notes")
    var notes: String
}
