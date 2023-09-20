//
//  ParticipantResponse.swift
//  Tinodios
//
//  Created by Djaka Permana on 29/08/23.
//  Copyright © 2023 Tinode LLC. All rights reserved.
//

import Foundation

public struct ParticipantResponse {
    var call_room_id: String
    var chat_room_id: String
    
    init(call_room_id: String, chat_room_id: String) {
        self.call_room_id = call_room_id
        self.chat_room_id = chat_room_id
    }
    
    internal init?(createParticipantResponse: Grpc_GetParticipantsResponse) {
        self.init(
            call_room_id: createParticipantResponse.callRoomID,
            chat_room_id: createParticipantResponse.chatRoomID
        )
    }
}
