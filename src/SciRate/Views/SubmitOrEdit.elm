port module SciRate.Views.SubmitOrEdit exposing (..)

import Browser
import Date                  exposing (Date, day, month, weekday, year)
import DatePicker            exposing (DatePicker, DateEvent(..), defaultSettings)
import Html                  exposing ( Html, a, button, div, h2, h3
                                      , input, label , li, p, span, text, ul
                                      , node, small, hr
                                      )
import Html.Attributes       exposing ( checked, class, disabled, for
                                      , href, id, placeholder, title, type_, value
                                      , name
                                      )
import Html.Events           exposing (onInput, onClick)
import Json.Encode           as Encode
import Url                   exposing (Url)
import Dict                  exposing (Dict)
import Http                  
import Json.Decode           as Decode exposing (Decoder, bool, string, list)
import Json.Decode.Pipeline  exposing (required)
import Json.Encode           as Encode exposing (object)
import SciRate.Data          exposing (Job, decodeOneJob, decodeAffectedRows
                                     , decodeJobId, InitData, emptyJob
                                     )
import SciRate.Misc          exposing (queryStringItems)
import SciRate.Querying      exposing (runQuery)
import SciRate.Views.Sidebar exposing (renderJob, fromJob)


port openPaymentForm  : (String, Int) -> Cmd msg
port academicComplete : (String, Int) -> Cmd msg


mapDefault : b -> (a -> b) -> Maybe a -> b
mapDefault a f m
  =  Maybe.map f m
  |> Maybe.withDefault a 


main : Program InitData Model Msg
main =
    Browser.element
        { view          = view
        , init          = init
        , update        = update
        , subscriptions = \_ -> Sub.none
        }


-- | Returns a job.
getQuery : String -> String
getQuery token = """
query {
  jobs(where: {token: {_eq: \"""" ++ token ++ """\"}}) {
    academic
    closingDate
    contactEmail
    contactName
    created
    jobTitle
    jobUrl
    location
    organisationName
    organisationUrl
    remote
    tags
    withdrawn
    approved
  }
}
"""

-- | Adds a job.
insertQuery : Job -> String
insertQuery j = """
mutation {
  insert_jobs(
    objects:
      { organisationName: \"""" ++ j.organisationName    ++ """\"
      , organisationUrl:  \"""" ++ j.organisationUrl     ++ """\"
      , jobTitle:         \"""" ++ j.jobTitle            ++ """\"
      , jobUrl:           \"""" ++ j.jobUrl              ++ """\"
      , remote:             """ ++ (fromBool j.remote)   ++ """
      , academic:           """ ++ (fromBool j.academic) ++ """
      , contactName:      \"""" ++ j.contactName         ++ """\"
      , contactEmail:     \"""" ++ j.contactEmail        ++ """\"
      , location:         \"""" ++ j.location            ++ """\"
      , tags:             \"""" ++ j.tags                ++ """\"
      , closingDate:      \"""" ++ j.closingDate         ++ """\"
      , withdrawn: false
      , approved:  false
      }
  ) {
    returning { id }
  }
}
"""

-- | Updates an existing job.
updateQuery : String -> Job -> String
updateQuery token j = """
mutation {
  update_jobs(
    where: {token: {_eq: \"""" ++ token ++ """\"}},
    _set:
      { organisationName: \"""" ++ j.organisationName     ++ """\"
      , organisationUrl:  \"""" ++ j.organisationUrl      ++ """\"
      , jobTitle:         \"""" ++ j.jobTitle             ++ """\"
      , jobUrl:           \"""" ++ j.jobUrl               ++ """\"
      , remote:             """ ++ (fromBool j.remote)    ++ """
      , contactName:      \"""" ++ j.contactName          ++ """\"
      , location:         \"""" ++ j.location             ++ """\"
      , tags:             \"""" ++ j.tags                 ++ """\"
      , closingDate:      \"""" ++ j.closingDate          ++ """\"
      , withdrawn:          """ ++ (fromBool j.withdrawn) ++ """
      , approved:           """ ++ (fromBool j.approved)  ++ """
      }) {
    affected_rows
  }
}
"""

