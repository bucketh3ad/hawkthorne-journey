-- check for blank spaces
local anim8 = require 'vendor/anim8'
local character = require 'character'
local controls = require('inputcontroller').get()
local fonts = require 'fonts'
local Gamestate = require 'vendor/gamestate'
local sound = require 'vendor/TEsound'
local Player = require 'player'
-- use vertical particles instead of background & character strips
-- will have to do more coding later to get background to match
-- need to add in all occurances of VerticleParticles in this code
-- copy from backup
local VerticalParticles = require "verticalparticles"
local window = require 'window'

local state = Gamestate.new()

local function nonzeroMod(a,b)
    local m = a%b
    if m==0 then
        return b
    else
        return m
    end
end

-- do I need this?
local function __NULL__() end

function state:init()

  self.select = 'characterPick'
  self.characterLevel = 1
  self.column = 1
  self.row = 1
  self.costumeCount = 1
 
-- change this later to display more costumes on a line 
  self.rowLength = 6

  self.characterText = ""
  self.costumeText = ""

end

function state:enter(previous)

  VerticalParticles.init()

  self.select = 'characterPick'

  self.selectionBox = love.graphics.newImage('images/menu/selection.png')

  self.characters = {}
  self.selections = {}

  -- worry about insufficient friends later
  self.selections[1] = 'jeff'
  self.selections[2] = 'britta'
  self.selections[3] = 'abed'
  self.selections[4] = 'annie'
  self.selections[5] = 'troy'
  self.selections[6] = 'shirley'
  self.selections[7] = 'pierce'
  self.selections[8] = 'dean'
  self.selections[9] = 'chang'

  fonts.set('big')
  self.previous = previous
  
  -- possibly include option of randomly chosing costume?
  -- that would involve more coding too
  -- I don't actually print these at the moment
  self.characterText = "PRESS " .. controls:getKey('JUMP') .. " TO CHOOSE CHARACTER"
  self.costumeText = "PRESS " .. controls:getKey('JUMP') .. " TO CHOOSE COSTUME" 

end

function state:character()
  local name = self.selections[self.characterLevel]

  if not name then
    return nil
  end

  return self:loadCharacter(name)
end

function state:loadCharacter(name)
-- could use this to save info about characters row/column # possibly
  if not self.characters[name] then
    self.characters[name] = character.load(name)
  end

  return self.characters[name]
end

function state:keypressed( button )

  -- switch to previous gamestate
  if button == "START" then
   love.event.push("quit")
    --Gamestate.switch(self.previous)
    return
  end
  
  if self.select == 'characterPick' then
    self:characterKeypressed(button)
  elseif self.select =="costumePick" then
    self:costumeKeypressed(button)
  end
  
end

function state:characterKeypressed(button)

  local level = self.characterLevel
  local options = #self.selections
  
  if button == "DOWN" then
    self.characterLevel = nonzeroMod(level + 1, options)
    sound.playSfx('click')
    
  elseif button == "UP" then 
    self.characterLevel = nonzeroMod(level - 1 , options)
    sound.playSfx('click')

  elseif button == "JUMP" then
    local c = self:character()
    if c then
    
      self.owsprite = love.graphics.newImage('images/characters/'..c.name..'/overworld.png')
      self.g = anim8.newGrid(36, 36, self.owsprite:getWidth(), self.owsprite:getHeight())
    --somewhere will need to decide what to do if I have more costumes than can fit on a page
    -- possibly need to stick this maths somewhere else
      self.costumeNumber = #c.costumes
      
      self.columnLength = math.ceil(self.costumeNumber/self.rowLength)
      self.lastRowLength = nonzeroMod(self.costumeNumber, self.rowLength)    
   
      self.costumeName = {}
      self.costumeSheet = {}
      self.costumeOw = {}
      for i = 1, self.costumeNumber do
        self.costumeName[i] = c.costumes[i].name
        self.costumeSheet[i] = c.costumes[i].sheet
        self.costumeOw[i] = c.costumes[i].ow
      end
    end
    sound.playSfx('click')
    self.select = 'costumePick'
  end
  
end

