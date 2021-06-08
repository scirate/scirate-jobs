module SciRate.Querying exposing (..)

import Http
import Json.Encode  as Encode exposing (object)
import Json.Decode  as Decode exposing (Decoder)

runQuery
  :  String 
  -> String
  -> String
  -> (Result Http.Error a -> msg) 
  -> Decoder a 
  -> Cmd msg
runQuery graphqlUrl token query msg decoder =
  Http.request
    { method  = "POST"
    , headers = [ Http.header "Authorization" <| "Bearer " ++ token ]
    , url     = graphqlUrl
    , body    = Http.jsonBody (object [("query", Encode.string query)])
    , expect  = Http.expectJson msg decoder
    , timeout = Nothing
    , tracker = Nothing
    }