fromBool : Bool -> String
fromBool b = case b of
  True  -> "true"
  False -> "false"

type alias Model = 
  { job         : Job
  , note        : Maybe String
  , dirty       : Bool
  , closingDate : Maybe Date
  , datePicker  : DatePicker
  , editMode    : Bool
  , jobUuid     : Maybe String
  , initData    : InitData
  , error       : Maybe String
  }

emptyModel : InitData -> DatePicker -> Model
emptyModel id d
  = { job         = emptyJob
    , note        = Nothing
    , dirty       = False
    , closingDate = Nothing
    , datePicker  = d
    , editMode    = False
    , jobUuid     = Nothing
    , initData    = id
    , error       = Nothing
    }

init : InitData -> ( Model, Cmd Msg )
init d =
  let
    model = emptyModel d datePicker
    ( datePicker, datePickerFx ) = DatePicker.init

    jobUuid = Dict.get "i" (queryStringItems d.queryString)
    editMode = case jobUuid of
      Nothing -> False
      Just _  -> True

    baseCmds = [ Cmd.map ToDatePicker datePickerFx ]

    query = getQuery (Maybe.withDefault "" jobUuid)
    getJobByUuid = runQuery d.graphqlUrl d.jwtToken query SelectJobResponse decodeOneJob

    cmds =
      if editMode 
      then getJobByUuid :: baseCmds
      else baseCmds
  in
    ( { model
        | jobUuid  = jobUuid
        , editMode = editMode
        , initData = d
      }
    , Cmd.batch cmds
    )


requiredFieldsSatisfied : Model -> Bool
requiredFieldsSatisfied m =
    List.all (not << String.isEmpty) <| List.map String.trim
        [ m.job.jobTitle
        , m.job.jobUrl
        , m.job.organisationName
        , m.job.organisationUrl
        , m.job.contactEmail
        , m.job.contactName
        , m.job.location
        , m.job.closingDate
        ]

view : Model -> Html Msg
view m =
  let
      elt = if m.job.withdrawn
            then div [] [ text "This job has been withdrawn." ]
            else div [ class "job-form" ]
                    [ jobEntryFields m
                    , jobPreview m
                    ]
  in
      elt


jobPreview : Model -> Html Msg
jobPreview m
  = div [ class "preview-content"]
        [ div [ class "preview" ]
              [ h3 [] [ text "Preview" ]
              , renderJob (fromJob m.job)
              ]
        ]

jobEntryFields : Model -> Html Msg
jobEntryFields m =
  let
      maybeNote = case m.note of
        Just n  ->
          if not m.dirty 
          then [ p [ class "submit-note" ] [ text n ] ] 
          else []
        Nothing -> []

  
      maybeError = case m.error of
        Just n  -> [ p [ class "submit-error" ] [ text n ] ]
        Nothing -> []

      paySection
        = [ h3 [] [ text "Payment" ]
          , paymentSection m
          ]

      editSection
        = [ h3 [] [ text "Update" ]
          , div [ class "payment-section" ]
              [ div []
                    [ button [ class "update"
                             , onClick UpdateJob
                             ]
                             [ text "Update job details" ]
                    , button [ class "withdraw"
                             , onClick WithdrawJob
                             ]
                             [ text "Withdraw Posting" ]
                    ]
              , p [ class "note" ] [ text """
              Note: All job updates will go through a moderation queue. Unless
              there is an issue (in which case you will be contacted), it will
              appear on the site promptly!
              """ ]
              ]
          ]

      finalSection
        = case m.editMode of
            True -> editSection
            _    -> paySection

      topSection
        = case m.editMode of
            True -> h2 [] [ text "Update job posting" ]
            _    -> h2 [] [ text "Post a new job" ]
  in
  div []
    [ topSection
    , div [ class "job-content" ]
        (
        [ h2 [] [ text "Details" ]
        , small [ class "req-note" ] [ text "Fields marked with a '*' are required." ]
        , h3 [] [ text "Position details" ]
        , positionDetails m
        , h3 [] [ text "Contact details" ]
        , contactDetails m
        ] ++ finalSection ++ maybeNote ++ maybeError
        )
     ]

