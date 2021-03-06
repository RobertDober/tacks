module Screens.EditTrack.View where

import Html exposing (Html)
import Html.Attributes as HtmlAttr

import Svg exposing (..)
import Svg.Attributes exposing (..)

import AppTypes exposing (..)
import Models exposing (..)
import Constants exposing (..)

import Screens.EditTrack.Types exposing (..)
import Screens.EditTrack.Updates exposing (actions)
import Screens.EditTrack.SideView exposing (sideView)

import Screens.Utils exposing (..)

import Game.Grid as Grid
import Game.Geo exposing (floatify)
import Game.Render.SvgUtils exposing (..)

import Game.Render.Tiles as RenderTiles exposing (lazyRenderTiles, tileKindColor)
import Game.Render.Gates exposing (renderOpenGate)
import Game.Render.Players exposing (renderPlayerHull)

view : Player -> Screen -> Html
view player screen =
  case (screen.track, screen.editor) of
    (Just track, Just editor) ->
      if player.id == track.creatorId || isAdmin player then
        editorView track editor
      else
        Html.text "Access forbidden."
    _ ->
      Html.text "loading"


editorView : Track -> Editor -> Html
editorView track editor =
  Html.div [ class "content editor" ]
    [ sideView track editor
    , renderCourse editor
    ]


renderCourse : Editor -> Html
renderCourse ({courseDims, center, course, mode} as editor) =
  let
    (w, h) = floatify courseDims
    cx = w / 2 + fst center
    cy = -h / 2 + snd center
  in
    Svg.svg
      [ width (toString w)
      , height (toString h)
      , class <| "mode-" ++ (modeName (realMode editor) |> fst)
      ]
      [ g [ transform ("scale(1,-1)" ++ (translate cx cy)) ]
        [ (lazyRenderTiles course.grid)
        , renderOpenGate course.upwind 0
        , renderOpenGate course.downwind 0
        , renderPlayerHull 0 0
        ]
      ]


