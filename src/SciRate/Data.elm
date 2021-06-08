module SciRate.Data exposing (..)

import List
import Json.Decode as Decode exposing (Decoder, bool, string, list)
import Json.Decode.Pipeline  exposing (required)

type alias Job =
    { jobTitle         : String
    , jobUrl           : String
    , organisationName : String
    , organisationUrl  : String
    , closingDate      : String
    , remote           : Bool
    , contactEmail     : String
    , contactName      : String
    , tags             : String
    , academic         : Bool
    , location         : String
    , withdrawn        : Bool
    , approved         : Bool
    }

type alias DataResult 
  = { jobs : List Job }

-- {
--   "data": {
--     "insert_jobs": {
--       "returning": [
--         {
--           "id": 23
--         }
--       ]
--     }
--   }
-- }
decodeJobId : Decoder (Maybe Int)
decodeJobId = 
  let
      x = 1
      g = Decode.succeed identity |> required "insert_jobs" f
      f = Decode.succeed identity |> required "returning" (Decode.list h)
      h = Decode.succeed identity |> required "id" Decode.int
  in
      Decode.succeed List.head |> required "data" g

decodeAffectedRows : Decoder Int
decodeAffectedRows =
  let
      g = Decode.succeed identity |> required "update_jobs" f
      f = Decode.succeed identity |> required "affected_rows" Decode.int
  in
      Decode.succeed identity |> required "data" g

decodeOneJob : Decoder (Maybe Job)
decodeOneJob =
  let
    mkOneJob dr = List.head dr.jobs
  in Decode.succeed mkOneJob |> required "data" decodeDataResult

decodeDataResult 
  = Decode.succeed DataResult |> required "jobs" (list decodeJob)

decodeJob : Decoder Job
decodeJob =
  Decode.succeed Job
    |> required "jobTitle"         string
    |> required "jobUrl"           string
    |> required "organisationName" string
    |> required "organisationUrl"  string
    |> required "closingDate"      string
    |> required "remote"           bool
    |> required "contactEmail"     string
    |> required "contactName"      string
    |> required "tags"             string
    |> required "academic"         bool
    |> required "location"         string
    |> required "withdrawn"        bool
    |> required "approved"         bool
  
emptyJob =
  { jobTitle         = ""
  , jobUrl           = ""
  , organisationName = ""
  , organisationUrl  = ""
  , remote           = False
  , location         = ""
  , contactEmail     = ""
  , tags             = ""
  , academic         = False
  , closingDate      = ""
  , contactName      = ""
  , withdrawn        = False
  , approved         = False
  }

decodeInitData : Decoder InitData
decodeInitData =
  Decode.succeed InitData
    |> required "queryString" string
    |> required "jwtToken"    string
    |> required "graphqlUrl"  string

type alias InitData =
  { queryString : String
  , jwtToken    : String
  , graphqlUrl  : String
  }