contactDetails : Model -> Html Msg
contactDetails m
  = div [ class "job-form-fields" ]
        [ textField
            "Contact email" 
            "Your contact email. You will receive a link to edit to this address. This will not be shown to anyone."
            ""
            m.job.contactEmail
            UpdateContactEmail
        , textField
            "Contact Name" 
            "Your contact name. Used only if we need to get in touch we you."
            ""
            m.job.contactName
            UpdateContactName
        ]

positionDetails : Model -> Html Msg
positionDetails m = 
  let
      maybeAcademic =
        if not m.editMode
        then
          [ boolField 
                "Academic or Industry role?"
                "Is this an academic position?"
                "Academic"
                "Industry"
                m.job.academic
                UpdateAcademic
          ]
        else []
  in
  div []
    [ div [ class "job-form-fields" ] <|
            [ textField 
                "Organsation name" 
                "The organisation that is hiring this role." 
                "Ex. SciRate"
                m.job.organisationName
                UpdateOrganisationName
            , textField 
                "Link to organisation website" 
                "A link where people can learn more about your company."
                "Ex. https://scirate.com"
                m.job.organisationUrl
                UpdateOrganisationUrl
            , sep
            , textField 
                "Job title" 
                "The job title."
                "Ex. Senior Quantum Researcher"
                m.job.jobTitle
                UpdateJobTitle
            , textField 
                "Link to job" 
                "A link to a website with a job description and details on how to apply." 
                "Ex. https://yourwebsite.com/jobs/?jobId=..."
                m.job.jobUrl
                UpdateJobUrl
            , closingDateField m
            , sep
            , boolField 
                "Remote?"
                "Can this job be undertaken remotely?" 
                "Yes/Maybe"
                "No"
                m.job.remote
                UpdateRemote
            , textField 
                "Location" 
                """
                Primary location/time-zone where the job is based or
                'Multiple' if there are options.
                """
                "Ex. Melbourne, AU or Delft, NL or Multiple"
                m.job.location
                UpdateLocation
          ] ++
          maybeAcademic ++
          [ sep
            , textFieldR
                False
                "Tags"
                """
                Tags seperated by commas. Useful to help people filter for
                jobs using these skills/technologies.
                """
                "Ex. cirq, python, surface-code"
                m.job.tags
                UpdateTags
            ]
        ]

paymentSection : Model -> Html Msg
paymentSection m =
  let sat = requiredFieldsSatisfied m
      r = case sat of
          True  -> div [ class "payment" ] [ payButton m ]
          False -> div [ class "payment" ] [ text "Please complete all required fields." ]
  in
    div [ class "payment-section" ]
        [ r
        , p [ class "note" ] [ text """
        Note: All jobs will go through a moderation queue. Unless there is
        an issue (in which case you will be contacted), it will appear on
        the site promptly!
        """ ]
        ]

payButton : Model -> Html Msg
payButton m = 
  case m.job.academic of
    True -> 
      div [] [ p [] [ text "Academic jobs are free, presently!" ]
             , button [ class "pay"
                      , onClick SubmitAcademicJob
                      ]
                      [ text "Submit an academic job" ]
             ]
    False ->
      div [] [ button [ class "pay"
                      , onClick StartStripePayment
                      ]
                      [ text "Pay with Stripe" ]
             ]

sep : Html Msg
sep = span [] []

