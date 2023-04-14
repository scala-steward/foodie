module Pages.Util.DateUtil exposing
    ( Timestamp
    , dateParser
    , dateToPrettyString
    , dateToString
    , fromPosix
    , now
    , timeParser
    , timeToString
    , toPrettyString
    , toString
    )

import Api.Types.Date exposing (Date)
import Api.Types.SimpleDate exposing (SimpleDate)
import Api.Types.Time exposing (Time)
import Maybe.Extra
import Parser exposing ((|.), (|=), Parser)
import Task
import Time


toString : SimpleDate -> String
toString simpleDate =
    [ simpleDate.date |> dateToString
    , simpleDate.time |> Maybe.Extra.unwrap "" timeToString
    ]
        |> String.join " "
        |> String.trim


toPrettyString : SimpleDate -> String
toPrettyString simpleDate =
    [ simpleDate.date |> dateToPrettyString
    , simpleDate.time |> Maybe.Extra.unwrap "" timeToString
    ]
        |> String.join " "
        |> String.trim


dateToString : Date -> String
dateToString date =
    [ date.year
    , date.month
    , date.day
    ]
        |> List.map padToTwo
        |> String.join "-"


dateToPrettyString : Date -> String
dateToPrettyString date =
    [ date.year
    , date.month
    , date.day
    ]
        |> List.map padToTwo
        |> String.join "."


padToTwo : Int -> String
padToTwo i =
    if i >= 0 && i <= 9 then
        String.concat [ "0", String.fromInt i ]

    else
        String.fromInt i


timeToString : Time -> String
timeToString time =
    [ time.hour, time.minute ]
        |> List.map padToTwo
        |> String.join ":"


{-| No validation, because the date is checked by the backend.
-}
dateParser : Parser Date
dateParser =
    Parser.succeed Date
        |= intWithOptionalLeadingZero
        |. Parser.symbol "-"
        |= intWithOptionalLeadingZero
        |. Parser.symbol "-"
        |= intWithOptionalLeadingZero


intWithOptionalLeadingZero : Parser Int
intWithOptionalLeadingZero =
    Parser.oneOf
        [ Parser.symbol "0" |> Parser.andThen (always Parser.int)
        , Parser.int
        ]


{-| No validation, because the time is checked by the backend.
-}
timeParser : Parser Time
timeParser =
    Parser.succeed Time
        |= intWithOptionalLeadingZero
        |. Parser.symbol ":"
        |= intWithOptionalLeadingZero


type alias Timestamp =
    { zone : Time.Zone
    , time : Time.Posix
    }


fromPosix : Timestamp -> SimpleDate
fromPosix timestamp =
    let
        zone =
            timestamp.zone

        time =
            timestamp.time
    in
    { date =
        { year = Time.toYear zone time
        , month = Time.toMonth zone time |> monthToNumber
        , day = Time.toDay zone time
        }
    , time =
        Just
            { hour = Time.toHour zone time
            , minute = Time.toMinute zone time
            }
    }


now : Task.Task x Timestamp
now =
    Task.map2 Timestamp Time.here Time.now


monthToNumber : Time.Month -> Int
monthToNumber month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12
