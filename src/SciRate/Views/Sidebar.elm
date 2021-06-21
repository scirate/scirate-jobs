module SciRate.Views.Sidebar exposing (..)

import Browser
import Html                  exposing (Html, a, div , h3 , p, span, text, hr , small)
import Html.Attributes       exposing (class, href, title, target)
import Http
import Json.Decode           as Decode exposing (Decoder, bool, string, list)
import Json.Decode.Pipeline  exposing (required)
import Json.Encode           as Encode exposing (object)
import List.Extra            exposing (unique)
import Random                exposing (generate)
import Random.List           exposing (choices)
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

query = """
query {
  jobPostings(
      where: {
        active: {_eq: true}
        , job:
            { withdrawn: {_eq: false}
            , approved:  {_eq: true}
            }
        }
    ) {
    job {
      jobTitle
      jobUrl
      location
      organisationName
      organisationUrl
      remote
      academic
      tags
    }
  }
}
"""

type alias JobItem =
    { jobTitle : String
    , jobUrl : String
    , organisationName : String
    , organisationUrl : String
    , location : String
    , remote : Bool
    , academic : Bool
    , tags : List String
    }

fromJob : D.Job -> JobItem
fromJob job =
  JobItem
    job.jobTitle
    job.jobUrl
    job.organisationName
    job.organisationUrl
    job.location
    job.remote
    job.academic
    (cleanTags job.tags)

cleanTags : String -> List String
cleanTags ts =
      let a = List.map String.trim <| String.split "," ts
          b = unique a
          c = List.filter (not << String.isEmpty) b
       in c

type alias Model =
    { jobs : List JobItem
    }

emptyModel : Model
emptyModel =
    { jobs = [] 
    }

init : D.InitData -> ( Model, Cmd Msg )
init d =
    ( emptyModel
    , Cmd.batch [ runQuery d.graphqlUrl d.jwtToken query FetchJobsSuccess decodeJobs ]
    )

decodeJobs : Decoder JobData
decodeJobs =
  Decode.succeed JobData
    |> required "data" decodePostings

decodePostings : Decoder JobPostings
decodePostings =
  Decode.succeed JobPostings
    |> required "jobPostings" (list decodeJobBox)

decodeJobBox : Decoder JobBox
decodeJobBox =
  Decode.succeed JobBox
    |> required "job" (decodeJob)

decodeJob : Decoder JobItem
decodeJob =
  Decode.succeed JobItem
    |> required "jobTitle"         string
    |> required "jobUrl"           string
    |> required "organisationName" string
    |> required "organisationUrl"  string
    |> required "location"         string
    |> required "remote"           bool
    |> required "academic"         bool
    |> required "tags"             (Decode.map cleanTags string)

type alias JobData =
  { data : JobPostings }

type alias JobPostings =
  { jobPostings : List JobBox
  }

type alias JobBox = 
  { job : JobItem
  }

type Msg
    = NoOp
    | FetchJobsSuccess (Result Http.Error JobData)
    | SetVisibleJobs (List JobItem, List JobItem)

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      NoOp -> ( model, Cmd.none )

      SetVisibleJobs (jobs, _) ->
        let
            newModel = { model | jobs = jobs }
        in
            ( newModel, Cmd.none )

      FetchJobsSuccess r ->
        let
            cmd = case r of
              Ok jd -> 
                let jobs_ = List.map .job jd.data.jobPostings
                    gen   = choices 5 jobs_
                 in Cmd.batch [ generate SetVisibleJobs gen ]

              Err e -> Cmd.none
        in
          ( model, cmd )

view : Model -> Html Msg
view model = 
  if List.length model.jobs > 0
  then jobSidebar model.jobs
  else div [] []

jobSidebar : List JobItem -> Html Msg
jobSidebar jobs = 
    div [ class "job-sidebar" ]
        [ h3 []
             [ a [ href "/jobs" ] [ text "Open positions" ]
             , text " "
             , span [ class "beta" ]
                    [ a [ href "/jobs/about" ]
                        [ text "beta" ]
                    ]
             ]
        , div [ class "jobs" ] [ renderJobs jobs ]
        ]

jobSep = hr [] []

renderJobs : List JobItem -> Html Msg
renderJobs jobs = 
  div [ class "jobs" ] 
    <| List.intersperse jobSep (List.map renderJob jobs)

-- | Display an individual job.
renderJob : JobItem -> Html msg
renderJob job =
  div [ class "job" ]
      [ div [ class "title" ] 
            [ a [ target "_blank", href job.jobUrl ] [ text <| job.jobTitle ] ]
      , div [ class "org" ]
            [ a [ target "_blank", href job.organisationUrl ] [ text job.organisationName ] ]
      , div [ class "location" ]
            [ small [ ] [ text job.location ] ]
      , div [ class "tags" ]
            <| List.intersperse (span [] [ text ", "] )
            <| List.map renderTag job.tags
      , div [ class "kind" ]
            [ span [] [ text <| if job.academic then "Academic" else "Industry" ] ]
      ]

renderTag : String -> Html msg
renderTag t =
  span [ class "tag" ]
       [ a [ target "_blank", href <| "/jobs?tag=" ++ t ] [ text t ]
       ]