-- | Potential actions.
type Msg
    -- >> Model updates
    = UpdateContactEmail String
    | UpdateContactName String
    | UpdateOrganisationName String
    | UpdateOrganisationUrl String
    | UpdateJobTitle String
    | UpdateJobUrl String
    | UpdateLocation String
    | UpdateTags String
    | UpdateAcademic Bool
    | UpdateRemote Bool
    | StartStripePayment
    | SubmitAcademicJob
    --
    | UpdateJob
    | InsertJobResponse String (Result Http.Error (Maybe Int))
    | UpdateJobResponse String (Result Http.Error Int)
    | SelectJobResponse        (Result Http.Error (Maybe Job))
    | WithdrawJob
    --
    | ToDatePicker DatePicker.Msg

dateSettings : DatePicker.Settings
dateSettings =
  { defaultSettings
    | inputId = Just "date-field"
    , inputName = Just "date"
    , inputClassList = [ ("form-control", True) ]
  }

-- | Main model update.
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model
  = let
      noop = ( model, Cmd.none )
    in case msg of
      ToDatePicker m ->
        let
            ( newDatePicker, event )
              = DatePicker.update dateSettings m model.datePicker

            newModel
              = { model
                | closingDate = case event of
                          Picked date -> Just date
                          _           -> model.closingDate
                , dirty = True
                , datePicker = newDatePicker
                }

            oldJob = model.job
            
            -- We want an error later on.
            mStrDate = newModel.closingDate |> Maybe.map (Date.format "yyyy-MM-dd")
            strDate  = Maybe.withDefault "" mStrDate

            newJob = { oldJob | closingDate = strDate }
        in
            ( { newModel | job = newJob }, Cmd.none )

      -- State update busywork
      UpdateContactEmail s -> 
        let oldJob = model.job
            newJob = { oldJob | contactEmail = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateContactName s -> 
        let oldJob = model.job
            newJob = { oldJob | contactName = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateOrganisationName s -> 
        let oldJob = model.job
            newJob = { oldJob | organisationName = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateOrganisationUrl s -> 
        let oldJob = model.job
            newJob = { oldJob | organisationUrl = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateJobTitle s ->
        let oldJob = model.job
            newJob = { oldJob | jobTitle = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateJobUrl s ->
        let oldJob = model.job
            newJob = { oldJob | jobUrl = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateLocation s ->
        let oldJob = model.job
            newJob = { oldJob | location = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateTags s ->
        let oldJob = model.job
            newJob = { oldJob | tags = s }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateAcademic b ->
        let oldJob = model.job
            newJob = { oldJob | academic = b }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      UpdateRemote b ->
        let oldJob = model.job
            newJob = { oldJob | remote = b }
        in ( { model | job = newJob, dirty = True }, Cmd.none )

      -- Job things
      StartStripePayment ->
          ( model , runQuery model.initData.graphqlUrl model.initData.jwtToken (insertQuery model.job) (InsertJobResponse "Opening stripe ...") decodeJobId )

      SubmitAcademicJob ->
          ( model , runQuery model.initData.graphqlUrl model.initData.jwtToken (insertQuery model.job) (InsertJobResponse "Job submitted!") decodeJobId )

      WithdrawJob ->
        let
            oldJob   = model.job
            newJob   = { oldJob | withdrawn = True }
            query t  = updateQuery t newJob
            f token  = runQuery model.initData.graphqlUrl model.initData.jwtToken (query token) (UpdateJobResponse "Job withdrawn.") decodeAffectedRows
            cmd      = mapDefault Cmd.none f model.jobUuid
        in
          ( model, cmd )

      UpdateJob ->
        let
            oldJob   = model.job
            newJob   = { oldJob | approved = False }
            query t  = updateQuery t newJob
            f token  = runQuery model.initData.graphqlUrl model.initData.jwtToken (query token) (UpdateJobResponse "Job updated!") decodeAffectedRows
            cmd      = mapDefault Cmd.none f model.jobUuid
        in
          ( model, cmd )

      UpdateJobResponse s response ->
        let
            newModel
              = case response of
                  Ok _ -> { model | note = Just s, dirty = False }
                  _    -> { model | error = Just "Unable to update job." }
        in
            ( newModel, Cmd.none )

      InsertJobResponse s response ->
        let
            newCmd = 
              case response of
                -- We only open payment if it's an industry job.
                Ok (Just jobId) -> if model.job.academic 
                                  then academicComplete (model.job.contactEmail, jobId)
                                  else openPaymentForm  (model.job.contactEmail, jobId)
                _               -> Cmd.none
            
            newModel =
              case response of
                Ok (Just _) -> { model | note = Just s, dirty = False }
                _           -> { model | error = Just "Unable to submit job." }
        in
            ( newModel, newCmd )

      SelectJobResponse response ->
        let
            newModel = 
              case response of
                Ok (Just j) -> { model | job = j
                                      , closingDate = stringToDate j.closingDate
                               }
                _           -> model
        in
            ( newModel, Cmd.none )

stringToDate : String -> Maybe Date
stringToDate s =
  String.split "T" s
    |> List.head
    |> Maybe.andThen (Result.toMaybe << Date.fromIsoString)

closingDateField : Model -> Html Msg
closingDateField model
  = let
      name_ = "closing-date"
      txt = "Job closing date*"
    in
      div [ class "field" ]
        [ label [ for name_ ] [ text txt ]
        , div [ class "field-input" ]
              [ DatePicker.view model.closingDate dateSettings model.datePicker
                  |> Html.map ToDatePicker
              , div [ class "help" ]
                  [
                  p [] [ text "Closing date in yyyy-MM-dd "
                       , a [ href "https://time.is/Anywhere_on_Earth" ] [ text "anywhere on earth" ]
                       , text ". The furthest this can be is 3 months into the future."
                       ]
                  ]
              ]
        ]

textField = textFieldR True

-- | Make a text input field.
textFieldR : Bool            -- ^ Is it required?
          -> String          -- ^ Name of the html field
          -> String          -- ^ Help text
          -> String          -- ^ Placeholder value
          -> String          -- ^ Current field value
          -> (String -> Msg) -- ^ Command to run
          -> Html Msg
textFieldR req label_ help placeholder_ val msg
  = let
      txt   = if req then
                label_ ++ "*"
              else
                label_
      name_ = label_
    in
      div [ class "field" ]
        [ label [ for name_ ] [ text txt ]
        , div [ class "field-input" ]
              [ input [ type_ "text"
                      , id name_
                      , placeholder placeholder_
                      , onInput msg
                      , value val 
                      ] []
              , div [ class "help" ] [ p [] [ text help ] ]
              ]
        ]

-- | Make a boolean field with radio buttons.
boolField :  String         -- ^ Name of the html field
          -> String         -- ^ Help text
          -> String         -- ^ Label for 'true' radio button
          -> String         -- ^ Label for 'false' radio button
          -> Bool           -- ^ Present value
          -> (Bool -> Msg)  -- ^ Command to run
          -> Html Msg
boolField label_ help labelTrue labelFalse val msg
  = let
      mkRadio txt v =
        [ input [ type_ "radio"
                , name label_
                , id <| label_ ++ v
                , value v
                , onInput (msg << ((==) "yes"))
                , checked ((v == "yes" && val) || (v == "no" && not val))
                ] []
        , label [ for (label_ ++ v), class "radio" ] [ text txt ]
        ]
    in
      div [ class "field" ]
        [ label [] [ text label_ ]
        , div [ class "field-input" ]
              <| mkRadio labelTrue  "yes"
              ++ mkRadio labelFalse "no"
              ++ [ div [ class "help" ] [ p [] [ text help ] ] ]
        ]
