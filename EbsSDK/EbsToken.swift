//
// Created by Serge Rybchinsky on 2019-04-22.
// Copyright (c) 2019 Vitalii Poponov. All rights reserved.
//

import Foundation

public struct EbsToken {
	enum CodingKeys: String {
		case verifyToken = "verify_token"
		case expired = "expired"
	}

	public let verifyToken: String
	public let expired: String
}