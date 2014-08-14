module Steps where

import Inputs (..)
import Game (..)
import Geo (..)
import Core (..)

{-- Part 3: Update the game ---------------------------------------------------

How does the game step from one state to another based on user input?

Task: redefine `stepGame` to use the UserInput and GameState
      you defined in parts 1 and 2. Maybe use some helper functions
      to break up the work, stepping smaller parts of the game.

------------------------------------------------------------------------------}

mouseStep : MouseInput -> GameState -> GameState
mouseStep ({drag, mouse} as mouseInput) gameState =
  let center = case drag of
    Just (x',y') -> let (x,y) = mouse in sub (floatify (x - x', y' - y)) gameState.center
    Nothing      -> gameState.center 
  in
    { gameState | center <- center }

getTackTarget : Boat -> Wind -> Bool -> Maybe Int
getTackTarget boat wind spaceKey =
  case (boat.tackTarget, spaceKey) of
    -- target en cours
    (Just target, _) -> 
      -- si direction cible atteinte, on arrête le virement
      let targetReached = case boat.controlMode of
        FixedWindAngle -> target == boat.windAngle
        FixedDirection -> target == boat.direction
      in
        if targetReached then Nothing else boat.tackTarget
    -- si touche espace pressée, on défini la cible
    (Nothing, True) -> 
      case boat.controlMode of
        FixedWindAngle -> Just -boat.windAngle
        FixedDirection -> Just (ensure360 (wind.origin - boat.windAngle))
    -- sinon, pas de cible
    (Nothing, False) -> Nothing

getTurn : Maybe Int -> Boat -> Wind -> UserArrows -> Int 
getTurn tackTarget boat wind arrows =
  case (tackTarget, boat.controlMode, arrows.x, arrows.y) of 
    -- virement en cours
    (Just target, _, _, _) -> 
      case boat.controlMode of 
        FixedDirection -> if ensure360 (boat.direction - target) > 180 then 1 else -1
        FixedWindAngle -> if target > 90 || (target < 0 && target >= -90) then -1 else 1
    -- pas de virement ni de touche flèche, donc contrôle auto
    (Nothing, FixedDirection, 0, 0) -> 0
    (Nothing, FixedWindAngle, 0, 0) -> (wind.origin + boat.windAngle) - boat.direction
    -- changement de direction via touche flèche
    (Nothing, _, x, y) -> x * 3 + y

keysStep : KeyboardInput -> GameState -> GameState
keysStep ({arrows, shift, space, aKey, dKey} as keyboardInput) ({wind, boat} as gameState) =
  let newTackTarget = 
        if arrows.x /= 0 || arrows.y /= 0 then Nothing -- annule le virement
        else getTackTarget boat wind space
      turn = getTurn newTackTarget boat wind arrows
      newDirection = ensure360 <| boat.direction + turn
      newWindAngle = angleToWind newDirection wind.origin
      newControlMode = case (aKey, dKey, boat.controlMode) of
        (True, _, FixedDirection) -> FixedWindAngle
        (_, True, FixedWindAngle) -> FixedDirection
        (_, _, _)                 -> boat.controlMode
  in 
    { gameState | boat <- { boat | direction <- newDirection,
                                   windAngle <- newWindAngle,
                                   controlMode <- newControlMode,
                                   tackTarget <- newTackTarget }}

gatePassedInX : Gate -> (Point,Point) -> Bool
gatePassedInX gate ((x,y),(x',y')) =
  let a = (y - y') / (x - x')
      b = y - a * x
      xGate = (gate.y - b) / a
  in
    (abs xGate) <= gate.width / 2

gatePassedFromNorth : Gate -> (Point,Point) -> Bool
gatePassedFromNorth gate (p1,p2) =
  (snd p1) > gate.y && (snd p2) <= gate.y && (gatePassedInX gate (p1,p2))

