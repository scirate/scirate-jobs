module SciRate.Views.FullList exposing (..)

import Browser
import Dict                  exposing (Dict)
import Set                   exposing (Set)
import Url                   exposing (Url)
import Html                  exposing ( Html, a, div, h2, p, span, text
                                      , hr, input, small, label, select, option
                                      , button
                                      )
import Html.Attributes       exposing (class, href, title, for, type_, name
                                      , id, placeholder, value, selected
                                      )
import Html.Events           exposing (onInput, onClick)
import Http
import Json.Decode           as Decode exposing (Decoder, bool, string, list)
import Json.Decode.Pipeline  exposing (required)
import Json.Encode           as Encode exposing (object)
import List.Extra            exposing (unique)
import SciRate.Data          as D
import SciRate.Misc          exposing (queryStringItems)
import SciRate.Querying      exposing (runQuery)
import SciRate.Views.Sidebar exposing ( JobItem, renderJob, JobData
                                      , query, decodeJobs)

main : Program D.InitData Model Msg
main =
    Browser.element
        { view          = view
        , init          = init
        , update        = update
        , subscriptions = \_ -> Sub.none
        }

type alias Model =
    { visibleJobs  : List JobItem
    , allJobs      : List JobItem
    , allCompanies : List String
    , allLocations : List String
    , allTags      : List String
    , allKinds     : List String
    --
    , jobTitleFilter   : Maybe String
    , selectedCompany  : Maybe String
    , selectedLocation : Maybe String
    , selectedTags     : Set String
    , selectedKind     : Maybe String
    }


init : D.InitData -> ( Model, Cmd Msg )
init d =
  let
    items = queryStringItems d.queryString
    providedTag = Dict.get "tag" items
    selectedTags =
      case providedTag of
        Nothing -> Set.empty
        Just t  -> Set.fromList [t]

    selectedCompany = Dict.get "company" items
    model = { allJobs      = []
            , allCompanies = []
            , allLocations = []
            , allTags      = []
            , visibleJobs  = []
            , allKinds     = ["Academic", "Industry"]
            --
            , jobTitleFilter   = Nothing
            , selectedCompany  = selectedCompany
            , selectedLocation = Nothing
            , selectedTags     = selectedTags
            , selectedKind     = Nothing
            }
  in
    ( model
    , Cmd.batch [ runQuery d.graphqlUrl d.jwtToken query FetchJobsSuccess decodeJobs ]
    )

-- | Using the filters in the provided model, return a new one that contains
-- the jobs, but filtered.
filtered : Model -> Model
filtered m =
  let
      kindFilter job text =
        if job.academic
          then if text == "Academic" then True else False
          else if text == "Industry" then True else False

      filters = [ \job -> Maybe.map 
                            (\t -> String.contains (String.toLower t) <| String.toLower job.jobTitle) 
                            m.jobTitleFilter
                , \job -> Maybe.map (\t -> t == job.organisationName) m.selectedCompany
                , \job -> Maybe.map (\t -> t == job.location)         m.selectedLocation
                , \job -> Maybe.map (kindFilter job)                  m.selectedKind
                , \job -> 
                    Just 
                      <| (\l ->List.any identity l || List.length l == 0)
                      <| List.map (\t -> List.member t job.tags) 
                      <| Set.toList m.selectedTags
                ]

      mfilter f xs = List.filter (Maybe.withDefault True << f) xs
      jobs_        = List.foldl mfilter m.allJobs filters
  in
      { m | visibleJobs = jobs_ }

