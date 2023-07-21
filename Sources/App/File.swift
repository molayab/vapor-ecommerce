//
//  File.swift
//  
//
//  Created by Mateo Olaya on 21/07/23.
//

import Vapor
import Leaf
import CSRF


struct CSRFHeaderFieldTag: UnsafeUnescapedLeafTag {
    func render(_ ctx: LeafContext) throws -> LeafData {
        try ctx.requireParameterCount(0)
        
        guard let request = ctx.request else {
            throw Abort(.internalServerError)
        }
        
        let token = CSRF.createToken(from: request)
        let html = "<meta name=\"_csrf\" content=\"\(token)\" />"
        
        return LeafData.string(html)
    }
}
