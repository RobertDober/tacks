module Decoders where

import Json.Decode as Json exposing (..)
import Dict

import Models exposing (..)


liveStatusDecoder : Decoder LiveStatus
liveStatusDecoder =
  object2 LiveStatus
    ("liveTracks" := list liveTrackDecoder)
    ("onlinePlayers" := list playerDecoder)

liveTrackDecoder : Decoder LiveTrack
liveTrackDecoder =
  object4 LiveTrack
    ("track" := trackDecoder)
    ("players" := list playerDecoder)
    ("races" := list raceDecoder)
    ("rankings" := list rankingDecoder)

raceDecoder : Decoder Race
raceDecoder =
  object5 Race
    ("_id" := string)
    ("trackId" := string)
    ("startTime" := float)
    ("players" := list playerDecoder)
    ("tallies" := list playerTallyDecoder)

rankingDecoder : Decoder Ranking
rankingDecoder =
  object3 Ranking
    ("rank" := int)
    ("player" := playerDecoder)
    ("finishTime" := float)

playerTallyDecoder : Decoder PlayerTally
playerTallyDecoder =
  object3 PlayerTally
    ("player" := playerDecoder)
    ("gates" := list float)
    ("finished" := bool)

trackDecoder : Decoder Track
trackDecoder =
  object5 Track
    ("_id" := string)
    ("name" := string)
    ("draft" := bool)
    ("creatorId" := string)
    ("course" := courseDecoder)

playerDecoder : Decoder Player
playerDecoder =
  object7 Player
    ("id" := string)
    (maybe ("handle" := string))
    (maybe ("status" := string))
    (maybe ("avatarId" := string))
    ("vmgMagnet" := int)
    ("guest" := bool)
    ("user" := bool)

messageDecoder : Decoder Message
messageDecoder =
  object3 Message
    ("content" := string)
    ("player" := playerDecoder)
    ("time" := float)


-- opponentDecoder : Decoder Opponent
-- opponentDecoder =
--   object2 Opponent
--     ("player" := playerDecoder)
--     ("state" := opponentStateDecoder)

-- opponentStateDecoder : Decoder OpponentState
-- opponentStateDecoder =
--   object8 OpponentState
--     ("time" := float)
--     ("position" := pointDecoder)
--     ("heading" := float)
--     ("velocity" := float)
--     ("windAngle" := float)
--     ("windOrigin" := float)
--     ("shadowDirection" := float)
--     ("crossedGates" := list float)

pointDecoder : Decoder Point
pointDecoder =
  tuple2 (,) float float

courseDecoder : Decoder Course
courseDecoder =
  object7 Course
    ("upwind" := gateDecoder)
    ("downwind" := gateDecoder)
    ("grid" := gridDecoder)
    ("laps" := int)
    ("area" := raceAreaDecoder)
    ("windGenerator" := windGeneratorDecoder)
    ("gustGenerator" := gustGeneratorDecoder)

gateDecoder : Decoder Gate
gateDecoder =
  object2 Gate
    ("y" := float)
    ("width" := float)


gridDecoder : Decoder Grid
gridDecoder =
  list (tuple2 (,) int gridRowDecoder)
    |> map Dict.fromList

gridRowDecoder : Decoder GridRow
gridRowDecoder =
  list (tuple2 (,) int (string `andThen` tileKindDecoder))
    |> map Dict.fromList

tileKindDecoder : String -> Decoder TileKind
tileKindDecoder s =
  case s of
    "W" -> succeed Water
    "G" -> succeed Grass
    "R" -> succeed Rock
    _ -> fail (s ++ " is not a TileKind")

raceAreaDecoder : Decoder RaceArea
raceAreaDecoder =
  object2 RaceArea
    ("rightTop" := pointDecoder)
    ("leftBottom" := pointDecoder)

windGeneratorDecoder : Decoder WindGenerator
windGeneratorDecoder =
  object4 WindGenerator
    ("wavelength1" := int)
    ("amplitude1" := int)
    ("wavelength2" := int)
    ("amplitude2" := int)

gustGeneratorDecoder : Decoder GustGenerator
gustGeneratorDecoder =
  object2 GustGenerator
    ("interval" := int)
    ("defs" := list gustDefGenerator)

gustDefGenerator : Decoder GustDef
gustDefGenerator =
  object3 GustDef
    ("angle" := float)
    ("speed" := float)
    ("radius" := float)
