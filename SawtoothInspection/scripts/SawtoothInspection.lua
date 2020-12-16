

print('AppEngine Version: ' .. Engine.getVersion())

local DELAY = 1500 -- ms between visualization steps for demonstration purpose

-- Creating viewer
local viewer = View.create("view1")
local viewer2 = View.create("view2")


-- Setting up graphical overlay attributes
local edgeSampleDeco = View.ShapeDecoration.create()
edgeSampleDeco:setLineColor(75, 75, 255) -- Blue
edgeSampleDeco:setLineWidth(4)

local fittedLineDeco = View.ShapeDecoration.create()
fittedLineDeco:setLineColor(0, 255, 0) -- Blue
fittedLineDeco:setLineWidth(4)

local pointDecoOk = View.ShapeDecoration.create()
pointDecoOk:setLineColor(0, 255, 0) -- Green
pointDecoOk:setPointType('DOT')
pointDecoOk:setPointSize(30)

local pointDecoDefect = View.ShapeDecoration.create()
pointDecoDefect:setLineColor(255, 0, 0) -- Red
pointDecoDefect:setLineWidth(4)
pointDecoDefect:setPointType('DOT')
pointDecoDefect:setPointSize(30)

local textDecoration = View.TextDecoration.create()
textDecoration:setPosition(30, 50)
textDecoration:setSize(50)

--End of Global Scope-----------------------------------------------------------

local minToothHeight = 48

--Start of Function and Event Scope---------------------------------------------

local function InspectTooths(im, probeLine, minHeight)
  local defectsImPos = {}

  -- Sample edges along line
  local distProfile, strengthProfile = Image.extractEdgeProfile(im, probeLine, 40, 10)

  -- Smooth profile
  local distProfileLP = Profile.gauss(distProfile, 5)

  -- Find valleys. To be used as reference
  local minPos, minVal = Profile.findLocalExtrema(distProfileLP, "MIN", 31, 2.0)
  local minPoints = Point.create(minPos, minVal)
  local minProfile = Profile.createFromVector(minVal, minPos)
  
  -- Fit line to the valleys
  local CF = Profile.CurveFitter.create()
  --CF:setFitMode("RANSAC")
  local lineCurve = CF:fitLine(minProfile)
  local offset, slope = Profile.Curve.getLineParameters(lineCurve)
  local lineShape = Shape.createLine(Point.create(0, offset), Point.create(1.0, offset + slope))

  -- Find peaks
  local maxPos, maxVal = Profile.findLocalExtrema(distProfileLP, "MAX", 31, 2.0)
  local maxPoints = Point.create(maxPos, maxVal)

  -- Calculate tooth heights
  local toothHeights = {}
  for iPoint = 1, #maxPoints do
    toothHeights[#toothHeights + 1] = Point.getDistanceToLine(maxPoints[iPoint], lineShape)
  end

  -- Check tooth heights
  local defectsPos = {}
  for iTooth = 1, #toothHeights do
    if toothHeights[iTooth] < minHeight then
      defectsPos[#defectsPos + 1] = maxPoints[iTooth]
      -- Get edge position in image
      local edgePos = Profile.getCoordinate(strengthProfile, maxPoints[iTooth]:getX())
      defectsImPos[#defectsImPos + 1] = edgePos
      print("Defect tooth at x: ", maxPoints[iTooth]:getX())
    end
  end

  -- Visualize results
  viewer2:clear()
  viewer2:addProfile(distProfileLP)
  viewer2:addShape(lineShape, fittedLineDeco)
  viewer2:addShape(minPoints, pointDecoOk)
  viewer2:addShape(maxPoints, pointDecoOk)
  viewer2:addShape(defectsPos, pointDecoDefect)
  viewer2:present()

  return defectsImPos
end

local function main()
  local images = {}  
  images[1] = Image.load('resources/noDefect1.png')
  images[2] = Image.load('resources/noDefect2.png')
  images[3] = Image.load('resources/defect.png')

  -- Defining line to sample edges along
  local t = {}
  t[1] = Point.create(0, 300)
  t[2] = Point.create(1499, 300)
  local line = Shape.createPolyline(t, false)

  for iImage = 1, #images do
    local img = images[iImage]

    -- Inspect tooths
    local defectsImPos = InspectTooths(img, line, minToothHeight)

    local defectsImMarker = {}
    for iDefect = 1, #defectsImPos do
      defectsImMarker[#defectsImMarker + 1] = Shape.createCircle(defectsImPos[iDefect], 30)
    end

    -- Visualize results
    viewer:clear()
    viewer:addImage(img)
    viewer:addShape(line, edgeSampleDeco)
    viewer:addShape(defectsImMarker, pointDecoDefect)
    if #defectsImPos == 0 then
      textDecoration:setColor(0, 255, 0)
      viewer:addText('All tooths ok!', textDecoration)
    else
      textDecoration:setColor(255, 0, 0)
      viewer:addText('Defect tooth found!', textDecoration)
    end
    viewer:present()
    
    Script.sleep(DELAY) -- for demonstration purpose only
  end
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register('Engine.OnStarted', main)

--End of Function and Event Scope-----------------------------------------------
