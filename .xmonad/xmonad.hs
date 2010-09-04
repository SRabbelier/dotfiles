import XMonad
import XMonad.Actions.CycleWS -- For cycling workspaces
import XMonad.Config.Gnome -- For gnomeConfig
import XMonad.Hooks.ManageHelpers -- For isFullscreen, doFullFloat
import XMonad.Layout.NoBorders -- For smartBorders
import XMonad.Util.EZConfig(additionalKeys)

-- http://www.haskell.org/haskellwiki/Xmonad
-- sudo aptitude install xmonad
-- gconftool-2 -s /desktop/gnome/session/required_components/windowmanager xmonad --type string
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
	]

main = xmonad $ gnomeConfig {
         modMask = mod4Mask
	-- Hook in with Gnome
	, manageHook    = myManageHook <+> manageHook gnomeConfig
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
	-- Moving through workspaces
	-- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Actions-CycleWS.html
	, ((mod4Mask,               xK_Right),  nextWS)
	, ((mod4Mask,               xK_Left),   prevWS)
	, ((mod4Mask .|. shiftMask, xK_Right),  shiftToNext >> nextWS)
	, ((mod4Mask .|. shiftMask, xK_Left),   shiftToPrev >> prevWS)
	-- Toggle between last workspace
	, ((mod4Mask,               xK_z),     toggleWS)
	]
