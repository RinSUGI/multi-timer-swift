-- Arranges the mounted DMG window for drag-to-install:
-- icon view, hidden toolbar, background picture, and app -> Applications layout.
-- Usage: osascript scripts/dmg-layout.applescript <volumeName> <appName>
-- Coordinates must match scripts/render-dmg-background.swift.
--
-- The .background folder is given an explicit icon position far below the
-- visible window area. A recorded position forces Finder to show an item even
-- when it is hidden/invisible, so instead of fighting that we place it out of
-- view (it is also flagged invisible by the build script afterwards).

on run argv
	set volName to item 1 of argv
	set appName to item 2 of argv

	tell application "Finder"
		tell disk volName
			open
			set current view of container window to icon view
			set toolbar visible of container window to false
			set statusbar visible of container window to false
			-- {left, top, right, bottom} -> 640 x 400 content window
			set the bounds of container window to {380, 120, 1020, 520}

			set opts to the icon view options of container window
			set arrangement of opts to not arranged
			set icon size of opts to 160
			set text size of opts to 13
			set background picture of opts to file ".background:background.tiff"

			set position of item appName of container window to {170, 175}
			set position of item "Applications" of container window to {470, 175}
			try
				set position of item ".background" of container window to {320, 1100}
			end try

			update without registering applications
			delay 1
			close
		end tell
	end tell
end run