function state:costumeKeypressed(button)

  if button == "LEFT" then
    if self.row == self.columnLength then
      self.column = nonzeroMod(self.column - 1 , self.lastRowLength)
    else
      self.column = nonzeroMod(self.column - 1 , self.rowLength)
    end
    sound.playSfx('click')
	
  elseif button == "RIGHT" then
    if self.row == self.columnLength then
      self.column = nonzeroMod(self.column + 1 , self.lastRowLength)
    else
      self.column = nonzeroMod(self.column + 1 , self.rowLength)
    end
    sound.playSfx('click')
	
  elseif button == "DOWN" then
    if (self.row == self.columnLength - 1 and self.column > self.lastRowLength)  then
      self.row = 1
    else
      self.row = nonzeroMod(self.row + 1, self.columnLength)
    end
    sound.playSfx('click')
	
  elseif button == "UP" then
    if (self.row == 1 and self.column > self.lastRowLength) then
      self.row = self.columnLength - 1
	else
      self.row = nonzeroMod(self.row - 1, self.columnLength)
    end
    sound.playSfx('click')
	
  elseif button == "JUMP" then
    sound.playSfx('confirm')
    if self:character() then
    local player = Player.factory() -- expects existing player object
    local name = self.selections[self.characterLevel]
    local sheet = self.costumeSheet[self.costumeCount]
    character.pick(name, sheet)
    player.character = character.current()
  
  -- change to previous gamestate
    Gamestate.switch('studyroom', 'main')
    end
	
  elseif button == "ATTACK" then
    sound.playSfx('click')
    self.row = 1
	self.column = 1
    self.select = 'characterPick'
  end
  -- can probably move this to the JUMP loop
  self.costumeCount = (self.row - 1)*self.rowLength + self.column

end

function state:leave()

  VerticalParticles.leave()
  fonts.reset()
  
  self.select = nil
  self.selectionBox = nil
  self.characterText = nil
  self.costumeText = nil

  self.selections = {}
  self.characters = {}
  self.costumeName = {}
  self.costumeSheet = {}
  self.costumeOw = {}

  -- delete more stuff?
  love.graphics.setColor(255, 255, 255, 255)
  
end

function state:draw()
  love.graphics.setBackgroundColor(0, 0, 0, 0)
  VerticalParticles.draw()
  
  love.graphics.setColor(0, 255, 0, 255)
  

  
  if self.select == 'characterPick' then
  -- print pictures of characters
  -- print name of currently selected character up the top (maybe this should be general)
  -- display background row thingies
  -- maybe display big pick of selected character on the right?
  -- selection box around top row
  -- could do this for each side, might be easier, then also won't have giant blank space I have to fill
  -- or automatically fills RHS with overworld sprites?
  local characterNumber = #self.selections
    for i = 0, 3 do
    -- change this back to nonzeroMod
      love.graphics.print(self.selections[nonzeroMod(self.characterLevel + i, characterNumber)], 50, 100 + 50*i, 0)
	end
  elseif self.select == 'costumePick' then
    love.graphics.print('row ' .. self.row .. ' and column ' .. self.column, 50, 100 + 50, 0)
	love.graphics.setColor( 255, 255, 255, 255 )
	-- come up with a better way of doing this
	-- probably already have character somewhere
	-- don't need to do long name
	--local pick = self.column + (self.row - 1)*self.columnLength
	-- line above isn't correct. Want to get ow from ith costume
	-- will want to change this ow = position in list, not actually related to costume at this point
	
	--positions
	local x = 100
	local y = 100
	local spacingX = 40
	local spacingY = 40
	
	local i = 1
	local j = 1
	for k = 1, self.costumeNumber do
      self.overworld = anim8.newAnimation('once', self.g(self.costumeOw[k], 1), 1)
      self.overworld:draw(self.owsprite, x + spacingX*i, x + spacingY*j)
	  if i < self.rowLength then
	    i = i + 1
      else
        i = 1
		j = j + 1
	  end
    end
	love.graphics.draw(self.selectionBox, x - 2 + spacingX*self.column, y - 2 + spacingY*self.row)
    love.graphics.print(self.costumeCount, 50, 50, 0)
	-- print selected costume name up the top
	-- display large fly-in sprite somewhere
	-- display overworld sprites
	-- selection box around current character
  end

end

function state:update(dt)
  VerticalParticles.update(dt)
end

-- not sure I want this one
Gamestate.home = state

return state