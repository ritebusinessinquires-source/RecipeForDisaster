-- Recipe for Disaster: server entry point. All start-up logic lives in Bootstrap so it can be
-- tested. Everything that decides or runs a dish lives on the server; clients only show cards,
-- the reveal and the HUD.

require(script.Parent:WaitForChild("Bootstrap")).start()
