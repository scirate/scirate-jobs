module SciRate.Misc exposing (..)

-- Misc functions that are handy.

import Dict exposing (Dict)
import Url
import List

-- | A very bad querystring parsing. But we don't need to work with
-- arbitrary input.
parseQueryString : String -> Dict String String
parseQueryString s = 
  let
      ands = String.split "&" s
      eqs  = List.map (String.split "=") ands
      mkTuple two = 
        let a = List.head two
            b = List.head (List.drop 1 two)
        in (Maybe.withDefault "" a,
            Maybe.withDefault "" (Url.percentDecode (Maybe.withDefault "" b))
           )
      dict = List.map mkTuple eqs
  in
      Dict.fromList dict

-- | Given a query string; convert it into a dictionary where we can look up
-- elements.
queryStringItems : String -> Dict String String
queryStringItems url = 
  Maybe.withDefault Dict.empty
    <| (\f -> Maybe.map f (Url.fromString url))
    <| (\u -> case u.query of
        Nothing -> Dict.empty
        Just qs -> parseQueryString qs)