type Msg
    = NoOp
    | FetchJobsSuccess (Result Http.Error JobData)
    | FilterByJobTitle String
    | FilterByCompany  String
    | FilterByLocation String
    | FilterByKind     String
    | ToggleTag        String
    | ResetFilters

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
      NoOp -> ( model, Cmd.none )

      -- | Get the jobs and show them.
      FetchJobsSuccess r ->
        let
            newModel = case r of
              Ok jd -> 
                let jobs      = List.map .job jd.data.jobPostings
                    companies = unique <| List.map .organisationName jobs
                    locations = unique <| List.map .location jobs
                    allTags   = unique << List.concat <| List.map .tags jobs
                 in { model | allJobs      = jobs
                            , allCompanies = companies
                            , allLocations = locations
                            , allTags      = allTags
                            , visibleJobs  = jobs
                    }
              Err e -> model
        in
          ( filtered newModel, Cmd.none )

      ResetFilters ->
        let
            newModel = { model | selectedTags     = Set.empty
                               , selectedKind     = Nothing
                               , selectedLocation = Nothing
                               , selectedCompany  = Nothing
                               , jobTitleFilter   = Nothing
                               }
        in
            ( filtered newModel, Cmd.none )

      FilterByJobTitle t -> 
        let
            mt = if t == "all" then Nothing else Just t
            newModel = filtered { model | jobTitleFilter = mt }
        in
            ( newModel, Cmd.none )

      FilterByCompany c -> 
        let
            mc = if c == "all" then Nothing else Just c
            newModel = filtered { model | selectedCompany = mc }
        in
            ( newModel, Cmd.none )

      FilterByKind k -> 
        let
            mk = if k == "all" then Nothing else Just k
            newModel = filtered { model | selectedKind = mk }
        in
            ( newModel, Cmd.none )

      FilterByLocation l -> 
        let
            ml = if l == "all" then Nothing else Just l
            newModel = filtered { model | selectedLocation = ml }
        in
            ( newModel, Cmd.none )

      ToggleTag t ->
        let
            newTags = if   Set.member t model.selectedTags
                      then Set.remove t model.selectedTags
                      else Set.insert t model.selectedTags
            newModel = filtered { model | selectedTags = newTags }
        in ( newModel, Cmd.none )

view : Model -> Html Msg
view model = 
    div [ class "job-list" ]
        [ h2 [ ] [ text "Filter jobs" ]
        , div [ class "filters" ]
              -- Job Title contains ...
              [ div [ class "filter" ]
                    [ label [ for "title" ] [ text "Job title" ] 
                    , input [ type_ "text"
                            , id "title"
                            , placeholder "Ex. 'research' or 'testing'"
                            , class "date"
                            , onInput FilterByJobTitle
                            , value (Maybe.withDefault "" model.jobTitleFilter)
                            ] []
                    ]
              , div [ class "filter" ]
                    [ label [ for "org" ] [ text "Organisation" ]
                    , dropdownFilter model.selectedCompany FilterByCompany "org" model.allCompanies
                    ]
              , div [ class "filter" ]
                    [ label [ for "loc" ] [ text "Location" ]
                    , dropdownFilter model.selectedLocation FilterByLocation "loc" model.allLocations
                    ]
              , div [ class "filter" ]
                    [ label [ for "kind" ] [ text "Academic or Industry" ]
                    , dropdownFilter model.selectedKind FilterByKind "kind" model.allKinds
                    ]
              , div [ class "filter" ]
                    [ label [] [ text "Tagged"
                               , small [] [ text " (or)" ]
                               ]
                    , tagFilter model
                    ]
              ]
        , div [ class "reset" ]
              [ button [ class "reset", onClick ResetFilters ] [ text "Reset" ]
              ]
        , h2 [ class "results" ] [ text "Results" ]
        , renderJobs model.visibleJobs
        ]

tagFilter : Model -> Html Msg
tagFilter model =
  let
      class_ t = if Set.member t model.selectedTags
                   then "tag selected"
                   else "tag"
      renderTag t = span [ class (class_ t) ]
                         [ a [ href "#", onClick (ToggleTag t) ] [ text t ]
                         ]
  in
      div [ class "tag-filter" ]
        <| List.intersperse (text " ")
        <| List.map renderTag model.allTags

dropdownFilter : Maybe String -> (String -> Msg) -> String -> List String -> Html Msg
dropdownFilter presentValue msg name_ items =
  let
      mkOption item = 
        if presentValue == Just item
        then option [ value item, selected True ] [ text item ]
        else option [ value item ] [ text item ]
      all = option [ value "all", name name_ ] [ text "~ All ~"]
  in select [ onInput msg ] <| all :: List.map mkOption items

jobSep = hr [] []

renderJobs : List JobItem -> Html Msg
renderJobs jobs = 
  div [ class "jobs-list" ] 
    <| List.map renderJob jobs

