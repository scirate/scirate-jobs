module SciRate.Hacks exposing (..)

import Html exposing (node, div, text)

submitCss : String
submitCss =
  """
div.job-form {
  display: flex;
  flex-direction: row;
  margin: 10px;
  align-items: center;
}

div.job-form-fields {
  margin-left: 10px;
}

div.payment {
  margin-left: 15px;
}

div.field {
  display: flex;
  flex-direction: row;
  margin: 5px;
  margin-bottom: 10px;
}

label {
  font-weight: normal;
}

div.field label {
  width: 200px;
}

div.field input[type="text"] {
  width: 300px;
}

div.field input[type="radio"] {
  display: inline;
  padding: 5px;
}

div.field label.radio {
  padding: 5px;
  margin-right: 20px;
  display: inline;
}

div.field small {
  padding: 5px;
}

div.help {
  margin-top: 5px;
  background: #eaeaea;
  font-size: 0.9em;
  padding: 5px;
  border-radius: 3px;
  max-width: 350px;
}

div.help p {
  margin: 0;
  }

div.job-content {
  display: flex;
  flex-direction: column;
}

div.preview {
  margin-left: 20px;
  }




.elm-datepicker--container {
  position: relative; }

.elm-datepicker--input:focus {
  outline: 0; }

.elm-datepicker--picker {
  position: absolute;
  border: 1px solid #CCC;
  z-index: 10;
  background-color: white; }

.elm-datepicker--picker-header,
.elm-datepicker--weekdays {
  background: #F2F2F2; }

.elm-datepicker--picker-header {
  display: flex;
  align-items: center; }

.elm-datepicker--prev-container,
.elm-datepicker--next-container {
  flex: 0 1 auto;
  cursor: pointer; }

.elm-datepicker--month-container {
  flex: 1 1 auto;
  padding: 0.5em;
  display: flex;
  flex-direction: column; }

.elm-datepicker--month,
.elm-datepicker--year {
  flex: 1 1 auto;
  cursor: default;
  text-align: center; }

.elm-datepicker--year {
  font-size: 0.6em;
  font-weight: 700; }

.elm-datepicker--prev,
.elm-datepicker--next {
  border: 6px solid transparent;
  background-color: inherit;
  display: block;
  width: 0;
  height: 0;
  padding: 0 0.2em; }

.elm-datepicker--prev {
  border-right-color: #AAA; }
  .elm-datepicker--prev:hover {
    border-right-color: #BBB; }

.elm-datepicker--next {
  border-left-color: #AAA; }
  .elm-datepicker--next:hover {
    border-left-color: #BBB; }

.elm-datepicker--table {
  border-spacing: 0;
  border-collapse: collapse;
  font-size: 0.8em; }
  .elm-datepicker--table td {
    width: 2em;
    height: 2em;
    text-align: center; }

.elm-datepicker--row {
  border-top: 1px solid #F2F2F2; }

.elm-datepicker--dow {
  border-bottom: 1px solid #CCC;
  cursor: default; }

.elm-datepicker--day {
  cursor: pointer; }
  .elm-datepicker--day:hover {
    background: #F2F2F2; }

.elm-datepicker--disabled {
  cursor: default;
  color: #DDD; }
  .elm-datepicker--disabled:hover {
    background: inherit; }

.elm-datepicker--picked {
  color: white;
  background: darkblue; }
  .elm-datepicker--picked:hover {
    background: darkblue; }

.elm-datepicker--today {
  font-weight: bold; }

.elm-datepicker--other-month {
  color: #AAA; }
  .elm-datepicker--other-month.elm-datepicker--disabled {
    color: #EEE; }
  .elm-datepicker--other-month.elm-datepicker--picked {
    color: white; }
"""


bigListCss : String
bigListCss =
  """
div.jobs-list {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
}

div.filters {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
  }

div.filter { 
  margin: 5px;
}

div.reset {
  margin: 5px;
}

div.filter label {
  padding: 4px;
}
"""


sidebarCss : String
sidebarCss =
  """
div.jobs {
  width: 300px;
  display: flex;
  flex-direction: column;
}


div.job {
  width: 300px;
  background: #eaeaea;
}

div.job .title {
  font-size: 20px;
}

div.tags {
  font-size: 13px;
  margin-top: 3px;
  margin-bottom: 3px;
  }

span.tag {
  border-radius: 5px;
  margin: 5px;
  }

span.selected {
  background: snow;
  font-weight: bold;
}
"""


wrapCss view
  = div [] [ node "style" [] [ text <| submitCss ++ sidebarCss ++ bigListCss]
           , view
           ]
