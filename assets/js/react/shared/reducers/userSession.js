import { mergeDeepRight, mergeDeepWith, append } from "ramda"
import { SEND_HELLO_SUCCESS, SEND_COMMAND_SUCCESS } from "../actions/channel"

export const defaultState = {
  playerId: null,
  playerName: null,
  messages: []
}

export default function(state = defaultState, action) {
  switch (action.type) {
    case SEND_HELLO_SUCCESS:
      if (state.playerId) {
        return state
      }
      return mergeDeepRight(state, {
        playerId: action.data.player_id,
        playerName: action.data.player_name
      })
    case SEND_COMMAND_SUCCESS:
      const msg = action.data.body && action.data.body.text
      return mergeDeepWith(append, { messages: msg }, state)
    default:
      return state
  }
}
