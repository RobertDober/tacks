module Game where

import Geo (..)
import Json
import Dict

type Gate = { y: Float, width: Float }
type Island = { location : Point, radius : Float }
type Course =
  { upwind: Gate
  , downwind: Gate
  , laps: Int
  , markRadius: Float
  , islands: [Island]
  , bounds: (Point, Point)
  , windShadowLength: Float
  , boatWidth: Float
  }

type Boat a =
  { a | position : Point
      , heading: Float
      , velocity: Float
      , windAngle: Float
      , windOrigin: Float
      , windSpeed: Float }

type Spell = { kind : String }

containsSpell : String -> [Spell] -> Bool
containsSpell spellName spells =
  let filtredSpells = filter (\spell -> spell.kind == spellName) spells
  in  length filtredSpells > 0

type Buoy = { position : Point, radius : Float, spell : Spell }

type Opponent = Boat { user : { name : String } }

type Player = Boat
  { downwindVmg: Float
  , upwindVmg: Float
  , trail: [Point]
  , controlMode: String
  , tackTarget: Maybe Float
  , crossedGates: [Time]
  , nextGate: Maybe String -- GateLocation data type is incompatible with port inputs
  , ownSpell: Maybe Spell
  }

type Gust = { position : Point, angle: Float, speed: Float, radius: Float }
type Wind = { origin : Float, speed : Float, gusts : [Gust] }

type GameState =
  { wind: Wind
  , player: Player
  , wake: [Point]
  , center: Point
  , opponents: [Opponent]
  , buoys: [Buoy]
  , course: Course
  , leaderboard: [String]
  , now: Time
  , countdown: Maybe Time
  , triggeredSpells: [Spell]
  , isMaster: Bool
  }

type RaceState = { players : [Player] }

defaultGate : Gate
defaultGate = { y = 0, width = 0 }

defaultCourse : Course
defaultCourse =
  { upwind = defaultGate
  , downwind = defaultGate
  , laps = 0
  , markRadius = 0
  , islands = []
  , bounds = ((0,0), (0,0))
  , windShadowLength = 0
  , boatWidth = 0
  }

defaultPlayer : Player
defaultPlayer =
  { position = (0,0)
  , heading = 0
  , velocity = 0
  , windAngle = 0
  , windOrigin = 0
  , windSpeed = 0
  , trail = []
  , controlMode = "FixedHeading"
  , tackTarget = Nothing
  , crossedGates = []
  , nextGate = Nothing
  , downwindVmg = 0
  , upwindVmg = 0
  , ownSpell = Nothing
  }

defaultWind : Wind
defaultWind =
  { origin = 0
  , speed = 0
  , gusts = []
  }

defaultGame : GameState
defaultGame =
  { wind = defaultWind
  , player = defaultPlayer
  , center = (0,0)
  , wake = []
  , opponents = []
  , buoys = []
  , course = defaultCourse
  , leaderboard = []
  , now = 0
  , countdown = Nothing
  , triggeredSpells = []
  , isMaster = False
  }

getGateMarks : Gate -> (Point,Point)
getGateMarks gate = ((-gate.width / 2, gate.y), (gate.width / 2, gate.y))
