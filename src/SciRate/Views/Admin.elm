module SciRate.Views.Admin exposing (..)

import Browser
import Html                  exposing (Html, a, div , h3 , p, span, text, hr , small)
import Html.Attributes       exposing (class, href, title)
import Http
import Json.Decode           as Decode exposing (Decoder, bool, string, list, int)
import Json.Decode.Pipeline  exposing (required)
import Json.Encode           as Encode exposing (object)
import SciRate.Data          as D
import SciRate.Querying      exposing (runQuery)

main : Program D.InitData Model Msg
main =
    Browser.element
        { view          = view
        , init          = init
        , update        = update
        , subscriptions = \_ -> Sub.none
        }

-- Things to do on this page:
--
-- 1. See _every_ job posted
-- 2. Connect it to a (potential) job listing
-- 3. Highlight the rows based on various facts:
--    1. Posted, not paid for
--    2. Posted, paid, online,
--    3. Posted, paid, not online,

allJobPostingsQuery = """
query {
  jobPostings {
    id
    jobId
    startDate
    endDate
    active
  }
}
"""

allJobsQuery = """
query {
  jobs {
    id
    organisationName
    organisationUrl
    emailedConfirmation
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

type alias JobPosting =
  { jobId            : Int
  , startDate        : String
  , endDate          : String
  , active           : Bool
  }


decodeJobPosting : Decoder JobPosting
decodeJobPosting =
  Decode.succeed JobPosting
    |> required "jobId"            int
    |> required "startDate"        string
    |> required "endDate"          string
    |> required "active"           bool
    -- TODO: Can't easily show payment reference; need to leave it undecoded.

type alias FullJob =
    { id                  : Int
    , organisationName    : String
    , organisationUrl     : String
    , emailedConfirmation : Bool
    , jobTitle            : String
    , jobUrl              : String
    , remote              : Bool
    , location            : String
    , contactEmail        : String
    , created             : String
    , modified            : String
    , academic            : Bool
    , token               : String
    , contactName         : String
    , tags                : String
    , closingDate         : String
    , withdrawn           : Bool
    , approved            : Bool
    }

type alias Model
  = { jobs       : List FullJob
    , postings   : List JobPosting
    , bothLoaded : String
    }

decodeJob : Decoder FullJob
decodeJob =
  Decode.succeed FullJob
    |> required "id"                  int
    |> required "organisationName"    string
    |> required "organisationUrl"     string
    |> required "emailedConfirmation" bool
    |> required "jobTitle"            string
    |> required "jobUrl"              string
    |> required "remote"              bool
    |> required "location"            string
    |> required "contactEmail"        string
    |> required "created"             string
    |> required "modified"            string
    |> required "academic"            bool
    |> required "token"               string
    |> required "contactName"         string
    |> required "tags"                string
    |> required "closingDate"         string
    |> required "withdrawn"           bool
    |> required "approved"            bool

decodeJobs : Decoder (List FullJob)
decodeJobs =
  Decode.succeed identity 
    |> required "data"
       ( Decode.succeed identity 
          |> required "jobs" (list decodeJob)
       )

decodeJobPostings : Decoder (List JobPosting)
decodeJobPostings =
  Decode.succeed identity 
    |> required "data"
       ( Decode.succeed identity 
          |> required "jobPostings" (list decodeJobPosting)
       )

type alias JobData =
  { data : List FullJob }

emptyModel : Model
emptyModel
  = { jobs = []
    , postings = []
    , bothLoaded = ""
    }

init : D.InitData -> ( Model, Cmd Msg )
init d =
    ( emptyModel
    , Cmd.batch 
        [ runQuery d.graphqlUrl d.jwtToken allJobsQuery FetchJobsSuccess decodeJobs
        , runQuery d.graphqlUrl d.jwtToken allJobPostingsQuery FetchJobPostingsSuccess decodeJobPostings
        ]
    )

view : Model -> Html Msg
view model = 
  div []
      [ renderJobs model.jobs
      ]


renderJobs : List FullJob -> Html Msg
renderJobs jobs =
  div []
      [ div [] <| List.map renderJob jobs
      ]

renderJob : FullJob -> Html Msg
renderJob job = div [] [ text job.jobTitle ]

-- Note: Terrible code.
maybeLink : Model -> Model
maybeLink m = 
  if List.length m.jobs > 0 && List.length m.postings > 0
  then m -- TODO:
  else m

type Msg
    = NoOp
    | FetchJobsSuccess (Result Http.Error (List FullJob))
    | FetchJobPostingsSuccess (Result Http.Error (List JobPosting))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    NoOp -> ( model, Cmd.none )

    FetchJobPostingsSuccess r ->
        let
            newModel = case r of
              Ok postings -> { model | postings = postings }
              Err e   -> Debug.log ("ygh" ++ Debug.toString e) model
        in
          ( maybeLink newModel, Cmd.none )

    FetchJobsSuccess r ->
        let
            newModel = case r of
              Ok jobs -> { model | jobs = jobs }
              Err e   -> model
        in
          ( maybeLink newModel, Cmd.none )

