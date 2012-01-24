import XMonad
import XMonad.Actions.CycleWS -- For cycling workspaces
import XMonad.Config.Gnome -- For gnomeConfig
import XMonad.Hooks.ManageHelpers -- For isFullscreen, doFullFloat
import XMonad.Layout.NoBorders -- For smartBorders
import XMonad.Util.EZConfig(additionalKeys) -- For configuring keybindings

-- Needed for fullscreenEventHook implementation
import Data.List
import Data.Maybe
import Data.Monoid (All (All), mappend)
import Monad
import qualified XMonad.StackSet as W
import XMonad.Util.WindowProperties (getProp32)
import XMonad.Util.XUtils (fi)


-- http://www.haskell.org/haskellwiki/Xmonad
-- sudo aptitude install xmonad
-- gconftool-2 -s /desktop/gnome/session/required_components/windowmanager xmonad --type string
-- gsettings set org.gnome.desktop.session session-name xmonad
-- ^j ^k: move through windows
-- ^J ^K: move window
-- ^h ^l: resize major
-- ^, ^.: increase/decrease count

myManageHook = composeAll
	-- Make Xmessage dialogs float
	[(className =? "Xmessage") --> doFloat
	-- Make the firefox option dialog float
	,(className =? "Firefox" <&&> resource =? "Browser") --> doFloat
	-- Make the chrome option dialog float
	-- http://www.haskell.org/haskellwiki/Xmonad/Frequently_asked_questions#I_need_to_find_the_class_title_or_some_other_X_property_of_my_program
	,(className =? "Google-chrome" <&&> title =? "Google Chrome Options") --> doFloat
	,(className =? "Google-chrome" <&&> title =? "- chat -") --> doFloat
	-- Support for fullscreen
	,(isFullscreen)  --> doFullFloat
	,(isDialog) --> doCenterFloat
	]

-- http://code.google.com/p/xmonad/issues/detail?id=339
fullscreenEventHook :: Event -> X All
fullscreenEventHook (ClientMessageEvent _ _ _ dpy win typ (action:dats)) = do
  state <- getAtom "_NET_WM_STATE"
  fullsc <- getAtom "_NET_WM_STATE_FULLSCREEN"
  wstate <- fromMaybe [] `fmap` getProp32 state win

  let isFull = fromIntegral fullsc `elem` wstate

      -- Constants for the _NET_WM_STATE protocol:
      remove = 0
      add = 1
      toggle = 2
      ptype = 4 -- The atom property type for changeProperty
      chWstate f = io $ changeProperty32 dpy win state ptype propModeReplace (f wstate)

  when (typ == state && fi fullsc `elem` dats) $ do
    when (action == add || (action == toggle && not isFull)) $ do
      chWstate (fi fullsc:)
      windows $ W.float win $ W.RationalRect 0 0 1 1
    when (action == remove || (action == toggle && isFull)) $ do
      chWstate $ delete (fi fullsc)
      windows $ W.sink win

  return $ All True

fullscreenEventHook _ = return $ All True

fetchOtp = spawn $ "/usr/bin/fetchotp -x"
fetchPersonalOtp = spawn $ "/usr/bin/fetchotp -x --account='srabbelier@gmail.com'"


main = xmonad $ gnomeConfig {
         modMask = mod4Mask
	-- Hook in with Gnome
	, manageHook = myManageHook <+> manageHook gnomeConfig
	-- Support fullscreen for Totem
	, handleEventHook = fullscreenEventHook `mappend` handleEventHook gnomeConfig
	, workspaces = ["one", "two", "three", "four"]
	-- Turn on smartBoarders (e.g., no borders for fullscreen),
	-- while still using gnomeConfig
	-- http://www.haskell.org/haskellwiki/Xmonad/Frequently_asked_questions#Watch_fullscreen_flash_video
	, layoutHook = smartBorders(layoutHook gnomeConfig)
	-- Don't move focus unless you click
	, focusFollowsMouse = False
	-- Make border more obvious
	, borderWidth = 2
	} `additionalKeys`
	-- Bind 'scrot' to printscreen
	[ ((0,                      xK_Print),  spawn "scrot")
	-- Rebind mod-shift-q to logout
	, ((mod4Mask .|. shiftMask, xK_q),      spawn "gnome-session-save --gui --logout-dialog")
	-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-CycleWS.html
	, ((mod4Mask,               xK_Right),  nextWS)
	, ((mod4Mask,               xK_Left),   prevWS)
	, ((mod4Mask .|. shiftMask, xK_Right),  shiftToNext >> nextWS)
	, ((mod4Mask .|. shiftMask, xK_Left),   shiftToPrev >> prevWS)
	-- Toggle between last workspace
	, ((mod4Mask,               xK_z),     toggleWS)
	, ((mod4Mask, xK_o), fetchOtp)
	, ((mod4Mask, xK_p), fetchPersonalOtp)
	]
