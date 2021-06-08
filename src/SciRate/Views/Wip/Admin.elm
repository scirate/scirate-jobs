module SciRate.Views.Admin exposing (..)

import Browser
import SciRate.Data          as D
-- import Html                  exposing (Html, a, div , h3 , p, span, text, hr , small)
-- import Html.Attributes       exposing (class, href, title)

main : Program D.InitData Model Msg
main =
    Browser.element
        { view          = Debug.todo "view"
        , init          = Debug.todo "init"
        , update        = Debug.todo "update"
        , subscriptions = \_ -> Sub.none
        }

allJobsQuery = """
query {
  job {
    organisationName
    organisationUrl
    jobTitle
    jobUrl
    remote
    location
    contactEmail
    created
    modified
    academic
    token
    contactName
    tags
    closingDate
    withdrawn
    approved
  }
}
"""

type alias FullJob =
    { organisationName : String
    , organisationUrl  : String
    , jobTitle         : String
    , jobUrl           : String
    , remote           : Bool
    , location         : String
    , contactEmail     : String
    , created          : String
    , modified         : String
    , academic         : Bool
    , token            : String
    , contactName      : String
    , tags             : String
    , closingDate      : String
    , withdrawn        : Bool
    , approved         : Bool
    }

type alias Model
  = { jobs : List FullJob
    }


-- decodeOneFullJob : Decoder (Maybe FullJob)
-- decodeOneFullJob =
--   let
--     mkOneJob dr      = List.head dr.jobs
--     decodeDataResult = Decode.succeed DataResult |> required "jobs" (list decodeJob)
--   in Decode.succeed mkOneJob |> required "data" decodeDataResult

-- decodeDataResult 
--   = Decode.succeed DataResult |> required "jobs" (list decodeJob)

-- decodeJob : Decoder Job
-- decodeJob =
--   Decode.succeed Job
--     |> required "organisationName" string
--     |> required "organisationUrl"  string
--     |> required "jobTitle"         string
--     |> required "jobUrl"           string
--     |> required "remote"           bool
--     |> required "location"         string
--     |> required "contactEmail"     string
--     |> required "created"          string
--     |> required "modified"         string
--     |> required "academic"         bool
--     |> required "token"            string
--     |> required "contactName"      string
--     |> required "tags"             string
--     |> required "closingDate"      string
--     |> required "withdrawn"        bool
--     |> required "approved"         bool




-- emptyModel : Model
-- emptyModel
--   = { allJobs = []
--     }


-- init : D.InitData -> (Model, Cmd Msg)
-- init d =
--   ( emptyModel
--   , runQuery
--         d.graphqlUrl
--         d.jwtToken
--         -- query
--         FetchJobsSuccess
--         -- decodeJobs
--   )


-- view : Model -> Html Msg
-- view model = 
--   div [] []






type Msg
    = NoOp
--     | FetchJobsSuccess


-- update : Msg -> Model -> ( Model, Cmd Msg )
-- update msg model =
--   case msg of
--     NoOp -> ( model, Cmd.none )

--     FetchJobsSuccess ->
--       ( model, Cmd.none )

