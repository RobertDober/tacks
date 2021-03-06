module Game.Models where

import Models exposing (..)
import Game.Core as Core

import Maybe as M
import Time exposing (..)
import List exposing (..)
import Dict exposing (Dict)


markRadius : Float
markRadius = 5

boatWidth : Float
boatWidth = 3

windShadowLength : Float
windShadowLength = 120

windHistorySampling : Float
windHistorySampling = 2000

windHistoryLength : Float
windHistoryLength = windHistorySampling * 30

type alias GameState =
  { wind:        Wind
  , windHistory: WindHistory
  , gusts:       TiledGusts
  , playerState: PlayerState
  , wake:        List Point
  , center:      Point
  , opponents:   List Opponent
  , ghosts:      List GhostState
  , course:      Course
  , tallies:     List PlayerTally
  , timers:      Timers
  , live:        Bool
  , chatting:    Bool
  }


type alias Timers =
  { now : Time
  , serverNow : Maybe Time
  , rtd : Maybe Time
  , countdown : Float
  , startTime : Maybe Time
  , localTime : Time
  }

-- Wind

type alias Wind =
  { origin : Float
  , speed : Float
  , gusts : List Gust
  , gustCounter : Int
  }

type alias WindHistory =
  { samples : List WindSample
  , lastSample : Time
  , init : Time
  }

type alias WindSample =
  { origin : Float
  , speed : Float
  , time : Time
  }

type alias Gust =
  { position : Point
  , angle : Float
  , speed : Float
  , radius : Float
  , maxRadius : Float
  , spawnedAt : Float
  }

type alias TiledGusts =
  { genTime : Time
  , gusts : List TiledGust
  }

type alias TiledGust =
  { position : Point
  , radius : Float
  , tiles : Dict Coords GustTile
  }

type alias GustTile =
  { angle : Float
  , speed : Float
  }


-- Player

type alias PlayerState =
  { player:          Player
  , time:            Float
  , position:        Point
  , isGrounded:      Bool
  , isTurning:       Bool
  , heading:         Float
  , velocity:        Float
  , vmgValue:        Float
  , windAngle:       Float
  , windOrigin:      Float
  , windSpeed:       Float
  , downwindVmg:     Vmg
  , upwindVmg:       Vmg
  , shadowDirection: Float
  , trail:           List Point
  , controlMode:     ControlMode
  , tackTarget:      Maybe Float
  , crossedGates:    List Time
  , nextGate:        Maybe GateLocation
  }

type ControlMode = FixedAngle | FixedHeading

type alias Vmg =
  { angle: Float
  , speed: Float
  , value: Float
  }

type alias Opponent =
  { player: Player
  , state: OpponentState
  }

type alias OpponentState =
  { time: Float
  , position: Point
  , heading: Float
  , velocity: Float
  , windAngle: Float
  , windOrigin: Float
  , shadowDirection: Float
  , crossedGates: List Time
  }


type alias GhostState =
  { position: Point
  , heading:  Float
  , id:       String
  , handle:   Maybe String
  , gates:    List Time
  }

-- type GateLocation = Upwind | Downwind

areaBox : RaceArea -> (Point,Point)
areaBox {rightTop,leftBottom} =
  (rightTop, leftBottom)

areaDims : RaceArea -> (Float,Float)
areaDims {rightTop,leftBottom} =
  let
    (r,t) = rightTop
    (l,b) = leftBottom
  in
    (r - l, t - b)

areaTop : RaceArea -> Float
areaTop {rightTop} = snd rightTop

areaBottom : RaceArea -> Float
areaBottom {leftBottom} = snd leftBottom

areaWidth : RaceArea -> Float
areaWidth = areaDims >> fst

areaHeight : RaceArea -> Float
areaHeight = areaDims >> snd

areaCenters : RaceArea -> (Float,Float)
areaCenters {rightTop,leftBottom} =
  let
    (r,t) = rightTop
    (l,b) = leftBottom
    cx = (r + l) / 2
    cy = (t + b) / 2
  in
    (cx, cy)

genX : Float -> Float -> RaceArea -> Float
genX seed margin area =
  let
    effectiveWidth = (areaWidth area) - margin * 2
    (cx,_) = areaCenters area
  in
    (Core.floatMod seed effectiveWidth) - effectiveWidth / 2 + cx

upwind s = abs s.windAngle < 90
closestVmgAngle s = if upwind s then s.upwindVmg.angle else s.downwindVmg.angle
windAngleOnVmg s = if s.windAngle < 0 then -(closestVmgAngle s) else closestVmgAngle s
--headingOnVmg s = ensure360 (s.windOrigin + closestVmgAngle s)
deltaToVmg s = s.windAngle - windAngleOnVmg s

asOpponentState : PlayerState -> OpponentState
asOpponentState {time,position,heading,velocity,windAngle,windOrigin,shadowDirection,crossedGates} =
  { time = time
  , position = position
  , heading = heading
  , velocity = velocity
  , windAngle = windAngle
  , windOrigin = windOrigin
  , shadowDirection = shadowDirection
  , crossedGates = crossedGates
  }

defaultVmg : Vmg
defaultVmg = { angle = 0, speed = 0, value = 0}

defaultPlayerState : Player -> Float -> PlayerState
defaultPlayerState player now =
  { player          = player
  , time            = now
  , position        = (0,0)
  , isGrounded      = False
  , isTurning       = False
  , heading         = 0
  , velocity        = 0
  , vmgValue        = 0
  , windAngle       = 0
  , windOrigin      = 0
  , windSpeed       = 0
  , downwindVmg     = defaultVmg
  , upwindVmg       = defaultVmg
  , shadowDirection = 0
  , trail           = []
  , controlMode     = FixedHeading
  , tackTarget      = Nothing
  , crossedGates    = []
  , nextGate        = Just StartLine
  }

defaultGate : Gate
defaultGate = { y = 0, width = 0 }

defaultWind : Wind
defaultWind =
  { origin = 0
  , speed  = 0
  , gusts  = []
  , gustCounter = 0
  }

emptyWindHistory : Time -> WindHistory
emptyWindHistory now =
  { samples = []
  , lastSample = 0
  , init = now
  }


defaultGame : Time -> Course -> Player -> GameState
defaultGame now course player =
  { wind        = defaultWind
  , windHistory = emptyWindHistory now
  , gusts       = TiledGusts now []
  , playerState = defaultPlayerState player now
  , center      = (0,0)
  , wake        = []
  , opponents   = []
  , ghosts      = []
  , course      = course
  , tallies = []
  , timers =
    { now         = now
    , serverNow   = Nothing
    , rtd         = Nothing
    , countdown   = 0
    , startTime   = Nothing
    , localTime   = now
    }
  , live        = False
  , chatting    = False
  }

getGateMarks : Gate -> (Point,Point)
getGateMarks gate = ((-gate.width / 2, gate.y), (gate.width / 2, gate.y))

findPlayerGhost : String -> List GhostState -> Maybe GhostState
findPlayerGhost playerId ghosts =
  Core.find (\g -> g.id == playerId) ghosts

findOpponent : List PlayerState -> String -> Maybe PlayerState
findOpponent opponents id =
  Core.find (\ps -> ps.player.id == id) opponents

raceTime : GameState -> Float
raceTime {timers} =
  case timers.startTime of
    Just t -> timers.now - t
    Nothing -> 0

isStarted : GameState -> Bool
isStarted {timers} =
  case timers.startTime of
    Just t ->
      timers.now >= t
    Nothing ->
      False
