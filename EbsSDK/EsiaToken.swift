//
// Created by Serge Rybchinsky on 2019-04-22.
// Copyright (c) 2019 Vitalii Poponov. All rights reserved.
//

import Foundation

public struct EsiaToken {

	enum CodingKeys: String {
		case code
		case state
	}

	public var code: String
	public var state: String
}