gatePassedFromSouth : Gate -> (Point,Point) -> Bool
gatePassedFromSouth gate (p1,p2) =
  (snd p1) < gate.y && (snd p2) >= gate.y && (gatePassedInX gate (p1,p2))

getPassedGates : Boat -> Time -> Course -> (Point,Point) -> [(GateLocation,Time)]
getPassedGates boat timestamp ({upwind, downwind, laps}) step =
  case (nextGate boat course.laps, isEmpty boat.passedGates) of
    -- ligne de départ
    (_, True)          -> if | gatePassedFromSouth downwind step -> (Downwind, timestamp) :: boat.passedGates 
                             | otherwise                         -> boat.passedGates
    -- bouée au vent
    (Just Upwind, _)   -> if | gatePassedFromSouth upwind step   -> (Upwind, timestamp) :: boat.passedGates 
                             | gatePassedFromSouth downwind step -> tail boat.passedGates
                             | otherwise                         -> boat.passedGates
    -- bouée sous le vent
    (Just Downwind, _) -> if | gatePassedFromNorth downwind step -> (Downwind, timestamp) :: boat.passedGates 
                             | gatePassedFromNorth upwind step   -> tail boat.passedGates 
                             | otherwise                         -> boat.passedGates
    -- arrivée déjà franchie
    (Nothing, _)       -> boat.passedGates

getGatesMarks : Course -> [Point]
getGatesMarks course =
  [
    (course.upwind.width / -2, course.upwind.y),
    (course.upwind.width / 2, course.upwind.y),
    (course.downwind.width / -2, course.downwind.y),
    (course.downwind.width / 2, course.downwind.y)
  ]

isStuck : Point -> GameState -> Bool
isStuck p gameState =
  let gatesMarks = getGatesMarks gameState.course
      stuckOnMark = any (\m -> distance m p <= gameState.course.markRadius) gatesMarks
      outOfBounds = not (inBox p gameState.bounds)
  in 
    outOfBounds || stuckOnMark

getCenterAfterMove : Point -> Point -> Point -> (Float,Float) -> (Point)
getCenterAfterMove (x,y) (x',y') (cx,cy) (w,h) =
  let refocus n n' cn dn = 
        let margin = 30
            min = cn - (dn / 2) + margin
            max = cn + (dn / 2) - margin
        in
          if | n < min || n > max -> cn
             | n' < min           -> cn - (n - n')
             | n' > max           -> cn + (n' - n)
             | otherwise          -> cn
  in
    (refocus x x' cx w, refocus y y' cy h)

moveStep : GameClock -> (Int,Int) -> GameState -> GameState
moveStep (timestamp, delta) dimensions ({wind, boat} as gameState) =
  let {position, direction, velocity, windAngle, passedGates} = boat
      newVelocity = boatVelocity boat.windAngle velocity
      nextPosition = movePoint position delta newVelocity direction
      stuck = isStuck nextPosition gameState
      newPosition = if stuck then position else nextPosition
      newPassedGates = getPassedGates boat timestamp gameState.course (position, newPosition)
      newCenter = getCenterAfterMove position newPosition gameState.center (floatify dimensions)
      newBoat = { boat | position <- newPosition,
                         velocity <- if stuck then 0 else newVelocity,
                         passedGates <- newPassedGates }
  in { gameState | boat <- newBoat, center <- newCenter }

windStep : GameClock -> GameState -> GameState
windStep (timestamp, _) ({wind, boat} as gameState) =
  let o1 = cos (inSeconds timestamp / 10) * 15
      o2 = cos (inSeconds timestamp / 5) * 5
      newOrigin = round (o1 + o2)
      newWind = { wind | origin <- newOrigin }
  in { gameState | wind <- newWind }

stepGame : Input -> GameState -> GameState
stepGame input gameState =
  mouseStep input.mouseInput <| keysStep input.keyboardInput 
                             <| moveStep input.clock input.windowInput 
                             <| windStep input.clock gameState